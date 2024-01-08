// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155Upgradeable.sol";

abstract contract ERC1155WithMetadata is ERC1155Upgradeable {
    mapping(uint256 => address) private _creators;

    function __ERC1155WithMetadata_init(string memory uri_)
        internal
        initializer
    {
        __ERC1155_init_unchained(uri_);
    }

    /**
     * @dev Method to know if a token has already been minted or not
     */
    function minted(uint256 id) public view returns (bool) {
        return _creators[id] != address(0);
    }

    /**
     * @dev returns `id`'s creator
     */
    function creator(uint256 id) public view returns (address) {
        return _creators[id];
    }

    /**
     * @dev sets metadata for id
     */
    function _setMetadata(uint256 id, address _creator) internal {
        _creators[id] = _creator;
    }
}
