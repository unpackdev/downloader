// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC721Base.sol";
import "./ERC721Delegated.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";

contract ApocalypticPunksUkraine is ERC721Delegated, ReentrancyGuard {
  using Counters for Counters.Counter;

  constructor(address baseFactory, string memory customBaseURI_)
    ERC721Delegated(
      baseFactory,
      "Apocalyptic Punks Ukraine",
      "APKU",
      ConfigSettings({
        royaltyBps: 0,
        uriBase: customBaseURI_,
        uriExtension: "",
        hasTransferHook: false
      })
    )
  {}

  /** MINTING **/

  uint256 public constant MAX_SUPPLY = 3333;

  uint256 public constant MAX_MULTIMINT = 3333;

  Counters.Counter private supplyCounter;

  function mint(uint256 count) public nonReentrant onlyOwner {
    require(saleIsActive, "Sale not active");

    require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

    require(count <= MAX_MULTIMINT, "Mint at most 3333 at a time");

    for (uint256 i = 0; i < count; i++) {
      _mint(msg.sender, totalSupply());

      supplyCounter.increment();
    }
  }

  function totalSupply() public view returns (uint256) {
    return supplyCounter.current();
  }

  /** ACTIVATION **/

  bool public saleIsActive = true;

  function setSaleIsActive(bool saleIsActive_) external onlyOwner {
    saleIsActive = saleIsActive_;
  }

  /** URI HANDLING **/

  function setBaseURI(string memory customBaseURI_) external onlyOwner {
    _setBaseURI(customBaseURI_, "");
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    return string(abi.encodePacked(_tokenURI(tokenId), ".json"));
  }
}

// Contract created with Studio 721 v1.5.0
// https://721.so