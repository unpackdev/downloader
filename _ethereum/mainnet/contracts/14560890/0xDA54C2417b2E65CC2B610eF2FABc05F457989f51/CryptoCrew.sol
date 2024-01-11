// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC721A.sol";

import "./Ownable.sol";
import "./Strings.sol";
import "./SafeMath.sol";

contract CryptoCrew is ERC721A, Ownable {
  using SafeMath for uint256;

  string public baseTokenURI;

  bool public preSaleActive = false;
  bool public saleActive = false;

  uint256 public price = 0.04 ether;
  uint256 public reducedPrice = 0.03 ether;

  uint public MAX_SUPPLY = 10000;

  mapping(address => uint) public whiteList;

  address public add1 = 0xc11AB2D4E7b0379aa90D0E23370BC093D2De9f10;
  address public add2 = 0x3cD751E6b0078Be393132286c442345e5DC49699;
  address public add3 = 0xD8eC5a4d4540E430c15e08B25cB0533ab79c87Bd;

  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  constructor (uint256 maxBatchSize_, uint256 collectionSize_)
    ERC721A ("Crypto Crew", "COINCREW", maxBatchSize_, collectionSize_) {}

  function mintCryptoCrew(uint256 _amount) external payable {
    uint256 supply = totalSupply();
    require( saleActive, "Public Sale Not Active" );
    require( _amount > 0 && _amount <= maxBatchSize, "Can't Mint More Than 10" );
    require( supply + _amount <= MAX_SUPPLY, "Not Enough Supply" );
    require( msg.value == price * _amount, "Incorrect Amount Of ETH Sent" );
    _safeMint( msg.sender, _amount);
  }

  function mintPreSale(uint256 _amount) public payable {
    uint256 supply = totalSupply();
    require(preSaleActive, "Private Sale Not Active");
    require( _amount > 0 && _amount <= whiteList[msg.sender], "Exceeded Max Available To Purchase" );
    require( supply + _amount <= MAX_SUPPLY, "Not Enough Supply" );
    require( msg.value == reducedPrice * _amount,   "Incorrect Amount Of ETH Sent" );
    whiteList[msg.sender] -= _amount;
    _safeMint( msg.sender, _amount );
  }

  function setWhiteList(address[] calldata addresses, uint8 numAllowedToMint) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      whiteList[addresses[i]] = numAllowedToMint;
    }
  }

  function gift(address _to, uint256 _amount) external onlyOwner() {
    uint256 supply = totalSupply();
    require( supply + _amount <= MAX_SUPPLY, "Not Enough Supply" );
    _safeMint( _to, _amount );
  }

  function setPrice(uint256 newPrice) public onlyOwner() {
    price = newPrice;
  }

  function setBaseURI(string memory baseTokenURI_) public onlyOwner {
    baseTokenURI = baseTokenURI_;
  }

  function setSaleActive() public onlyOwner {
    saleActive = !saleActive;
  }

  function setPreSaleActive() public onlyOwner {
    preSaleActive = !preSaleActive;
  }

  function withdrawCrew() public onlyOwner {
    uint256 balance = address(this).balance;
    require( balance > 0 );
    _widthdraw(add1, balance.mul(333).div(1000));
    _widthdraw(add2, balance.mul(333).div(1000));
    _widthdraw(add3, address(this).balance);
  }

  function emergencyWidthdraw() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function _widthdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require( success, "Transfer failed." );
  }
}
