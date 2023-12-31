// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./token-contract.sol";
pragma solidity ^0.8.4;

contract EmpropsCollectionContract is Ownable, ReentrancyGuard {
    bool public creatorsOnly = false;
    uint256 public constant ONE_MILLION = 1000000;
    uint256 public collectionIdCount = 1;
    address[] public creators;
    Origen public origen = Origen.CURATED;

    enum MintMode {
        PUBLIC,
        ALLOWLIST
    }

    enum Origen {
        OPEN,
        CURATED
    }

    constructor(
        bool isCreatorsOnly,
        address[] memory listCreators,
        Origen _origen
    ) {
        creatorsOnly = isCreatorsOnly;
        creators = listCreators;
        origen = _origen;
    }

    struct Collection {
        address author;
        uint256 price;
        uint64 editions;
        uint16 royalty;
        address freeMinter;
        uint8 status;
        bool flag;
        string metadata;
        MintMode mintMode;
        bytes32 allowlist;
        address tokenContractAddress;
    }

    struct FundReceiver {
        address addr;
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
    mapping(uint256 => uint64) public mintCount;
    mapping(uint256 => uint256) public fundsCollected;
    mapping(uint256 => uint256) public collectionReceiversLength;
    mapping(uint256 => mapping(uint256 => FundReceiver)) public fundReceivers;
    mapping(uint256 => mapping(address => uint128)) public allowlistCount;

    /**
     * @dev Throws if called by any account other than
     * the collection author or contract owner.
     */
    modifier onlyAdmin(uint256 collectionId) {
        require(
            collections[collectionId].author == _msgSender() ||
                owner() == _msgSender(),
            "caller is not the owner or collection creator"
        );
        _;
    }

    function setCreators(address[] memory newCreators) public onlyOwner {
        creators = newCreators;
    }

    function createCollection(
        address author,
        uint256 price,
        uint64 editions,
        uint16 royalty,
        address freeMinter,
        uint8 status,
        string memory metadata,
        MintMode mintMode,
        bytes32 allowlist,
        FundReceiver[] memory primarySaleReceivers,
        address tokenAddr
    ) public {
        require(royalty <= 10000, "royalty overflows max percentage");
        if (creatorsOnly) {
            bool isCreator = false;
            for (uint256 i = 0; i < creators.length; i++) {
                if (creators[i] == _msgSender()) {
                    isCreator = true;
                }
            }
            require(isCreator, "Only creators allowed");
        }

        collectionReceiversLength[collectionIdCount] = primarySaleReceivers
            .length;

        // Make sure total rates are equal to 10_000
        uint256 collector = 0;
        for (uint256 i = 0; i < primarySaleReceivers.length; i++) {
            FundReceiver memory receiver = primarySaleReceivers[i];
            collector += receiver.rate;

            fundReceivers[collectionIdCount][i] = receiver;
        }

        require(collector == 10000, "Primary sales must be 100%");

        collections[collectionIdCount] = Collection(
            author,
            price,
            editions,
            royalty,
            freeMinter,
            status,
            true,
            metadata,
            mintMode,
            allowlist,
            tokenAddr
        );
        mintCount[collectionIdCount] = 0;

        emit CollectionCreated(
            collectionIdCount,
            author,
            price,
            editions,
            royalty,
            freeMinter,
            status,
            metadata,
            tokenAddr
        );

        collectionIdCount += 1;
    }

    function setStatus(
        uint256 collectionId,
        uint8 status
    ) public onlyAdmin(collectionId) {
        require(
            collections[collectionId].flag == true,
            "Collection does not exists"
        );
        collections[collectionId].status = status;
    }

    function setMode(
        uint256 collectionId,
        MintMode mode
    ) public onlyAdmin(collectionId) {
        require(
            collections[collectionId].flag == true,
            "Collection does not exists"
        );
        collections[collectionId].mintMode = mode;
    }

    function setAllowlist(
        uint256 collectionId,
        bytes32 allowlist
    ) public onlyAdmin(collectionId) {
        require(
            collections[collectionId].flag == true,
            "Collection does not exists"
        );
        collections[collectionId].allowlist = allowlist;
    }

    function mint(
        uint256 collectionId,
        address owner,
        bytes32[] calldata proof,
        uint32 quantity
    ) public payable nonReentrant {
        mintCount[collectionId] += 1;

        Collection memory c = collections[collectionId];
        uint256 collectionMintCount = mintCount[collectionId];

        require(c.flag == true, "Collection does not exists");
        require(c.status == 1, "Mint process is disabled at this moment");
        require(msg.value == c.price, "Insufficient funds");
        require(c.editions >= collectionMintCount, "Collection minted out");

        if (c.mintMode == MintMode.ALLOWLIST) {
            bytes32 leaf = keccak256(abi.encodePacked(msg.sender, quantity));
            require(
                MerkleProof.verify(proof, c.allowlist, leaf),
                "Invalid proof"
            );

            // Checks sender has mints remaining
            require(
                allowlistCount[collectionId][msg.sender] < quantity,
                "User supply minted out"
            );

            // Increase sender's count
            allowlistCount[collectionId][msg.sender] += 1;
        }

        uint256 thisTokenId = (collectionId * ONE_MILLION) +
            collectionMintCount;

        EmpropsTokenContract token = EmpropsTokenContract(
            c.tokenContractAddress
        );

        if (origen == Origen.OPEN) {
            token.mint(owner, thisTokenId, c.author, c.royalty);
        } else {
            // Use default royalty
            token.mint(owner, thisTokenId, address(0), 0);
        }

        fundsCollected[collectionId] += msg.value;
    }

    function freeMint(uint256 collectionId, address owner) public {
        mintCount[collectionId] += 1;

        Collection memory c = collections[collectionId];
        uint256 collectionMintCount = mintCount[collectionId];
        require(c.flag == true, "Collection does not exists");
        require(c.status == 1, "Mint process is disabled at this moment");
        require(c.freeMinter == _msgSender(), "Sender is not the freeMinter");
        require(c.editions >= collectionMintCount, "Collection minted out");

        uint256 thisTokenId = (collectionId * ONE_MILLION) +
            collectionMintCount;

        EmpropsTokenContract token = EmpropsTokenContract(
            c.tokenContractAddress
        );
        if (origen == Origen.OPEN) {
            token.mint(owner, thisTokenId, c.author, c.royalty);
        } else {
            // Use default royalty
            token.mint(owner, thisTokenId, address(0), 0);
        }
    }

    function withdrawFunds(uint256 collectionId) public nonReentrant {
        Collection memory collection = collections[collectionId];
        require(collection.flag == true, "Collection does not exists");

        require(
            collection.author == _msgSender(),
            "Sender is not the collection author"
        );

        // Verify there are funds to split
        uint256 funds = fundsCollected[collectionId];
        require(funds > 0, "No funds collected yet");
        uint256 length = collectionReceiversLength[collectionId];

        for (uint256 i = 0; i < length; i++) {
            FundReceiver memory receiver = fundReceivers[collectionId][i];

            uint256 amount = (funds * receiver.rate) / 10000;
            // Send ether to receiver's address
            (bool success, ) = payable(receiver.addr).call{value: amount}("");
            require(success, "Transfer failed");
        }

        // Reset funds collected for this collection
        fundsCollected[collectionId] = 0;
    }
}
