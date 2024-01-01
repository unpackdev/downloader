// SPDX-License-Identifier: MIT
import "./Ownable2Step.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./MerkleProof.sol";
import "./token-contract.sol";
pragma solidity 0.8.18;

contract EmpropsCollectionContract is Ownable2Step, ReentrancyGuard, Pausable {
    bool public creatorsOnly;
    uint256 private constant ONE_MILLION = 1e6;
    uint256 public collectionIdCount;
    address[] public creators;
    Origen public origen = Origen.CURATED;
    PlatformConfig public platformConfig;

    enum MintMode {
        PUBLIC,
        ALLOWLIST,
        FREELIST
    }

    enum Origen {
        OPEN,
        CURATED
    }

    constructor(
        bool isCreatorsOnly,
        address[] memory listCreators,
        Origen _origen,
        uint256 initialCollectionId,
        PlatformConfig memory config
    ) {
        creatorsOnly = isCreatorsOnly;
        creators = listCreators;
        origen = _origen;
        platformConfig = config;
        collectionIdCount = initialCollectionId;
    }

    struct Collection {
        address author;
        uint256 price;
        uint64 editions;
        address royaltyAddress;
        uint16 royalty;
        address freeMinter;
        uint8 status;
        string metadata;
        MintMode mintMode;
        bytes32 allowlist;
        bytes32 freelist;
        address tokenContractAddress;
    }

    struct PlatformConfig {
        uint32 maxCollectionSize;
        uint256 minMintPrice;
        uint32 maxBatchMintSize;
    }

    struct CollectionConfig {
        bool enableBatchMint;
        uint64 maxBatchMintAllowed;
        uint256 startDate;
        uint256 endDate;
    }

    struct FundReceiver {
        address addr;
        uint16 rate;
    }

    struct AccountInfo {
        uint32 allowlistCount;
        uint32 freelistCount;
        uint256 fundsClaimed;
        uint16 rate;
    }

    event CollectionCreated(
        uint256 id,
        address author,
        uint256 price,
        uint64 editions,
        uint16 royalty,
        address freeMinter,
        uint8 status,
        string metadata,
        address tokenContractAddress
    );

    mapping(uint256 => Collection) public collections;
    mapping(uint256 => CollectionConfig) public collectionsConfig;
    mapping(uint256 => uint256) public mintCount;
    mapping(uint256 => uint256) public fundsCollected;
    mapping(uint256 => mapping(address => AccountInfo)) public accounts;

    // MODIFIERS
    function _onlyAdmin(uint256 collectionId) internal view {
        require(
            collections[collectionId].author == _msgSender() ||
                owner() == _msgSender(),
            "Only admin"
        );
    }

    function _existCollection(uint256 collectionId) internal view {
        require(
            collections[collectionId].author != address(0x0),
            "Collection does not exists"
        );
    }

    function _verifyMint(
        uint256 collectionId,
        uint64 quantityToMint
    ) internal view {
        CollectionConfig memory config = collectionsConfig[collectionId];

        require(
            collections[collectionId].author != address(0x0),
            "Collection does not exists"
        );

        // Status check
        require(collections[collectionId].status == 1, "Mint disabled");

        // Supply checks
        require(
            collections[collectionId].editions >=
                mintCount[collectionId] + quantityToMint,
            "Collection minted out"
        );
        if (config.enableBatchMint) {
            require(
                quantityToMint <= config.maxBatchMintAllowed,
                "Quantity to mint is execeeded"
            );
        } else {
            require(quantityToMint == 1, "Batch mint is disabled");
        }

        // Dates checks
        require(block.timestamp > config.startDate, "Mint disabled");

        if (config.endDate != 0) {
            require(block.timestamp < config.endDate, "Mint finished");
        }
    }

    // MESSAGES
    function setPaused(bool paused) external onlyOwner {
        if (paused == true) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setPlatformConfig(
        PlatformConfig calldata config
    ) external onlyOwner {
        platformConfig = config;
    }

    function setCreators(address[] memory newCreators) external onlyOwner {
        creators = newCreators;
    }

    function createCollection(
        Collection memory collection,
        CollectionConfig memory collectionConfig,
        FundReceiver[] memory primarySaleReceivers
    ) external {
        _requireNotPaused();
        require(
            collection.royalty <= 10000,
            "royalty overflows max percentage"
        );
        require(collection.author != address(0x0), "Invalid author address");
        require(
            collection.editions < platformConfig.maxCollectionSize + 1,
            "Invalid editions"
        );
        require(
            collection.price > platformConfig.minMintPrice - 1,
            "Invalid price"
        );
        if (collectionConfig.enableBatchMint == true) {
            require(
                collectionConfig.maxBatchMintAllowed > 1 &&
                    collectionConfig.maxBatchMintAllowed <
                    platformConfig.maxBatchMintSize + 1,
                "Invalid batch size"
            );
        }

        if (collection.royaltyAddress == address(0x0)) {
            collection.royaltyAddress = collection.author;
        }

        if (collectionConfig.startDate == 0) {
            collectionConfig.startDate = block.timestamp;
        }

        if (collectionConfig.endDate != 0) {
            require(
                collectionConfig.endDate > collectionConfig.startDate,
                "Invalid endDate"
            );
        }

        if (creatorsOnly) {
            bool isCreator = false;
            uint256 cl = creators.length;
            for (uint256 i = 0; i < cl; ) {
                if (creators[i] == _msgSender()) {
                    isCreator = true;
                }
                unchecked {
                    ++i;
                }
            }
            require(isCreator, "Only creators allowed");
        }

        // Make sure total rates are equal to 10_000
        uint256 collector = 0;
        uint256 rl = primarySaleReceivers.length;
        for (uint256 i = 0; i < rl; ) {
            FundReceiver memory receiver = primarySaleReceivers[i];
            collector = collector + receiver.rate;

            accounts[collectionIdCount][receiver.addr].rate = receiver.rate;

            unchecked {
                ++i;
            }
        }

        require(collector == 10000, "Primary sales must be 100%");

        collections[collectionIdCount] = collection;
        collectionsConfig[collectionIdCount] = collectionConfig;
        mintCount[collectionIdCount] = 0;

        emit CollectionCreated(
            collectionIdCount,
            collection.author,
            collection.price,
            collection.editions,
            collection.royalty,
            collection.freeMinter,
            collection.status,
            collection.metadata,
            collection.tokenContractAddress
        );

        collectionIdCount = collectionIdCount + 1;
    }

    function setStatus(uint256 collectionId, uint8 status) external {
        _onlyAdmin(collectionId);
        _existCollection(collectionId);
        collections[collectionId].status = status;
    }

    function setTotalEditions(
        uint256 collectionId,
        uint64 newEditions
    ) external {
        _onlyAdmin(collectionId);
        _existCollection(collectionId);
        require(
            newEditions < collections[collectionId].editions,
            "Cannot increase supply"
        );
        require(
            newEditions >= mintCount[collectionId],
            "Invalid editions number"
        );

        collections[collectionId].editions = newEditions;
    }

    function setPrice(uint256 collectionId, uint256 price) external {
        _onlyAdmin(collectionId);
        _existCollection(collectionId);
        collections[collectionId].price = price;
    }

    function setMode(uint256 collectionId, MintMode mode) external {
        _onlyAdmin(collectionId);
        _existCollection(collectionId);
        collections[collectionId].mintMode = mode;
    }

    function setAllowlist(uint256 collectionId, bytes32 allowlist) external {
        _onlyAdmin(collectionId);
        _existCollection(collectionId);
        collections[collectionId].allowlist = allowlist;
    }

    function setFreelist(uint256 collectionId, bytes32 freelist) external {
        _onlyAdmin(collectionId);
        _existCollection(collectionId);
        collections[collectionId].freelist = freelist;
    }

    function setFreeMinter(uint256 collectionId, address freeMinter) external {
        _onlyAdmin(collectionId);
        _existCollection(collectionId);
        collections[collectionId].freeMinter = freeMinter;
    }

    function mint(
        uint256 collectionId,
        address owner,
        bytes32[] calldata proof,
        uint32 quantityToMint,
        uint32 maxQuantityAllowed
    ) external payable nonReentrant {
        _verifyMint(collectionId, quantityToMint);
        require(
            msg.value == (collections[collectionId].price * quantityToMint),
            "Insufficient funds"
        );
        require(
            collections[collectionId].mintMode != MintMode.FREELIST,
            "Invalid mint mode"
        );

        if (collections[collectionId].mintMode == MintMode.ALLOWLIST) {
            bytes32 leaf = keccak256(
                abi.encodePacked(owner, maxQuantityAllowed)
            );
            require(
                MerkleProof.verify(
                    proof,
                    collections[collectionId].allowlist,
                    leaf
                ),
                "Invalid proof"
            );
            uint32 count = accounts[collectionId][owner].allowlistCount +
                quantityToMint;
            // Checks sender has mints remaining
            require(count <= maxQuantityAllowed, "User supply minted out");

            // Increase sender's count
            accounts[collectionId][owner].allowlistCount = count;
        }

        _mintTokens(collectionId, owner, quantityToMint);

        fundsCollected[collectionId] = fundsCollected[collectionId] + msg.value;
    }

    function freeMint(
        uint256 collectionId,
        address owner,
        bytes32[] calldata proof,
        uint32 quantityToMint,
        uint32 maxQuantityAllowed
    ) external nonReentrant {
        _verifyMint(collectionId, quantityToMint);

        if (collections[collectionId].freeMinter != _msgSender()) {
            require(
                collections[collectionId].mintMode == MintMode.FREELIST,
                "Invalid mint mode"
            );

            bytes32 leaf = keccak256(
                abi.encodePacked(msg.sender, maxQuantityAllowed)
            );
            require(
                MerkleProof.verify(
                    proof,
                    collections[collectionId].freelist,
                    leaf
                ),
                "Invalid proof"
            );
            uint32 minted = accounts[collectionId][msg.sender].freelistCount;
            uint32 count = minted + quantityToMint;
            // Checks sender has mints remaining
            require(count <= maxQuantityAllowed, "User supply minted out");

            // Increase sender's count
            accounts[collectionId][msg.sender].freelistCount =
                minted +
                quantityToMint;
        }

        _mintTokens(collectionId, owner, quantityToMint);
    }

    function _mintTokens(
        uint256 collectionId,
        address owner,
        uint32 quantity
    ) internal {
        uint256 collectionMintCount = mintCount[collectionId];

        EmpropsTokenContract token = EmpropsTokenContract(
            collections[collectionId].tokenContractAddress
        );
        for (
            uint256 i = collectionMintCount + 1;
            i <= collectionMintCount + quantity;

        ) {
            uint256 thisTokenId = (collectionId * ONE_MILLION) + i;
            token.mint(
                owner,
                thisTokenId,
                collections[collectionId].royaltyAddress,
                collections[collectionId].royalty
            );

            unchecked {
                ++i;
            }
        }

        mintCount[collectionId] = collectionMintCount + uint256(quantity);
    }

    function withdrawFunds(uint256 collectionId) external nonReentrant {
        _existCollection(collectionId);
        uint16 rate = accounts[collectionId][msg.sender].rate;

        require(rate != 0, "invalid rate");

        // Verify there are funds to split
        uint256 funds = fundsCollected[collectionId];
        uint256 claimed = accounts[collectionId][msg.sender].fundsClaimed;
        uint256 amount = ((funds * rate) / 10000) - claimed;

        require(amount != 0, "No funds collected yet");
        // Send ether to receiver's address
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        accounts[collectionId][msg.sender].fundsClaimed = claimed + amount;
    }
}
