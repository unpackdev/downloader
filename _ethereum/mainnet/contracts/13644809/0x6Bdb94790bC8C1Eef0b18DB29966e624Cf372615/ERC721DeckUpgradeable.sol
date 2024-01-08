// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Upgradeable.sol";
import "./Random.sol";
import "./TotalSupply.sol";

contract ERC721DeckUpgradeable is ERC721Upgradeable, TotalSupply {
    using Random for Random.Manifest;

    Random.Manifest private _manifest;

    modifier onlyRemaining(uint256 count) {
        require (remaining() >= count, 'Not enough tokens remaining');
        _;
    }

    function __ERC721Deck_init(uint256 __length) internal {
        _manifest.setup(__length);
        _setTotalSupply(__length);
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

    uint256[49] private __gap;
}
