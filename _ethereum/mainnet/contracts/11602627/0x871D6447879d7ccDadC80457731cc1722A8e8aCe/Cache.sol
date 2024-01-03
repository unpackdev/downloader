// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./LibCache.sol";

/// @notice A cache structure composed by a bytes32 array
contract Cache {
    using LibCache for bytes32[];

    bytes32[] cache;

    modifier isCacheEmpty() {
        require(cache.length == 0, "Cache not empty");
        _;
    }
}
