// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract GrowitOwl is ERC721A, Ownable {
  uint256 public MAX_SUPPLY = 7500;
  bool public isActive = false;
  uint256 public mintPrice = 0.00059 ether;
  string public _baseTokenURI;
  uint256 public freeMintsPerWallet = 1;
  uint256 public maxMintsPerWallet = 10;

  constructor(string memory baseURI) ERC721A("Growit Owl", "GIO") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  function setPrice(uint256 _price) public onlyAuthorized {
    mintPrice = _price;
  }

  function toggleSale() public onlyAuthorized {
    isActive = !isActive;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function getCurrentPrice() public view returns (uint256) {
    return mintPrice;
  }

  function setFreeMaximumAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
    freeMintsPerWallet = _count;
  }

  function setMaximumAllowedTokensPerWallet(uint256 _count) public onlyAuthorized {
    maxMintsPerWallet = _count;
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
    MAX_SUPPLY = maxMintSupply;
  }

  function batchAirdrop(uint256 _count, address[] calldata addresses) external onlyAuthorized {
    uint256 supply = totalSupply();

    require(supply <= MAX_SUPPLY, "Total supply spent.");
    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");

    for (uint256 i = 0; i < addresses.length; i ++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _safeMint(addresses[i], _count);
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Token Id Non-existent");
    return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ".json")) : "";
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function mint(uint256 _count) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
      require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
      require(balanceOf(msg.sender) + _count <= maxMintsPerWallet, "Max mints per wallet exceeded.");
      if (balanceOf(msg.sender) < freeMintsPerWallet) {
        require(msg.value >= mintPrice * (_count > freeMintsPerWallet? (_count - freeMintsPerWallet) : 0), "Insufficient ETH amount sent.");
      } else {
        require(msg.value >= mintPrice * _count, "Insufficient ETH amount sent.");
      }
      
      payable(owner()).transfer(msg.value);
    }

    _safeMint(msg.sender, _count);
  }
}