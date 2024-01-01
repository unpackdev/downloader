// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./PullPaymentUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IIncinerator.sol";
import "./IVerifier.sol";
import "./INFTOperator.sol";
import "./IFeeDistributor.sol";
import "./ParamEncoder.sol";

contract Incinerator is
    IIncinerator,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PullPaymentUpgradeable
{
    using AddressUpgradeable for address payable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant VERSION = "1.2.1";

    IVerifier public verifier;
    uint8[2] public nftItemRange;
    uint8 private _reserved1;
    bytes32 private _reserved2;
    // slither-disable-next-line uninitialized-state
    mapping(uint256 deduplicationId => CountersUpgradeable.Counter itemUsage) public itemUsages;
    INFTOperator public nftOperator;
    IFeeDistributor public feeDistributor;

    event EtherReceived(address sender, uint256 value);
    event VerifierSet(IVerifier indexed verifier);
    event NFTItemRangeSet(uint8[2] nftItemRange);
    event NFTOperatorSet(INFTOperator indexed nftOperator);
    event FeeDistributorSet(IFeeDistributor indexed feeDistributor);
    event TokensBurnt(uint256 nftItemCount);
    event TransactionProcessed(uint256 indexed transactionId);

    error NFTItemRangeMissed(uint8[2] nftItemRange, uint256 currentNFTItemCount);
    error MaxItemUsageReached(uint256 deduplicationId, uint256 currentUsage);
    error InvalidNFTOwner(address collection, uint256 tokenId, address currentOwner, address claimedOnwer);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IVerifier verifier_,
        uint8[2] calldata nftItemRange_,
        INFTOperator nftOperator_,
        IFeeDistributor feeDistributor_
    ) external initializer {
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();
        PullPaymentUpgradeable.__PullPayment_init();

        verifier = verifier_;
        nftItemRange = nftItemRange_;
        nftOperator = nftOperator_;
        feeDistributor = feeDistributor_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    receive() external payable {
        _asyncTransfer(msg.sender, msg.value);
        emit EtherReceived(msg.sender, msg.value);
    }

    function setVerifier(IVerifier verifier_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        verifier = verifier_;
        emit VerifierSet(verifier_);
    }

    function setNFTItemRange(uint8[2] calldata nftItemRange_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nftItemRange = nftItemRange_;
        emit NFTItemRangeSet(nftItemRange_);
    }

    function setNFTOperator(INFTOperator nftOperator_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        nftOperator = nftOperator_;
        emit NFTOperatorSet(nftOperator_);
    }

    function setFeeDistributor(IFeeDistributor feeDistributor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feeDistributor = feeDistributor_;
        emit FeeDistributorSet(feeDistributor_);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function burnItems(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        bytes calldata signature
    ) external payable nonReentrant whenNotPaused {
        bytes32 hash = _burnItemsHash(transactionId, deduplicationId, maxUsage, nftItems, fees, msg.sender);
        bool verified = verifier.verifySigner(hash, signature);
        if (!verified) {
            revert IVerifier.SignerNotVerified(hash, signature);
        }

        _setItemUsage(deduplicationId, maxUsage);
        _burnItems(nftItems);
        feeDistributor.distributeFees{ value: msg.value }(fees);

        emit TokensBurnt(nftItems.length);
        emit TransactionProcessed(transactionId);
    }

    function permitBurnItems(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        Message calldata message,
        bytes calldata signature
    ) external payable nonReentrant whenNotPaused {
        bytes32 hash = _permitBurnItemsHash(
            transactionId,
            deduplicationId,
            maxUsage,
            nftItems,
            fees,
            message,
            msg.sender
        );
        bool verified = verifier.verifySigner(hash, signature);
        if (!verified) {
            revert IVerifier.SignerNotVerified(hash, signature);
        }

        address claimedOwner = verifier.recoverSigner(message.hash, message.signature);
        _setItemUsage(deduplicationId, maxUsage);
        _permitBurnItems(nftItems, claimedOwner);
        feeDistributor.distributeFees{ value: msg.value }(fees);

        emit TokensBurnt(nftItems.length);
        emit TransactionProcessed(transactionId);
    }

    function burnItemsHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        address sender
    ) external pure returns (bytes32) {
        return _burnItemsHash(transactionId, deduplicationId, maxUsage, nftItems, fees, sender);
    }

    function permitBurnItemsHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        Message calldata message,
        address sender
    ) external pure returns (bytes32) {
        return _permitBurnItemsHash(transactionId, deduplicationId, maxUsage, nftItems, fees, message, sender);
    }

    function _setItemUsage(uint256 deduplicationId, uint256 maxUsage) private {
        CountersUpgradeable.Counter storage currentUsage = itemUsages[deduplicationId];
        if (maxUsage != 0 && currentUsage.current() == maxUsage) {
            revert MaxItemUsageReached(deduplicationId, currentUsage.current());
        }
        currentUsage.increment();
    }

    function _burnItems(NFTItem[] calldata nftItems) private {
        uint256 nftItemCount = nftItems.length;
        _checkItemRange(nftItemCount);

        INFTOperator nftOperator_ = nftOperator;
        for (uint256 i = 0; i < nftItemCount; ) {
            NFTItem calldata nftItem = nftItems[i];

            nftOperator_.burn(nftItem.collection, nftItem.tokenId);
            unchecked {
                i++;
            }
        }
    }

    function _permitBurnItems(NFTItem[] calldata nftItems, address claimedOwner) private {
        uint256 nftItemCount = nftItems.length;
        _checkItemRange(nftItemCount);

        INFTOperator nftOperator_ = nftOperator;
        for (uint256 i = 0; i < nftItemCount; ) {
            NFTItem calldata nftItem = nftItems[i];

            address currentOwner = IERC721Upgradeable(nftItem.collection).ownerOf(nftItem.tokenId);
            if (currentOwner != claimedOwner) {
                revert InvalidNFTOwner(nftItem.collection, nftItem.tokenId, currentOwner, claimedOwner);
            }

            nftOperator_.burn(nftItem.collection, nftItem.tokenId);
            unchecked {
                i++;
            }
        }
    }

    function _checkItemRange(uint256 nftItemCount) private view {
        if (nftItemCount < nftItemRange[0] || nftItemCount > nftItemRange[1]) {
            revert NFTItemRangeMissed(nftItemRange, nftItemCount);
        }
    }

    // slither-disable-next-line encode-packed-collision
    function _burnItemsHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        IIncinerator.NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        address sender
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    transactionId,
                    deduplicationId,
                    maxUsage,
                    ParamEncoder.encodeNFTItems(nftItems),
                    ParamEncoder.encodeFees(fees),
                    sender
                )
            );
    }

    // slither-disable-next-line encode-packed-collision
    function _permitBurnItemsHash(
        uint256 transactionId,
        uint256 deduplicationId,
        uint256 maxUsage,
        IIncinerator.NFTItem[] calldata nftItems,
        IFeeDistributor.Fee[] calldata fees,
        Message calldata message,
        address sender
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    transactionId,
                    deduplicationId,
                    maxUsage,
                    ParamEncoder.encodeNFTItems(nftItems),
                    ParamEncoder.encodeFees(fees),
                    message.hash,
                    message.signature,
                    sender
                )
            );
    }
}
