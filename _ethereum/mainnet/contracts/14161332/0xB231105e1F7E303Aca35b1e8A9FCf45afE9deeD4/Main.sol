// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./Creator.sol";

contract Main is Creator {
    constructor(
        string memory name,
        string memory symbol,
        address creatorImplementation
    ) Creator(name, symbol, creatorImplementation) {}
}
