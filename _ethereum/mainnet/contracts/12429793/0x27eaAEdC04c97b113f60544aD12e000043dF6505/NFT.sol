pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ICollectionManager.sol";
import "./TokenId.sol";

contract NFT is Ownable, ERC721, ERC721Enumerable, TokenId {
    mapping(CollectionManager => bool) public collectionManagerRegistry;
    mapping(uint256 => CollectionManager) public collectionManagerLookup;
    string public contractURI;

    constructor(string memory name, string memory symbol)
        Ownable()
        ERC721(name, symbol)
    {}

    // PERMISSIONED METHODS ////////////////////////////////////////////////////

    function setContractURI(string memory contractURI_) public onlyOwner {
        contractURI = contractURI_;
    }

    function addCollectionManager(CollectionManager collectionManager)
        public
        onlyOwner
    {
        collectionManagerRegistry[collectionManager] = true;
    }

    // Can only be called by a collection manager.
    function createCollection(uint256 collectionId) public {
        CollectionManager collectionManager = CollectionManager(msg.sender);
        require(
            collectionManagerRegistry[collectionManager],
            "NOT_COLLECTION_MANAGER"
        );
        require(
            collectionManagerLookup[collectionId] ==
                CollectionManager(address(0x0)),
            "COLLECTION_ALREADY_EXISTS"
        );
        require(collectionId < TOKEN_ID_LIMIT, "COLLECTION_ID_TOO_BIG");

        collectionManagerLookup[collectionId] = collectionManager;
    }

    // Can only be called by the collection manager of the collection.
    function mint(
        address recipient,
        uint256 collectionId,
        uint256 seriesId,
        uint256 edition
    ) public {
        require(
            msg.sender == address(collectionManagerLookup[collectionId]),
            "NOT_COLLECTION_MANAGER"
        );
        require(edition < seriesIdMultiplier, "TOKEN_POSITION_TOO_LARGE");
        require(seriesId < collectionIdMultiplier, "SERIES_POSITION_TOO_LARGE");

        uint256 fullId = encodeTokenId(collectionId, seriesId, edition);
        return _safeMint(recipient, fullId);
    }

    // READ METHODS ////////////////////////////////////////////////////////////

    function nextAvailableCollectionId() external view returns (uint256) {
        uint256 i = 0;
        while (true) {
            if (collectionManagerLookup[i] == CollectionManager(address(0x0))) {
                return i;
            }
            i++;
        }
        return 0;
    }

    // Return a list of tokens owned by the passed-in address.
    function tokensOfOwner(address owner)
        external
        view
        returns (uint256[] memory, string[] memory)
    {
        uint256 length = ERC721.balanceOf(owner);

        uint256[] memory tokenIds = new uint256[](length);
        string[] memory tokenURIs = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);
            tokenIds[i] = tokenId;
            tokenURIs[i] = tokenURI(tokenId);
        }

        return (tokenIds, tokenURIs);
    }

    // Overrides ///////////////////////////////////////////////////////////////

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        return ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }
}
