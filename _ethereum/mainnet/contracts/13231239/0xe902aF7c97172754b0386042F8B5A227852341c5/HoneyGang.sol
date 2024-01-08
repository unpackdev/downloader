// SPDX-License-Identifier: None

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721Enumerable.sol";


contract HoneyGang is Ownable, ERC721Enumerable {
  using SafeMath for uint256;

  uint256 public mintPrice = 50000000000000000;
  uint256 public mintLimit = 20;

  uint256 public supplyLimit = 10000;
  bool public preSaleState = false;
  bool public publicSaleState = false;

  string public baseURI;

  mapping(address => bool) private _whitelist;

  address private deployer;

  constructor() ERC721("HoneyGangBees", "HGB") { 
    deployer = msg.sender;
  }
  
  modifier whitelisted {
    require(_whitelist[msg.sender], "Not on presale whitelist");
    _;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }
  
  function setMintPrice(uint256 newMintPrice) public onlyOwner returns(uint256){
      mintPrice = newMintPrice;
      return mintPrice;
  }
  
  function setMintLimit(uint256 newMintLimit) public onlyOwner returns(uint256){
      mintLimit = newMintLimit;
      return mintLimit;
  }
  
  function changeStatePreSale() public onlyOwner returns(bool) {
      preSaleState = !preSaleState;
      return preSaleState;
  }
  
  function changeStatePublicSale() public onlyOwner returns(bool) {
    publicSaleState = !publicSaleState;
    return publicSaleState;
  }
  

  function addToWhitelist(address[] memory wallets) public onlyOwner {
    for(uint i = 0; i < wallets.length; i++) {
      _whitelist[wallets[i]] = true;
    }
  }

  function checkWhitelisted(address wallet) public view returns (bool) {
    return _whitelist[wallet];
  }

  function buyPresale(uint numberOfTokens) external whitelisted payable {
    require(preSaleState, "Presale is not active");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment");

    _mint(numberOfTokens);
  }

  function buy(uint numberOfTokens) external payable {
    require(publicSaleState, "Sale is not active");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment");

    _mint(numberOfTokens);
  }

  function _mint(uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= supplyLimit, "Not enough tokens left");

    uint256 newId = totalSupply();
    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(msg.sender, newId);
    }
  }

  function reserve(uint256 numberOfTokens) external onlyOwner {
    _mint(numberOfTokens);
  }
  
  function withdraw(address payable _to) public onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    _to.transfer(address(this).balance);
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