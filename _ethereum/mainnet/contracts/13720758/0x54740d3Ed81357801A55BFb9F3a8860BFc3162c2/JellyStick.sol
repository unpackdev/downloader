// SPDX-License-Identifier: MIT
/*
      ___  _______  ___      ___      __   __  _______  _______  ___   _______  ___   _
     |   ||       ||   |    |   |    |  | |  ||       ||       ||   | |       ||   | | |
     |   ||    ___||   |    |   |    |  |_|  ||  _____||_     _||   | |       ||   |_| |
     |   ||   |___ |   |    |   |    |       || |_____   |   |  |   | |       ||      _|
  ___|   ||    ___||   |___ |   |___ |_     _||_____  |  |   |  |   | |      _||     |_
 |       ||   |___ |       ||       |  |   |   _____| |  |   |  |   | |     |_ |    _  |
 |_______||_______||_______||_______|  |___|  |_______|  |___|  |___| |_______||___| |_|
*/

pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract JellyStick is ERC721Enumerable, Ownable {
  /* CONSTANTS */
  uint256 public constant MAX_SUPPLY = 10000;

  /* PUBLIC */
  bool public isPublicSale = false;
  bool public isPrivateSale = false;
  uint256 public maxBalance = 20;
  uint256 public maxMintCount = 10;
  uint256 public privateMintPrice = 0.025 ether;
  uint256 public publicMintPrice = 0.05 ether;

  /* PRIVATE */
  string private _baseUri;
  mapping(address => bool) private _whiteList;

  /* TEAM */
  address team1 = address(0x66f914486A68cD3e2650C89bc150677D223e452c);
  address team2 = address(0x9D0b47CcF5c59E8315160B518621A499D63d836f);
  address team3 = address(0x68157833936dc494B59F2953e8EE3C7e0F0CBD50);
  address team4 = address(0x44a6c4F0163f377566CA72dFaE809aC6f6715F64);

  constructor() ERC721("JellyStick", "JELLY") {
    _safeMint(team1, 0);
    _safeMint(team2, 1);
    _safeMint(team3, 2);
    _safeMint(team4, 3);
  }

  /* PUBLIC METHODS */
  function getTokenIdsByOwner(address _owner) public view returns(uint256[] memory) {
    uint256 count = balanceOf(_owner);

    uint256[] memory tokensIds = new uint256[](count);
    for (uint256 i; i < count; i++) {
      tokensIds[i] = tokenOfOwnerByIndex(_owner, i);
    }

    return tokensIds;
  }

  function mintForWhiteList(uint count) public payable {
    uint256 supply = totalSupply();
    uint256 balance = balanceOf(msg.sender);

    require(isPrivateSale, "Not on sale");
    require(_whiteList[msg.sender], "It is not a wallet address registered on the white list");
    require(count <= maxMintCount, "Exceeded max available to purchase");
    require(supply + count <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(balance + count <= maxBalance, "The maximum number of possessions has exceeded");
    require(privateMintPrice * count <= msg.value, "Insufficient balance");

    for (uint256 i = 0; i < count; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function mint(uint count) public payable {
    uint256 supply = totalSupply();
    uint256 balance = balanceOf(msg.sender);

    require(isPublicSale, "Not on sale");
    require(count <= maxMintCount, "Exceeded max available to purchase");
    require(supply + count <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(balance + count <= maxBalance, "The maximum number of possessions has exceeded");
    require(publicMintPrice * count <= msg.value, "Insufficient balance");

    for (uint256 i = 0; i < count; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseUri;
  }

  function isWhiteList(address _owner) public view returns (bool) {
    return _whiteList[_owner];
  }

  /* ONLY OWNER METHODS */
  function setWhiteList(address[] calldata addresses, bool enable) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      _whiteList[addresses[i]] = enable;
    }
  }

  function getOwnersByTokenIds(uint256[] memory tokenIds) external onlyOwner view returns(address[] memory) {
    uint256 count = tokenIds.length;

    address[] memory owners = new address[](count);
    for (uint256 i; i < count; i++) {
      owners[i] = ownerOf(tokenIds[i]);
    }

    return owners;
  }

  function setBaseUri(string memory baseUri) external onlyOwner {
    _baseUri = baseUri;
  }

  function setMaxMintCount(uint256 _maxMintCount) external onlyOwner {
    maxMintCount = _maxMintCount;
  }

  function setPrivateMintPrice(uint256 _privateMintPrice) external onlyOwner {
    privateMintPrice = _privateMintPrice;
  }

  function setPublicMintPrice(uint256 _publicMintPrice) external onlyOwner {
    publicMintPrice = _publicMintPrice;
  }

  function setPublicSale(bool _isPublicSale) external onlyOwner {
    isPublicSale = _isPublicSale;
  }

  function setPrivateSale(bool _isPrivateSale) external onlyOwner {
    isPrivateSale = _isPrivateSale;
  }

  function setMaxBalance(uint256 _maxBalance) external onlyOwner {
    maxBalance = _maxBalance;
  }

  function giveaway(address _owner, uint256 count) external onlyOwner {
    uint256 supply = totalSupply();
    uint256 balance = balanceOf(_owner);

    require(count <= maxMintCount, "Exceeded max available to purchase");
    require(supply + count <= MAX_SUPPLY, "Purchase would exceed max tokens");
    require(balance + count <= maxBalance, "The maximum number of possessions has exceeded");

    for (uint i; i < count; i++) {
      _safeMint(_owner, supply + i);
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}
