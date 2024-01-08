// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";

contract EndangeredBeastRebelCamp is Ownable, ERC721Enumerable {
  using SafeMath for uint256;

  uint256 public constant mintPrice = 0.05 ether;
  uint256 public constant mintLimit = 20;

  uint256 public supplyLimit = 3333;
  bool public saleActive = false;

  string public baseURI;

  address private _withdrawalAddress;

  constructor(
    string memory tokenBaseUri,
    address withdrawalAddress
  ) ERC721("EndangeredBeastsRebelCamp", "EBRC") {
    baseURI = tokenBaseUri;
    _withdrawalAddress = withdrawalAddress;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }
  
  function toggleSaleActive() external onlyOwner {
    saleActive = !saleActive;
  }

  function buyBeasts(uint numberOfTokens) external payable {
    require(saleActive, "Sale is not active.");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction.");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment.");

    _mintBeasts(numberOfTokens);
  }

  function _mintBeasts(uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= supplyLimit, "Not enough tokens left.");

    uint256 newId = totalSupply();
    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(msg.sender, newId);
    }
  }

  function reserveBeasts(uint256 numberOfTokens) external onlyOwner {
    _mintBeasts(numberOfTokens);
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw.");
    
    (bool success, ) = _withdrawalAddress.call{value: address(this).balance}("");
    require(success, "Withdrawal failed.");
  }

  function tokensOwnedBy(address wallet) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
    }

    return ownedTokenIds;
  }
}