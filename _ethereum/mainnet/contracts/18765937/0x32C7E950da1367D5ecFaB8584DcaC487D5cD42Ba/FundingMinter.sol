// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./MerkleProof.sol";
import "./FeeControllerI.sol";
import "./MembershipNftV1.sol";

/// @notice The contract that handles minting of NFTs and fee payout
contract FundingMinter is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    FeeControllerI public feeController;

    error InvalidProof();
    error InsufficientFunds();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner, address _feeController) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        feeController = FeeControllerI(_feeController);
        _transferOwnership(owner);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        _transferOwnership(newOwner);
    }

    function buyEdition(address collection, uint256 editionId, address recipient, uint256 quantity)
    external
    virtual
    payable
    returns (uint256 tokenId){
        return buyEditionProof(collection, editionId, recipient, quantity, new bytes32[](0));
    }

    function buyEditionProof(address collection, uint256 editionId, address recipient, uint256 quantity, bytes32[] memory proof)
    public
    virtual
    payable
    returns (uint256 tokenId){
        MembershipNftV1I nft = MembershipNftV1I(collection);
        MembershipNftV1I.Edition memory edition = nft.getEdition(editionId);
        if (edition.allowlistRoot != bytes32(0)) {
            if (!MerkleProof.verify(proof, edition.allowlistRoot, keccak256(abi.encodePacked(recipient)))) {
                revert InvalidProof();
            }
        }

        uint256 price = edition.price * quantity;
        uint256 fee = feeController.getMintFee(collection, edition.price, quantity);
        if (msg.value != price + fee) {
            revert InsufficientFunds();
        }
        // send fee to fee collector
        sendFunds(payable(feeController.getFeePayoutAddress()), fee);
        if (price > 0) {
            // send rest to vault
            sendFunds(payable(address(nft.vault())), msg.value - fee);
        }
        return nft.buyEdition(editionId, recipient, quantity);
    }

    function sendFunds(address payable recipient, uint256 amount) internal {
        (bool sent,) = recipient.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}
}
