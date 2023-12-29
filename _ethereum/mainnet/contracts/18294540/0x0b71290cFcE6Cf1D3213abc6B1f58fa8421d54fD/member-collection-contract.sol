// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./token-contract.sol";
pragma solidity ^0.8.4;

contract MemberCollectionsContract is Ownable, ReentrancyGuard {
    address public tokenContract;
    address public patronTokenAddress;
    bool public creatorsOnly = false;
    uint256 public constant ONE_MILLION = 1000000;
    uint256 public collectionIdCount = 1;
    address[] public creators;

    enum MintMode {
        PUBLIC,
        ALLOWLIST
    }

    constructor(
        address token,
        bool isCreatorsOnly,
        address[] memory listCreators,
        address patronPassTokenAddr
    ) {
        tokenContract = token;
        creatorsOnly = isCreatorsOnly;
        patronTokenAddress = patronPassTokenAddr;
        creators = listCreators;
    }

    struct Collection {
        address author;
        uint256 price;
        uint64 editions;
        uint16 royalty;
        uint16 offset;
        address freeMinter;
        uint8 status;
        bool flag;
        string metadata;
        MintMode mintMode;
        bytes32 allowlist;
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
    mapping(uint256 => uint64) public regularMintCount;
    mapping(uint256 => uint256) public fundsCollected;
    mapping(uint256 => mapping(address => uint128)) public allowlistCount;
    mapping(uint256 => mapping(uint256 => bool)) public redeemedTokensRegistry;

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
        uint16 offset
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

        collections[collectionIdCount] = Collection(
            author,
            price,
            editions,
            royalty,
            offset,
            freeMinter,
            status,
            true,
            metadata,
            mintMode,
            allowlist
        );
        mintCount[collectionIdCount] = 0;
        regularMintCount[collectionIdCount] = 0;

        emit CollectionCreated(
            collectionIdCount,
            author,
            price,
            editions,
            royalty,
            freeMinter,
            status,
            metadata,
            tokenContract
        );

        collectionIdCount += 1;
    }

    function setPatronPassTokenAddress(address newAddress) public onlyOwner {
        patronTokenAddress = newAddress;
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

    function setPrice(
        uint256 collectionId,
        uint256 price
    ) public onlyAdmin(collectionId) {
        require(
            collections[collectionId].flag == true,
            "Collection does not exists"
        );
        collections[collectionId].price = price;
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
        regularMintCount[collectionId] += 1;

        Collection memory c = collections[collectionId];
        uint256 collectionMintCount = regularMintCount[collectionId] + c.offset;

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

        EmpropsTokenContract token = EmpropsTokenContract(tokenContract);
        token.mint(owner, thisTokenId, c.author, c.royalty);

        fundsCollected[collectionId] += msg.value;
    }

    function freeMint(uint256 collectionId, address owner) public {
        mintCount[collectionId] += 1;
        regularMintCount[collectionId] += 1;

        Collection memory c = collections[collectionId];
        uint256 collectionMintCount = regularMintCount[collectionId] + c.offset;
        require(c.flag == true, "Collection does not exists");
        require(c.status == 1, "Mint process is disabled at this moment");
        require(c.freeMinter == _msgSender(), "Sender is not the freeMinter");
        require(c.editions >= collectionMintCount, "Collection minted out");

        uint256 thisTokenId = (collectionId * ONE_MILLION) +
            collectionMintCount;

        EmpropsTokenContract token = EmpropsTokenContract(tokenContract);
        token.mint(owner, thisTokenId, c.author, c.royalty);
    }

    function redeem(uint256 collectionId, uint256 tokenId) public nonReentrant {
        mintCount[collectionId] += 1;
        Collection memory c = collections[collectionId];

        require(c.flag == true, "Collection does not exists");
        require(c.status == 1, "Collection is disabled");
        require(c.offset > 0, "No tokens to redeem");
        // Verify if token has been redeemed before
        require(
            redeemedTokensRegistry[collectionId][tokenId] == false,
            "Token redeemed"
        );

        // Check the redeemer is a PatronPass owner
        address owner = EmpropsTokenContract(patronTokenAddress).ownerOf(
            tokenId
        );
        require(owner == msg.sender, "Sender is not the token owner");

        // Check the basedTokenId is between the offset range
        uint256 basedTokenId = tokenId - ONE_MILLION;
        require(basedTokenId <= c.offset, "Token redeeming is not redeemable");

        // Mint MemberToken respectly to PatronPass tokenId
        uint256 memberTokenId = (collectionId * ONE_MILLION) + basedTokenId;
        EmpropsTokenContract token = EmpropsTokenContract(tokenContract);
        token.mint(owner, memberTokenId, c.author, c.royalty);

        // Set token as redeemed
        redeemedTokensRegistry[collectionId][tokenId] = true;
    }

    function withdrawFunds(uint256 collectionId) public nonReentrant {
        require(
            collections[collectionId].flag == true,
            "Collection does not exists"
        );
        require(
            collections[collectionId].author == _msgSender(),
            "Sender is not the collection author"
        );
        uint256 funds = fundsCollected[collectionId];
        require(funds > 0, "No funds collected yet");

        // Reset funds collected for this collection
        fundsCollected[collectionId] = 0;

        // Send ether to collection's author
        (bool success, ) = payable(collections[collectionId].author).call{
            value: funds
        }("");
        require(success, "Transfer failed");
    }
}
