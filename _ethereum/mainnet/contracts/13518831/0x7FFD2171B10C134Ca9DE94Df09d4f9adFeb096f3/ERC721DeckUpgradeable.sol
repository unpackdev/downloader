// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./CardDeck.sol";

contract ERC721DeckUpgradeable is ERC721Upgradeable {
  using CardDeck for CardDeck.Manifest;

  CardDeck.Manifest private _manifest;

  function __ERC721Deck_init(uint256 __length) internal {
    _manifest.setup(__length);
  }

  function remaining() public view returns (uint256) {
    return _manifest.remaining();
  }

  function _mint(address account) internal {
    _mint(account, _manifest.draw());
  }

  function _burn(uint256 tokenId) internal virtual override {
    _manifest.put(tokenId);
  }
}
