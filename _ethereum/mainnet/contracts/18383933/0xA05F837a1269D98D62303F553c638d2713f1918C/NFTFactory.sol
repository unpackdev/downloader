// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Initializable.sol";
import "./AccessControlUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./PausableUpgradeable.sol";
import "./PullPaymentUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./IVerifier.sol";
import "./INFTFactory.sol";
import "./IRoyaltySplitter.sol";
import "./IFeeDistributor.sol";
import "./INFT.sol";
import "./INFTDeployer.sol";
import "./ParamEncoder.sol";

contract NFTFactory is
    INFTFactory,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    PullPaymentUpgradeable
{
    using AddressUpgradeable for address payable;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct Collection {
        address nft;
        uint256 itemLimit;
        CountersUpgradeable.Counter itemCount;
    }

    bytes32 public constant VERSION = "1.3.0";
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IVerifier public verifier;
    uint8 private _reserved1;
    bytes32 private _reserved2;
    mapping(uint256 collectionId => Collection) public collections;
    // slither-disable-next-line uninitialized-state
    mapping(uint256 collectionId => mapping(uint256 deduplicationId => CountersUpgradeable.Counter itemSupply))
        public itemSupplies;
    INFTDeployer public nftDeployer;
    IRoyaltySplitter public royaltySplitter;
    IFeeDistributor public feeDistributor;
    address private _reserved3;

    event EtherReceived(address sender, uint256 value);
    event VerifierSet(address indexed verifier);
    event NFTDeployerSet(address indexed nftDeployer);
    event RoyaltySplitterSet(address indexed royaltySplitter);
    event FeeDistributorSet(address indexed feeDistributor);
    event NFTRegistryDisabled(uint256 indexed collectionId, bool registryDisabled);
    event NFTOwnershipTransferred(uint256 indexed collectionId, address newOwner);
    event MaxItemSupplySet(uint256 maxItemSupply);
    event CollectionCreated(uint256 indexed collectionId);
    event TokenMinted(uint256 indexed collectionId, uint256 indexed tokenId);
    event TransactionProcessed(uint256 indexed transactionId);

    error ZeroVerifier();
    error ZeroNFTDeployer();
    error ZeroRoyaltySplitter();
    error ZeroFeeDistributor();
    error CollectionExists(uint256 collectionId);
    error CollectionNotFound(uint256 collectionId);
    error CollectionItemLimitExceeded(uint256 collectionId, uint256 currentItemCount);
    error ItemSupplyLimitExceeded(uint256 collectionId, uint256 deduplicationId, uint256 currentItemSupply);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address verifier_,
        address nftDeployer_,
        address royaltySplitter_,
        address feeDistributor_
    ) external initializer {
        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();
        PullPaymentUpgradeable.__PullPayment_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        if (verifier_ == address(0)) {
            revert ZeroVerifier();
        }
        verifier = IVerifier(verifier_);

        if (nftDeployer_ == address(0)) {
            revert ZeroNFTDeployer();
        }
        nftDeployer = INFTDeployer(nftDeployer_);

        if (royaltySplitter_ == address(0)) {
            revert ZeroRoyaltySplitter();
        }
        royaltySplitter = IRoyaltySplitter(royaltySplitter_);

        if (feeDistributor_ == address(0)) {
            revert ZeroFeeDistributor();
        }
        feeDistributor = IFeeDistributor(feeDistributor_);
    }

    receive() external payable {
        _asyncTransfer(msg.sender, msg.value);
        emit EtherReceived(msg.sender, msg.value);
    }

    function setVerifier(address verifier_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (verifier_ == address(0)) {
            revert ZeroVerifier();
        }

        verifier = IVerifier(verifier_);
        emit VerifierSet(verifier_);
    }

    function setNFTDeployer(address nftDeployer_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (nftDeployer_ == address(0)) {
            revert ZeroNFTDeployer();
        }

        nftDeployer = INFTDeployer(nftDeployer_);
        emit NFTDeployerSet(nftDeployer_);
    }

    function setRoyaltySplitter(address royaltySplitter_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (royaltySplitter_ == address(0)) {
            revert ZeroRoyaltySplitter();
        }

        royaltySplitter = IRoyaltySplitter(royaltySplitter_);
        emit RoyaltySplitterSet(royaltySplitter_);
    }

    function setFeeDistributor(address feeDistributor_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (feeDistributor_ == address(0)) {
            revert ZeroFeeDistributor();
        }

        feeDistributor = IFeeDistributor(feeDistributor_);
        emit FeeDistributorSet(feeDistributor_);
    }

    function setNFTRegistryDisabled(uint256 collectionId, bool registryDisabled) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address nft = collections[collectionId].nft;
        emit NFTRegistryDisabled(collectionId, registryDisabled);
        INFT(nft).setRegistryDisabled(registryDisabled);
    }

    function transferNFTOwnership(uint256 collectionId, address newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        address nft = collections[collectionId].nft;
        emit NFTOwnershipTransferred(collectionId, newOwner);
        INFT(nft).transferOwnership(newOwner);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function createCollection(
        CreateCollectionParams calldata params,
        bytes calldata signature
    ) external payable nonReentrant whenNotPaused {
        bytes32 hash = _createCollectionHash(params, msg.sender);
        bool verified = verifier.verifySigner(hash, signature);
        if (!verified) {
            revert IVerifier.SignerNotVerified(hash, signature);
        }

        _createCollection(params);
    }

    function mintItem(
        MintItemParams calldata params,
        bytes calldata signature
    ) external payable nonReentrant whenNotPaused {
        bytes32 hash = _mintItemHash(params, msg.sender);
        bool verified = verifier.verifySigner(hash, signature);
        if (!verified) {
            revert IVerifier.SignerNotVerified(hash, signature);
        }

        _mintItem(params);
    }

    function mintItemUnsigned(
        MintItemParams calldata params
    ) external payable nonReentrant whenNotPaused onlyRole(MINTER_ROLE) {
        _mintItem(params);
    }

    function computeCollectionAddress(
        uint256 collectionId,
        string memory name,
        string memory symbol
    ) external view returns (address) {
        return nftDeployer.computeProxyAddress(collectionId, name, symbol);
    }

    function createCollectionHash(
        CreateCollectionParams calldata params,
        address sender
    ) external pure returns (bytes32) {
        return _createCollectionHash(params, sender);
    }

    function mintItemHash(MintItemParams calldata params, address sender) external pure returns (bytes32) {
        return _mintItemHash(params, sender);
    }

    // slither-disable-next-line reentrancy-no-eth
    function _createCollection(CreateCollectionParams calldata params) private {
        uint256 collectionId = params.collectionId;
        if (collections[collectionId].nft != address(0)) {
            revert CollectionExists(collectionId);
        }

        address nftProxy = nftDeployer.deploy(collectionId, params.name, params.symbol);

        collections[collectionId] = Collection({
            nft: address(nftProxy),
            itemLimit: params.itemLimit,
            itemCount: CountersUpgradeable.Counter(0)
        });

        if (params.royalties.length > 0) {
            (address royaltyForwarder, uint96 totalShares) = royaltySplitter.registerCollectionRoyalty(
                nftProxy,
                params.royalties
            );
            INFT(nftProxy).setDefaultRoyalty(royaltyForwarder, totalShares);
        }

        if (params.fees.length > 0) {
            feeDistributor.distributeFees{ value: msg.value }(params.fees);
        }

        emit CollectionCreated(params.collectionId);
        emit TransactionProcessed(params.transactionId);
    }

    function _mintItem(MintItemParams calldata params) private {
        _setItemSupply(params.collectionId, params.deduplicationId, params.maxItemSupply);
        _mintToken(params.collectionId, params.tokenId, params.tokenReceiver, params.tokenURI, params.royalties);

        if (params.fees.length > 0) {
            feeDistributor.distributeFees{ value: msg.value }(params.fees);
        }

        emit TokenMinted(params.collectionId, params.tokenId);
        emit TransactionProcessed(params.transactionId);
    }

    function _setItemSupply(uint256 collectionId, uint256 deduplicationId, uint256 maxItemSupply) private {
        CountersUpgradeable.Counter storage itemSupply = itemSupplies[collectionId][deduplicationId];
        if (maxItemSupply != 0 && itemSupply.current() >= maxItemSupply) {
            revert ItemSupplyLimitExceeded(collectionId, deduplicationId, itemSupply.current());
        }

        itemSupply.increment();
    }

    function _mintToken(
        uint256 collectionId,
        uint256 tokenId,
        address tokenReceiver,
        string calldata tokenURI,
        IRoyaltySplitter.Royalty[] calldata royalties
    ) private {
        Collection storage collection = collections[collectionId];
        if (collection.nft == address(0)) {
            revert CollectionNotFound(collectionId);
        }
        if (collection.itemLimit != 0 && collection.itemCount.current() >= collection.itemLimit) {
            revert CollectionItemLimitExceeded(collectionId, collection.itemCount.current());
        }

        collection.itemCount.increment();

        INFT nft = INFT(collection.nft);
        nft.mint(tokenId, tokenReceiver, tokenURI);

        if (royalties.length > 0) {
            (address royaltyForwarder, uint96 totalShares) = royaltySplitter.registerTokenRoyalty(
                collection.nft,
                tokenId,
                royalties
            );
            nft.setTokenRoyalty(tokenId, royaltyForwarder, totalShares);
        }
    }

    // slither-disable-next-line encode-packed-collision
    function _createCollectionHash(
        CreateCollectionParams calldata params,
        address sender
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    params.transactionId,
                    params.collectionId,
                    params.name,
                    params.symbol,
                    params.itemLimit,
                    ParamEncoder.encodeFees(params.fees),
                    sender
                )
            );
    }

    // slither-disable-next-line encode-packed-collision
    function _mintItemHash(MintItemParams calldata params, address sender) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
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
