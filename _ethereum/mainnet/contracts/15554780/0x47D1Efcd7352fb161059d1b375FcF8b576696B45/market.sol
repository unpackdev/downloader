//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721URIStorage.sol";


contract market is ERC721URIStorage, Ownable {
    event NftBought(address _seller, address _buyer, uint256 _price);

    mapping(uint256 => uint256) public tokenIdToPrice;
    mapping(address => tokenMetaData[]) public ownershipRecord;

    struct tokenMetaData {
        uint256 tokenId;
        uint256 timeStamp;
        int32 xCoordinate;
        int32 yCoordinate;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() public ERC721("market", "NFT") {}

    function mintNFT(address recipient, string memory tokenURI)
        public onlyOwner
        returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, tokenURI);

        return newItemId;
    }

    function allowBuy(uint256 _tokenId, uint256 _price) external {
        require(msg.sender == ownerOf(_tokenId), "Not owner of this token");
        require(_price > 0, "Price cannot be zero");
        tokenIdToPrice[_tokenId] = _price;
    }

    function disallowBuy(uint256 _tokenId) external {
        require(msg.sender == ownerOf(_tokenId), "Not owner of this token");
        tokenIdToPrice[_tokenId] = 0;
    }

    function buy(uint256 _tokenId) external payable {
        uint256 price = tokenIdToPrice[_tokenId];
        require(price > 0, "This token is not for sale");
        require(msg.value == price, "Incorrect value");

        address seller = ownerOf(_tokenId);
        (bool sent,/*memory data*/) =  payable(seller).call{value: msg.value}("");
        require(sent, "Transfer Failed!");

        _transfer(seller, msg.sender, _tokenId);
        tokenIdToPrice[_tokenId] = 0; // not for sale anymore

        emit NftBought(seller, msg.sender, msg.value);
    }
}
