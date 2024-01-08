// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*                  
 █████╗  ██████╗ ██████╗  ██╗
██╔══██╗██╔═████╗╚════██╗███║
╚██████║██║██╔██║ █████╔╝╚██║
 ╚═══██║████╔╝██║██╔═══╝  ██║
 █████╔╝╚██████╔╝███████╗ ██║
 ╚════╝  ╚═════╝ ╚══════╝ ╚═╝          
*/

import "./console.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract NFT9021 is ERC721Enumerable, ERC721URIStorage, Ownable {
    using Strings for uint256;

    struct Collections {
        uint256 preSaleSupply;
        uint256 publicSupply;
        uint256 preSaleMaxMint;
        uint256 maxMint;
        uint256 collectionSupply;
        uint256 price;
        uint256 publicAmountMinted;
        uint256 privateAmountMinted;
        uint256 collectionId;
        uint256 startRange;
        uint256 endRange;
        string URIPath;
        mapping(address => bool) presalerList;
        mapping(address => uint256) presalerListPurchases;
    }

    uint256 public maxSupply = 9021;
    uint256 public tokenCounter;
    uint256 public ccId;

    address public wallet = 0x8b37ebbCB4f082d3942dbA4725eDDe0CFd067515;

    bool public presaleLive;
    bool public saleLive;

    mapping(uint256 => Collections) public collection;

    constructor() ERC721("9021 - Les Generatives & Fine Arts", "9021") {
        tokenCounter = 5492;
    }

    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!collection[ccId].presalerList[entry], "DUPLICATE_ENTRY");

            collection[ccId].presalerList[entry] = true;
        }
    }

    function removeFromPresaleList(address[] calldata entries)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");

            collection[ccId].presalerList[entry] = false;
        }
    }

    function buy(uint256 tokenQuantity) external payable {
        require(saleLive, "sale closed");
        require(!presaleLive, "disable presale");
        require(tokenCounter + tokenQuantity <= maxSupply, "project sold out");
        require(
            collection[ccId].privateAmountMinted +
                collection[ccId].publicAmountMinted +
                tokenQuantity <=
                collection[ccId].collectionSupply,
            "collection sold out"
        );
        require(
            collection[ccId].publicAmountMinted + tokenQuantity <=
                collection[ccId].publicSupply,
            "exceeded public supply"
        );
        require(
            tokenQuantity <= collection[ccId].maxMint,
            "exceeded max limit per mint"
        );
        require(
            collection[ccId].price * tokenQuantity <= msg.value,
            "insufficient eth"
        );

        for (uint256 i = 0; i < tokenQuantity; i++) {
            collection[ccId].publicAmountMinted++;
            tokenCounter++;
            _safeMint(msg.sender, tokenCounter);
        }
    }

    function presaleBuy(uint256 tokenQuantity) external payable {
        require(!saleLive && presaleLive, "presale closed");
        require(
            collection[ccId].presalerList[msg.sender],
            "address not in presale"
        );
        require(
            collection[ccId].privateAmountMinted + tokenQuantity <=
                collection[ccId].preSaleSupply,
            "exceeded presale supply"
        );
        require(
            collection[ccId].presalerListPurchases[msg.sender] +
                tokenQuantity <=
                collection[ccId].preSaleMaxMint,
            "exceeded presale mint allocation"
        );
        require(
            collection[ccId].price * tokenQuantity <= msg.value,
            "insufficient eth"
        );

        for (uint256 i = 0; i < tokenQuantity; i++) {
            collection[ccId].privateAmountMinted++;
            collection[ccId].presalerListPurchases[msg.sender]++;
            tokenCounter++;
            _safeMint(msg.sender, tokenCounter);
        }
    }

    function setNewCollection(
        uint256 _collectionId,
        uint256 _preSaleSupply,
        uint256 _publicSupply,
        uint256 _collectionSupply,
        uint256 _price,
        uint256 _preSaleMaxMint,
        uint256 _maxMint
    ) external onlyOwner {
        ccId = _collectionId;
        collection[ccId].preSaleSupply = _preSaleSupply;
        collection[ccId].publicSupply = _publicSupply;
        collection[ccId].collectionSupply = _collectionSupply;
        collection[ccId].price = _price;
        collection[ccId].preSaleMaxMint = _preSaleMaxMint;
        collection[ccId].maxMint = _maxMint;
        collection[ccId].collectionId = _collectionId;
    }

    function setCollectionURI(
        uint256 _rangeStart,
        uint256 _rangeEnd,
        string calldata _collectionURI
    ) external onlyOwner {
        collection[ccId].startRange = _rangeStart;
        collection[ccId].endRange = _rangeEnd;
        collection[ccId].URIPath = _collectionURI;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = wallet.call{value: (address(this).balance)}("");

        require(success, "Transfer failed.");
    }

    function isPresaler(address addr) external view returns (bool) {
        return collection[ccId].presalerList[addr];
    }

    function presalePurchasedCount(address addr)
        external
        view
        returns (uint256)
    {
        return collection[ccId].presalerListPurchases[addr];
    }

    function togglePresaleStatus() external onlyOwner {
        presaleLive = !presaleLive;
    }

    function toggleSaleStatus() external onlyOwner {
        saleLive = !saleLive;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorage)
        returns (string memory URI)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );

        for (uint256 i = 1; i <= ccId; i++) {
            if (
                tokenId >= collection[i].startRange &&
                tokenId <= collection[i].endRange
            ) {
                URI = string(
                    abi.encodePacked(collection[i].URIPath, tokenId.toString())
                );
            }
        }
    }

    // function overrides
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}