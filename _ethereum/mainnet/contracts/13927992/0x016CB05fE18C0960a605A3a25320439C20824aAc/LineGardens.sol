// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract LineGardens is ERC721, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  constructor (string memory customBaseURI_) ERC721("Line Gardens", "KGLG") {
    customBaseURI = customBaseURI_;
  }

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 365;

  Counters.Counter private supplyCounter;

  function mint() public nonReentrant {
    require(saleIsActive, "Sale not active");

    require(totalSupply() < MAX_SUPPLY, "Exceeds max supply");

    _safeMint(_msgSender(), totalSupply());

    supplyCounter.increment();
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = false;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  string private customBaseURI;

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    customBaseURI = customBaseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return customBaseURI;
  }

  function tokenURI(uint256 tokenId) public view override
    returns (string memory)
  {
    return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
  }
}

// Contract created with Studio 721 v1.4.0
// https://721.so