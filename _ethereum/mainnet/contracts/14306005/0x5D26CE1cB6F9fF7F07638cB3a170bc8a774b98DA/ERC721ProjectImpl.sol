// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/// @title: My Project

import "./ERC721ProjectUpgradeable.sol";

contract ERC721ProjectImpl is ERC721ProjectUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(string memory _name, string memory _symbol) public initializer {
        _initialize(_name, _symbol);
    }
}
