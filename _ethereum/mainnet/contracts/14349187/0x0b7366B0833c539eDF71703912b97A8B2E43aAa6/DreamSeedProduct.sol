// SPDX-License-Identifier: MIT
// by @eddietree

pragma solidity ^0.8.0;

import "./DreamSeedsNFT.sol";
import "./ERC721TradableBurnable.sol";

abstract contract DreamSeedProduct is ERC721TradableBurnable {
  uint256 public constant MAX_SUPPLY = 1300;

  string internal _prerevealMetaURI;
  DreamSeedsNFT public contractDreamSeeds;

  bool public mintIsActive = true;

  function setPreRevealURI(string memory _value) external onlyOwner {
    _prerevealMetaURI = _value;
  }

  function setMintState(bool newState) external onlyOwner {
      mintIsActive = newState;
  }

  function setContractDreamSeeds(address newAddress) external onlyOwner {
      contractDreamSeeds = DreamSeedsNFT(newAddress);
  }

  function ownerOfSeed(uint256 seedTokenId) private view returns (address) {
    return contractDreamSeeds.ownerOf(seedTokenId) ;
  }

  function burnDreamSeed(uint256 seedTokenId) internal {
    require(ownerOfSeed(seedTokenId) == msg.sender, "not owner of dream seed");
    contractDreamSeeds.burnDreamSeed(seedTokenId);
  }

  function withdraw() public onlyOwner {
    uint balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}