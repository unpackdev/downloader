// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract BetmanComponents is ERC721Enumerable, Ownable {
  uint256 public constant MAX_SUPPLY = 1120;
  uint256 public constant MAX_MINT = 10;
  uint256 public constant PUBLIC_MINT_PRICE = 50000000000000000; // mint price: 0.05 eth

  uint256 public publicStartTime = 1646722800; // 2022.03.08 3 PM (GMT+8)
  string private baseURI;

  constructor(
  ) ERC721("Betman Components", "BM") {
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setbaseURI(string memory baseURI_) external onlyOwner() {
    baseURI = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setPublicMintTime(uint256 startTime) external onlyOwner {
    publicStartTime = startTime;
  }
  
  function mint(uint256 numberOfTokens) public payable {
    uint256 totalToken = totalSupply();
    require(block.timestamp >= publicStartTime, "Public mint not begin yet");
    require(numberOfTokens <= MAX_MINT, "Number of mint exceed MAX_MINT");
    require(totalToken + numberOfTokens <= MAX_SUPPLY, "Purchase would exceed token supply");
    require(PUBLIC_MINT_PRICE * numberOfTokens <= msg.value, "Ether value is insufficient");

    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender, totalToken + i);
    }
  }

  function reserve(uint256 numberReserved) public onlyOwner {
    uint totalToken = totalSupply();
    uint i;
    for (i = 0; i < numberReserved; i++) {
      _safeMint(msg.sender, totalToken + i);
    }
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    Address.sendValue(payable(owner()), balance);
  }
}
