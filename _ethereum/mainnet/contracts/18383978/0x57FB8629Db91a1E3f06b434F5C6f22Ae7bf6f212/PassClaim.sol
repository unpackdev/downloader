// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IPassClaim.sol";
import "./IVerifier.sol";
import "./INFTFactory.sol";
import "./IHotWallet.sol";
import "./ParamEncoder.sol";

contract PassClaim is IPassClaim, Initializable, OwnableUpgradeable, PausableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant VERSION = "1.1.0";

    IVerifier public verifier;
    INFTFactory public nftFactory;
    IHotWallet public hotWallet;
    uint8[2] public nftItemRange;
    // slither-disable-next-line uninitialized-state
    mapping(address collection => mapping(uint256 deduplicationId => CountersUpgradeable.Counter itemUsage))
        public itemUsages;

    event EtherReceived(address sender, uint256 value);
    event VerifierSet(address indexed verifier);
    event NFTFactorySet(address indexed nftFactory);
    event HotWalletSet(address indexed hotWallet);
    event NFTItemRangeSet(uint8[2] nftItemRange);
    event ItemUsagesReset(address indexed collection, uint256 deduplicationIdCount);

    error ZeroVerifier();
    error ZeroNFTFactory();
    error NFTItemRangeMissed(uint8[2] nftItemRange, uint256 currentNFTItemCount);
    error MaxItemUsageReached(address collection, uint256 deduplicationId, uint256 currentUsage);
    error InvalidNFTOwner(address collection, uint256 tokenId, address sender);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address verifier_,
        address nftFactory_,
        address hotWallet_,
        uint8[2] calldata nftItemRange_
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        if (verifier_ == address(0)) {
            revert ZeroVerifier();
        }
        verifier = IVerifier(verifier_);

        if (nftFactory_ == address(0)) {
            revert ZeroNFTFactory();
        }
        nftFactory = INFTFactory(nftFactory_);

        hotWallet = IHotWallet(hotWallet_);
        nftItemRange = nftItemRange_;
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }

    function setVerifier(address verifier_) external onlyOwner {
        if (verifier_ == address(0)) {
            revert ZeroVerifier();
        }

        verifier = IVerifier(verifier_);
        emit VerifierSet(verifier_);
    }

    function setNFTFactory(address nftFactory_) external onlyOwner {
        if (nftFactory_ == address(0)) {
            revert ZeroNFTFactory();
        }

        nftFactory = INFTFactory(nftFactory_);
        emit NFTFactorySet(nftFactory_);
    }

    function setHotWallet(address hotWallet_) external onlyOwner {
        hotWallet = IHotWallet(hotWallet_);
        emit HotWalletSet(hotWallet_);
    }

    function setNFTItemRange(uint8[2] calldata nftItemRange_) external onlyOwner {
        nftItemRange = nftItemRange_;
        emit NFTItemRangeSet(nftItemRange_);
    }

    function resetItemUsages(address collection, uint256[] calldata deduplicationIds) external onlyOwner {
        uint256 deduplicationIdCount = deduplicationIds.length;

        for (uint256 i = 0; i < deduplicationIdCount; ) {
            uint256 deduplicationId = deduplicationIds[i];
            itemUsages[collection][deduplicationId].reset();
            unchecked {
                i++;
            }
        }

        emit ItemUsagesReset(collection, deduplicationIdCount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mintItem(
        NFTItem[] calldata nftItems,
        INFTFactory.MintItemParams calldata params,
        bytes calldata signature
    ) external payable whenNotPaused {
        bytes32 hash = _mintItemHash(nftItems, params, msg.sender);
        bool verified = verifier.verifySigner(hash, signature);
        if (!verified) {
            revert IVerifier.SignerNotVerified(hash, signature);
        }

        _checkNFTItems(nftItems);
        nftFactory.mintItemUnsigned{ value: msg.value }(params);
    }

    function mintItemHash(
        NFTItem[] calldata nftItems,
        INFTFactory.MintItemParams calldata params,
        address sender
    ) external pure returns (bytes32) {
        return _mintItemHash(nftItems, params, sender);
    }

    function _checkNFTItems(NFTItem[] calldata nftItems) private {
        uint256 nftItemCount = nftItems.length;
        if (nftItemCount < nftItemRange[0] || nftItemCount > nftItemRange[1]) {
            revert NFTItemRangeMissed(nftItemRange, nftItemCount);
        }

        bool shouldCheckHotWallet = address(hotWallet) != address(0);
        for (uint256 i = 0; i < nftItemCount; ) {
            NFTItem calldata nftItem = nftItems[i];
            _setItemUsage(nftItem.collection, nftItem.deduplicationId, nftItem.maxUsage);

            shouldCheckHotWallet
                ? _checkHotWalletOwner(nftItem.collection, nftItem.tokenId)
                : _checkColdWalletOwner(nftItem.collection, nftItem.tokenId);

            unchecked {
                i++;
            }
        }
    }

    function _setItemUsage(address collection, uint256 deduplicationId, uint256 maxUsage) private {
        CountersUpgradeable.Counter storage currentUsage = itemUsages[collection][deduplicationId];
        if (maxUsage != 0 && currentUsage.current() == maxUsage) {
            revert MaxItemUsageReached(collection, deduplicationId, currentUsage.current());
        }
        currentUsage.increment();
    }

    function _checkHotWalletOwner(address collection, uint256 tokenId) private view {
        address nftOwner = hotWallet.ownerOf(collection, tokenId);
        if (nftOwner != msg.sender && nftOwner != hotWallet.getHotWallet(msg.sender)) {
            revert InvalidNFTOwner(collection, tokenId, msg.sender);
        }
    }

    function _checkColdWalletOwner(address collection, uint256 tokenId) private view {
        address nftOwner = IERC721Upgradeable(collection).ownerOf(tokenId);
        if (nftOwner != msg.sender) {
            revert InvalidNFTOwner(collection, tokenId, msg.sender);
        }
    }

    // slither-disable-next-line encode-packed-collision
    function _mintItemHash(
        NFTItem[] calldata nftItems,
        INFTFactory.MintItemParams calldata params,
        address sender
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    ParamEncoder.encodeNFTItems(nftItems),
                    params.transactionId,
                    params.collectionId,
                    params.tokenReceiver,
                    params.tokenId,
                    params.tokenURI,
                    params.deduplicationId,
                    params.maxItemSupply,
                    ParamEncoder.encodeRoyalty(params.royalties),
                    ParamEncoder.encodeFees(params.fees),
                    sender
                )
            );
    }
}
