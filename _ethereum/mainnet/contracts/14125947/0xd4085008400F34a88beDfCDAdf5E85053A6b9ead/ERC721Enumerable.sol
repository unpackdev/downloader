// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Counters.sol";
import "./ERC721.sol";

abstract contract ERC721Enumerable is ERC721 {
  using Counters for Counters.Counter;

  Counters.Counter internal supply;

  function walletOfOwner(address _owner)
  public
  view
  returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply()) {
      if (!_exists(currentTokenId)) {
        currentTokenId++;

        continue;
      }

      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function _mint(address to, uint256 tokenId) internal override {
    super._mint(to, tokenId);

    supply.increment();
  }

  function _burn(uint256 tokenId) internal override {
    super._burn(tokenId);

    supply.decrement();
  }

  function maxSupply() public view virtual returns (uint256);
}
