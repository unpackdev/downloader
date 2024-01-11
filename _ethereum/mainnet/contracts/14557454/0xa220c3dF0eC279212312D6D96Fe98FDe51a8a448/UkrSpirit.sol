// SPDX-License-Identifier: UNLICENSED
// (c) Oleksii Vynogradov 2021, All rights reserved, contact alex@cfc.io if you like to use code

pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";
import "./SafeMath.sol";
import "./Strings.sol";

//import "./AggregatorV3Interface.sol";

/// @custom:security-contact alex@openbisea.io
contract UkrSpirit is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using SafeMath for uint256;

    // moto:
    uint8 public constant TYPE_HELP = 0;
    uint8 public constant TYPE_UNITY = 1;
    uint8 public constant TYPE_WILL = 2;
    uint8 public constant TYPE_LOVE = 3;
    uint8 public constant TYPE_PEACE = 4;

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => uint8) public typeForId;

    mapping(uint256 => uint8) public imageNumberForId;

    mapping(uint8 => mapping(uint8 => uint256)) public counterForTypeForImageNumber;

    mapping(uint8 => mapping(uint8 => uint256)) public limitForTypeForImageNumber;

    mapping(uint8 => uint256) public priceForType;

    mapping(uint8 => uint256) public imagesQuantityPerType;

    string public baseURI;

    bool public privateSale = true;

    uint256 public totalSales;

    function setupType(
        uint8 _type,
        uint256 _price,
        uint256 _imagesQuantity,
        uint256 _limit
    ) private {
        priceForType[_type] = _price; imagesQuantityPerType[_type] = _imagesQuantity;
        for (uint8 x = 0; x < _imagesQuantity; x++) {
            limitForTypeForImageNumber[_type][x] = _limit;
        }
    }

    constructor() ERC721("UkrSpirit", "UKRSPRT") {
        baseURI = "ipfs://QmbQVDxwB7yfoYiS7BmfbKGHFzdqcE3MvmZLGCaYe7Wsxt/";
        setupType(TYPE_HELP, 0.4 ether, 15, 777);
        setupType(TYPE_UNITY, 0.18 ether, 11, 155);
        setupType(TYPE_WILL, 0.9 ether, 7, 31);
        setupType(TYPE_LOVE, 4.4 ether, 4, 6);
        setupType(TYPE_PEACE, 17 ether, 2, 1);
    }


    function setPrivateSale(bool _privateSale) public onlyOwner {
        privateSale = _privateSale;
    }

    function setBaseUri(string memory uri) public onlyOwner {
        baseURI = uri;
    }


    function setLimitForType(uint256 limit, uint8 typeNft, uint8 imageNumber) public onlyOwner {
        limitForTypeForImageNumber[typeNft][imageNumber] = limit;
    }

    function setPriceForType(uint256 price, uint8 typeNft) public onlyOwner {
        priceForType[typeNft] = price;
    }

    function setImagesQuantityPerType(uint256 imagesQuantity, uint8 typeNft) public onlyOwner {
        imagesQuantityPerType[typeNft] = imagesQuantity;
    }


    struct ItemFullData {
        string nftURI;
        uint256 price;
        uint256 typeNFT;
        uint256 imageNumber;
    }

    function getDirFor(uint8 typesIndex) public pure returns (string memory) {
        string memory dirName;
        if (typesIndex == TYPE_HELP) dirName = "help";
        if (typesIndex == TYPE_LOVE) dirName = "love";
        if (typesIndex == TYPE_PEACE) dirName = "peace";
        if (typesIndex == TYPE_UNITY) dirName = "unity";
        if (typesIndex == TYPE_WILL) dirName = "will";
        return dirName;
    }

    function getAllItems() public view returns (ItemFullData[] memory) {
        uint256 itemsCount;
        for(uint8 typesIndex=0;typesIndex<5;typesIndex++) {
            for(uint8 imagesIndex=0;imagesIndex<imagesQuantityPerType[typesIndex];imagesIndex++) {
                itemsCount++;
            }
        }
        ItemFullData[] memory allItems = new ItemFullData[](itemsCount);

        uint256 itemsFullDataCount;
        for(uint8 typesIndex=0;typesIndex<5;typesIndex++) {
            for(uint8 imagesIndex=0;imagesIndex<imagesQuantityPerType[typesIndex];imagesIndex++) {
                allItems[itemsFullDataCount] = ItemFullData({
                    nftURI: string(abi.encodePacked(baseURI, getDirFor(typesIndex),"/" ,Strings.toString(imagesIndex) ,".json")),
                    price: priceForType[typesIndex],
                    typeNFT: typesIndex,
                    imageNumber: imagesIndex
                });
                itemsFullDataCount++;
            }
        }

        return allItems;
    }


