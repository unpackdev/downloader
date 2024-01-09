// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract KripticComputersCollection is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 public constant START_PRE_SALE_DATE = 1645225200;
  uint256 public constant MAX_AMOUNT = 5500;
  uint256 public constant MAX_SALE_MINT_AMOUNT = 10;
  uint256 public constant MAX_PRESALE_MINT_AMOUNT = 5;

  string public baseURI;
  uint256 public salePrice;
  uint256 public preSalePrice;
  mapping(address => bool) public whitelisted;

  event BaseURIUpdated(string url);
  event SalePriceUpdated(uint256 price);
  event PreSalePriceUpdated(uint256 preSalePrice);

  constructor(
   string memory _initBaseURI,
   string memory _name,
   string memory _symbol,
   uint256 _salePrice,
   uint256 _preSalePrice
  ) ERC721(_name, _symbol) {
    baseURI = _initBaseURI;
    salePrice = _salePrice;
    preSalePrice = _preSalePrice;
  }

  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(block.timestamp > START_PRE_SALE_DATE, "pre-sale not started");
    require(_mintAmount > 0, "mint amount should be more than 0");
    require(supply + _mintAmount <= MAX_AMOUNT, "max collection supply");

    if (block.timestamp - START_PRE_SALE_DATE < 24 hours) {
      require(_mintAmount + balanceOf(_to) <= MAX_PRESALE_MINT_AMOUNT, "max pre-sale mint amount");

      if (msg.sender != owner()) {
        require(whitelisted[_to] == true, "pre-sale minting is available for whitelisted only");
        require(msg.value >= preSalePrice * _mintAmount, "not enough money");
      }
    } else {
      require(_mintAmount + balanceOf(_to) <= MAX_SALE_MINT_AMOUNT, "max sale mint amount");

      if (msg.sender != owner()) {
        require(msg.value >= salePrice * _mintAmount, "not enough money");
      }
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
      : "";
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
    emit BaseURIUpdated(_newBaseURI);
  }

  function setPreSalePrice(uint256 _newPreSalePrice) public onlyOwner {
    preSalePrice = _newPreSalePrice;
    emit PreSalePriceUpdated(_newPreSalePrice);
  }

  function setSalePrice(uint256 _newSalePrice) public onlyOwner {
    salePrice = _newSalePrice;
    emit SalePriceUpdated(_newSalePrice);
  }

  function withdraw() public payable onlyOwner {
    require(address(this).balance != 0, "balance is zero");

    (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");

    require(success, "transfer failed");
  }

  function addWhitelistUsers(address[] memory _users) public onlyOwner {
    for (uint256 i = 0; i < _users.length; i++) {
      whitelisted[_users[i]] = true;
    }
  }

}
