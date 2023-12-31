// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract Wombat66 is ERC721A, Ownable {
  bool public isActive = false;
  uint256 public mintPrice = 0.013 ether;
  string public _baseTokenURI;
  uint256 public mintPerWallet = 1;

  constructor(string memory baseURI) ERC721A("Wombat66", "WMB") {
    setBaseURI(baseURI);
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

  function getMintPerWallet() public view returns (uint256) {
    return mintPerWallet;
  }

  function batchAirdrop(uint256 _count, address[] calldata addresses) external onlyAuthorized {
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

  function mint(uint256 _count) public payable {
    if (msg.sender != owner()) {
      require(isActive, "Sale is not active currently.");
      require(balanceOf(msg.sender) + _count <= mintPerWallet, "Mint per wallet exceeded");
      require(msg.value >= mintPrice * _count, "Insufficient ETH amount sent.");
      
      payable(owner()).transfer(msg.value);
    }

    _safeMint(msg.sender, _count);
  }
}