// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./MerkleProof.sol";
import "./FeeControllerI.sol";
import "./MembershipNftV1.sol";
import "./FundingMinter.sol";
import "./FeeControllerV2I.sol";

/// @notice The contract that handles minting of NFTs and fee payout
contract FundingMinterV2 is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    address public feeControllerAddress;

    event LorePayOut(address indexed to, uint256 amount);

    error InvalidProof();
    error InsufficientFunds();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address owner, address _feeController) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        feeControllerAddress = _feeController;
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
        FeeControllerV2I feeController = FeeControllerV2I(feeControllerAddress);
        uint256 fee = feeController.getMintFee(collection, edition.price, quantity);
        if (msg.value != price + fee) {
            revert InsufficientFunds();
        }

        // split the fee here
        // have a default fee split and a community override
        uint256 creatorGetsFee = feeController.getFeeSplitToCreator(collection, fee);
        uint256 loreGetsFee = fee - creatorGetsFee;

//        console.log("creator fee %d wei", creatorGetsFee);
//        console.log("lore fee %d wei", loreGetsFee);
        // send fee to fee collector
        if(loreGetsFee > 0){
//            console.log("Sending %d wei to lore %s", loreGetsFee, feeController.getFeePayoutAddress());
            sendFunds(payable(feeController.getFeePayoutAddress()), loreGetsFee);
        }
        if (price > 0) {
            // send rest to vault
//            console.log("Sending %d wei to creator %s", msg.value - loreGetsFee, address(nft.vault()));
            sendFunds(payable(address(nft.vault())), msg.value - loreGetsFee);
        }
        return nft.buyEdition(editionId, recipient, quantity);
    }

    function sendFunds(address payable recipient, uint256 amount) internal {
//        console.log("Sending %s wei to %s", amount, recipient);
        (bool sent,) = recipient.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit LorePayOut(recipient, amount);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}
}
