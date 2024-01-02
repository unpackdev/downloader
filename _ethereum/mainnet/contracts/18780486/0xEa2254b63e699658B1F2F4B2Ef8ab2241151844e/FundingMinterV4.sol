
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./OwnableUpgradeable.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./MerkleProof.sol";
import "./FeeControllerV3I.sol";
import "./MembershipNftV2.sol";
import "./IMembershipNftV3.sol";
import "./SafeI.sol";

/// @notice The contract that handles minting of NFTs and fee payout
contract FundingMinterV4 is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    address public feeControllerAddress;

    event LorePayOut(address indexed to, uint256 amount);

    error InvalidProof();
    error InsufficientFunds();
    error Unauthorized();

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

    function setFeeControllerAddress(address _feeControllerAddress) external onlyOwner {
        feeControllerAddress = _feeControllerAddress;
    }

    function buyEdition(address collection, uint256 editionId, address recipient, uint256 quantity)
    external
    virtual
    payable
    returns (uint256 tokenId) {
        return buyEditionProof(collection, editionId, recipient, quantity, new bytes32[](0));
    }

    function buyEditionProof(address collection, uint256 editionId, address recipient, uint256 quantity, bytes32[] memory proof)
    public
    virtual
    payable
    returns (uint256 tokenId){
        MembershipNftV2I nft = MembershipNftV2I(collection);
        uint256 priceEdition;
        bytes32 allowlistRootEdition;

        if(keccak256(bytes(nft.version())) == keccak256(bytes("3"))){
            MembershipNftV3I nftv3 = MembershipNftV3I(collection);
            MembershipNftV3I.Edition memory edition = nftv3.getEdition(editionId);
            priceEdition = edition.price;
            allowlistRootEdition = edition.allowlistRoot;
        }else{
            MembershipNftV2I.Edition memory edition = nft.getEdition(editionId);
            priceEdition = edition.price;
            allowlistRootEdition = edition.allowlistRoot;
        }

        if (allowlistRootEdition != bytes32(0)) {
            if (!MerkleProof.verify(proof, allowlistRootEdition, keccak256(abi.encodePacked(recipient)))) {
                revert InvalidProof();
            }
        }

        uint256 price = priceEdition * quantity;
        FeeControllerV3I feeController = FeeControllerV3I(feeControllerAddress);
        uint256 fee = feeController.getMintFee(collection, priceEdition, quantity);
        if (msg.value != price + fee) {
            revert InsufficientFunds();
        }
        // split the fee here
        // have a default fee split and a community override
        uint256 creatorGetsFee = feeController.getFeeSplitToCreator(collection, fee);
        uint256 loreGetsFee = fee - creatorGetsFee;

        // send fee to fee collector
        if (loreGetsFee > 0) {
            sendFunds(payable(feeController.getFeePayoutAddress()), loreGetsFee);
        }
        // send rest to vault
        if (price + creatorGetsFee > 0) {
            sendFunds(payable(address(nft.vault())), price + creatorGetsFee);
        }
        return nft.buyEdition(editionId, recipient, quantity);
    }

    /// @notice Mint tokens from an edition by an admin. Must pay the lore mint fee * amount.
    function adminAirdrop(address collection, address[] memory wallets, uint256[] memory editionIds, uint256[] memory amounts)
    external
    virtual
    payable {

        // check access control here
        // only vault signers can call this
        MembershipNftV3I nft = MembershipNftV3I(collection);
        SafeI vault = nft.vault();
        if(!vault.isOwner(msg.sender)){
            revert Unauthorized();
        }

        FeeControllerV3I feeController = FeeControllerV3I(feeControllerAddress);
        uint256 totalQuantity = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalQuantity += amounts[i];
        }
        uint256 fee = feeController.getMintFee(collection, 0, totalQuantity);
        if (msg.value != fee) {
            revert InsufficientFunds();
        }

        // split the fee here
        // have a default fee split and a community override
        uint256 creatorGetsFee = feeController.getFeeSplitToCreator(collection, fee);
        uint256 loreGetsFee = fee - creatorGetsFee;


        // send fee to fee collector
        if (loreGetsFee > 0) {
            sendFunds(payable(feeController.getFeePayoutAddress()), loreGetsFee);
        }
        // send rest to vault
        if (creatorGetsFee > 0) {
            sendFunds(payable(address(nft.vault())), creatorGetsFee);
        }

        nft.adminAirdrop(wallets, editionIds, amounts);
    }

    function sendFunds(address payable recipient, uint256 amount) internal {
        (bool sent,) = recipient.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit LorePayOut(recipient, amount);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    function withdraw() external onlyOwner {
        sendFunds(payable(owner()), address(this).balance);
    }
}
