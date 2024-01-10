// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

/// @title: My Project

import "./ERC1155ProjectUpgradeable.sol";

contract ERC1155ProjectImpl is ERC1155ProjectUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        _initialize();
    }
}
