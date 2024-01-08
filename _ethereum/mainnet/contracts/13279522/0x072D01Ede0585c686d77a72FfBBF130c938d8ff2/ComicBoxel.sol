//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./SafeMath.sol";

contract ComicBoxel is ERC721, ERC721Burnable, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  event RoyaltyPaid(string sku, address artist, uint256 royalty);

  //catalog item
  struct Item {
    string sku;
    uint256 price;
    string metadataURI;
    address artist;
    uint8 royaltiesPercentage;
    uint16 quantity;
    uint16 left;
  }

  mapping(string => Item) _catalog;
  mapping(uint256 => string) _tokenIdToSku;
  mapping(string => uint256[]) _skuToTokenIds;

  string private baseURI = "";
  string private _contractURI = "";

  constructor(string memory name, string memory symbol, string memory newBaseURI, string memory newContractURI) ERC721(name, symbol) 
  {
    baseURI = newBaseURI;
    _contractURI = newContractURI;
  }

  /**
    Mint
   */
  function buyBoxel(string memory sku) public payable {
    Item memory item = _catalog[sku];
    require(bytes(item.sku).length != 0, "SKU does not exist in catalog");
    require(item.left > 0, "No NFTs left for this SKU");
    require(msg.value >= item.price, "Insufficient ETH sent for Boxel");

    //create a new token
    _tokenIds.increment();
    uint256 tokenId = _tokenIds.current();

    //mint a new token
    _safeMint(msg.sender, tokenId);

    //pay royalties to artist
    payRoyalties(item);

    //decrease number of items left
    item.left = item.left - 1;
    _catalog[sku] = item;

    //save token->sku
    _tokenIdToSku[tokenId] = sku;
    //save sku->token
    _skuToTokenIds[sku].push(tokenId);
  }

  function payRoyalties(Item memory item) private {
    uint256 royalty = (item.price.mul(item.royaltiesPercentage)).div(100);
    payable(item.artist).transfer(royalty);
    emit RoyaltyPaid(item.sku, item.artist, royalty);
  }

  /**
    URI functions
   */
  function getBaseURI() public view onlyOwner returns (string memory) {
		return baseURI;
	}

  function setBaseURI(string memory newBaseURI) public onlyOwner {
		baseURI = newBaseURI;
	}

  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(baseURI, _contractURI));
  }

  function setContractURI(string memory newContractURI) public onlyOwner {
    _contractURI = newContractURI;
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "Token with this ID does not exist");
    string memory sku = _tokenIdToSku[tokenId];
    require(bytes(sku).length != 0, "SKU not found for token ID");
    Item memory item = _catalog[sku];
    return string(abi.encodePacked(baseURI, item.metadataURI));
	}

  /**
    Catalog functions
   */
  function addItem(Item memory item) public onlyOwner {
    require(bytes(item.sku).length != 0, "SKU can not be empty");
    _catalog[item.sku] = item;
  }

  function addItems(Item[] memory items) public onlyOwner {
    for(uint i = 0; i < items.length; i++) {
      require(bytes(items[i].sku).length != 0, "SKU can not be empty");
      _catalog[items[i].sku] = items[i];
    }
  }

  //to deactivate an item, remove it's metadata
  function deactivateItem(string memory sku) public onlyOwner {
    Item memory item = _catalog[sku];
    require(bytes(item.sku).length != 0, "SKU not found");
    item.left = 0;
    _catalog[sku] = item;
  }

  function getItemBySku(string memory sku) public view onlyOwner returns(Item memory) {
    Item memory item = _catalog[sku];
    require(bytes(item.sku).length != 0, "SKU not found");
    return item;
  }

  function getItemByTokenId(uint256 tokenId) public view onlyOwner returns(Item memory) {
    string memory sku = _tokenIdToSku[tokenId];
    require(bytes(sku).length != 0, "SKU not found for provided token Id");
    return getItemBySku(sku);
  }

  function getSkuByTokenId(uint256 tokenId) public view onlyOwner returns (string memory) {
    return _tokenIdToSku[tokenId];
  }

  function getTokenIdsBySku(string memory sku) public view onlyOwner returns (uint256[] memory) {
    return _skuToTokenIds[sku];
  }
  
  /**
    Withdraw funds
   */
	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}