//    function getPriceForType(uint8 typeNft) public view returns (uint256) {
//        return priceForType[typeNft];
//    }
//
//    function getImagesQuantityPerType(uint8 typeNft) public view returns (uint256) {
//        return imagesQuantityPerType[typeNft];
//    }
//
//    function getCounterForType(uint8 typeNft, uint8 imageNumber) public view returns (uint256) {
//        return counterForTypeForImageNumber[typeNft][imageNumber];
//    }
//
//    function getLimitForType(uint8 typeNft, uint8 imageNumber) public view returns (uint256) {
//        return limitForTypeForImageNumber[typeNft][imageNumber];
//    }
//
//    function getTypeForId(uint256 tokenId) public view returns (uint8) {
//        return typeForId[tokenId];
//    }
//
//    function getImageNumberForId(uint256 tokenId) public view returns (uint8) {
//        return imageNumberForId[tokenId];
//    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _safeMintType(address to, string memory uri, uint8 typeNft, uint8 imageNumber, bool needURI) private {
        uint256 counter = counterForTypeForImageNumber[typeNft][imageNumber];
        counterForTypeForImageNumber[typeNft][imageNumber] = counter + 1;
        require(limitForTypeForImageNumber[typeNft][imageNumber] > 0 && counter + 1 < limitForTypeForImageNumber[typeNft][imageNumber], "UkrSpirit: counter reach end of limit");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        if (needURI) _setTokenURI(tokenId, uri);
        typeForId[tokenId] = typeNft;
        imageNumberForId[tokenId] = imageNumber;
    }

    function safeMintType(address to, string memory uri, uint8 typeNft, uint8 imageNumber) public onlyOwner {
        _safeMintType(to, uri, typeNft, imageNumber, true);
    }

    function safeMintTypeBatch(address[] memory to, uint8[]memory typesNft,uint8[] memory imageNumbers, uint256 count, string[] memory tokenUris) public onlyOwner {
        for(uint256 x=0;x<count;x++) {
            _safeMintType(to[x], tokenUris[x], typesNft[x], imageNumbers[x], false);
        }
    }

    function priceForTypeFinal(uint8 typeNft) public view returns(uint256){
        if (privateSale) return priceForType[typeNft].mul(70).div(100);
        return priceForType[typeNft];
    }

    event Purchase(address indexed from, uint256 value, uint8 typeNft, uint8 finalTypeNft, uint8 imageNumber);

    uint256[] public distributionPercent;
    address[] distributionAddresses;

    function setDistributionAddresses(address [] memory _distributionAddresses, uint256 [] memory _percents) public onlyOwner {
        distributionPercent = _percents;
        distributionAddresses = _distributionAddresses;
    }


    function purchase (uint8 typeNft, uint8 imageNumber) payable public {
        if (privateSale) require(msg.value >= 300000000000000000, "UkrSpirit: minimal 0.3 amount for private sale");
        require(msg.value >= priceForTypeFinal(typeNft), "UkrSpirit: wrong value to send");
        uint256 amountSent;
        bool success;
        for(uint256 x=0;x<distributionAddresses.length - 1;x++) {
            uint amountToSend = msg.value.mul(distributionPercent[x]).div(100);
            (success, ) = distributionAddresses[x].call{value:amountToSend}("");
            require(success, "UkrSpirit: Transfer failed.");
            amountSent = amountSent + amountToSend;
        }
        (success, ) = distributionAddresses[distributionAddresses.length - 1].call{value:msg.value.sub(amountSent)}("");
        require(success, "UkrSpirit: Transfer failed.");

        totalSales = totalSales + msg.value;
        emit Purchase(msg.sender, msg.value,typeNft, typeNft, imageNumber);
        _safeMintType(msg.sender, "", typeNft, imageNumber, false);
    }

    function purchaseBatch(uint8[] memory typesNft, uint8 [] memory imageNumbers, uint256 count) payable public {
        if (privateSale) require(msg.value >= 300000000000000000, "UkrSpirit: minimal 0.3 amount for private sale");

        uint256 totalValueToPay;
        for(uint256 x=0;x<count;x++) {
            totalValueToPay = totalValueToPay + priceForTypeFinal(typesNft[x]);
        }
        require(msg.value >= totalValueToPay, "UkrSpirit: wrong value to send");
        for(uint256 y=0;y<count;y++) {
            _safeMintType(msg.sender, "", typesNft[y], imageNumbers[y], false);
            emit Purchase(msg.sender, priceForTypeFinal(typesNft[y]), typesNft[y], typesNft[y], imageNumbers[y]);
        }

        uint256 amountSent;
        bool success;
        for(uint256 x=0;x<distributionAddresses.length - 1;x++) {
            uint amountToSend = msg.value.mul(distributionPercent[x]).div(100);
            (success, ) = distributionAddresses[x].call{value:amountToSend}("");
            require(success, "UkrSpirit: Transfer failed.");
            amountSent = amountSent + amountToSend;
        }
        (success, ) = distributionAddresses[distributionAddresses.length - 1].call{value:msg.value.sub(amountSent)}("");
        require(success, "UkrSpirit: Transfer failed.");
        totalSales = totalSales + msg.value;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal
    whenNotPaused
    override(ERC721, ERC721Enumerable)
    {
        if (privateSale) require(from == address(0x0), "UkrSpirit: you can't transfer NFT till private sale finished");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        bytes memory tempEmptyStringTest = bytes(super.tokenURI(tokenId));
        if (tempEmptyStringTest.length == 0) {
            string memory imageNumber = Strings.toString(imageNumberForId[tokenId]);
            return string(abi.encodePacked(baseURI, getDirFor(typeForId[tokenId]),"/" ,imageNumber ,".json"));
        }
        else return super.tokenURI(tokenId);
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
