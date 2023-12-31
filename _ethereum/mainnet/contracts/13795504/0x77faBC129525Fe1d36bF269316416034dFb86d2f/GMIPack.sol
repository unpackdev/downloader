// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Counters.sol";

contract GMIPack is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  uint256 public constant MAX_SUPPLY = 4200;
  uint256 public constant MAX_MULTIMINT = 10;
  uint256 public constant PRICE = 69000000000000000;
  bool public saleIsActive = false;
  string private customBaseURI;
  Counters.Counter private _tokenIdCounter;

  constructor (string memory customBaseURI_) ERC721("GMI Pack", "GMIP") {
    _tokenIdCounter.increment();
    customBaseURI = customBaseURI_;
  }

  function mint(uint256 count) public payable nonReentrant {
    require(saleIsActive, "Sale not active");
    require(_tokenIdCounter.current() + count - 1 <= MAX_SUPPLY, "Exceeds max supply");
    require(count <= MAX_MULTIMINT, "Mint at most 10 at a time");
    require(msg.value >= PRICE * count, "Insufficient payment, 0.069 ETH per item");
    
    for (uint256 i = 0; i < count; i++) {
      uint256 mintIndex = _tokenIdCounter.current();
      _safeMint(_msgSender(), mintIndex);
      _tokenIdCounter.increment();
    }
  }

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function withdraw() public nonReentrant onlyOwner {
    uint256 balance = address(this).balance;

    Address.sendValue(payable(owner()), balance);
  }
}