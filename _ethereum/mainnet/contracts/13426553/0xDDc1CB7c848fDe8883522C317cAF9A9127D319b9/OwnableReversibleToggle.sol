// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Ownable.sol";

/**
 * @title ERC721 ToggleableOnce Token
 * @dev ERC721 Token that can be toggled to a between two states.
 */
abstract contract OwnableReversibleToggle is Ownable {
    mapping(uint256 => bool) private _toggles;

    function toggle(uint256 tokenId) public virtual onlyOwner {
        _toggles[tokenId] = !_toggles[tokenId];
    }

    function isToggled(uint256 tokenId) public view returns (bool) {
        return _toggles[tokenId];
    }
}
