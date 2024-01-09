// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract Gravitations is ERC721Enumerable, Ownable {

  string private constant BASE_URI
    = "ipfs://Qma5t2y6f9BGk3nCNW6YGW6H4bowaTZLFp8yRFkwYW6A39/";
  bool private isSaleActive = false;
  uint256 private constant MAX_NUM_TOKENS = 2500;
  uint256 private price = 10000000000000000; // 0.01 ETH

  constructor() ERC721("Gravitations", "GRAV") {}

  function _baseURI() internal pure override returns (string memory) {
    return BASE_URI;
  }

  function flipSaleStatus() public onlyOwner {
    isSaleActive = !isSaleActive;
  }

  function getBaseURI() public pure returns (string memory) {
    return _baseURI();
  }

  function getIsSaleActive() public view returns (bool) {
    return isSaleActive;
  }

  function getMaxNumTokens() public pure returns (uint256) {
    return MAX_NUM_TOKENS;
  }

  function getNumTokensAvailableToMint() public view returns (uint256) {
    return MAX_NUM_TOKENS - totalSupply();
  }

  function getPrice() public view returns (uint256) {
    return price;
  }

  function mintTokens(uint256 _quantity) public payable {
    uint256 numTokensMinted = totalSupply();

    require(isSaleActive, "Sale is not active" );
    require(_quantity >= 1, "Quantity must be at least 1");
    require(
      numTokensMinted + _quantity <= MAX_NUM_TOKENS,
      "Exceeds number of tokens available for minting"
    );
    require(msg.value >= price * _quantity, "Insufficient payment");
    
    for (uint256 i = 0; i < _quantity; i++) {
      _safeMint(msg.sender, numTokensMinted + i + 1);
    }
  }

  function mintReserveTokens(uint256 _quantity) public onlyOwner {
    uint256 numTokensMinted = totalSupply();

    require(_quantity >= 1, "Quantity must be at least 1");
    require(
      numTokensMinted + _quantity <= MAX_NUM_TOKENS,
      "Exceeds number of tokens available for minting"
    );
    
    for (uint256 i = 0; i < _quantity; i++) {
      _safeMint(msg.sender, numTokensMinted + i + 1);
    }
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}
