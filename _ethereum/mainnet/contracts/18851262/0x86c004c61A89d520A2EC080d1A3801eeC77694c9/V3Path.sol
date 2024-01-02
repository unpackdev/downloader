// SPDX-License-Identifier: GPL-3.0-or-later

// A modified version of V3Path library
// Origin: https://github.com/1inch/universal-router/blob/b972662f8d3f0ba55ef99411720f613f77c3fab5/contracts/modules/uniswap/v3/V3Path.sol
// Unused methods and constants were removed

pragma solidity 0.8.18;

import "./BytesLib.sol";

/// @title Functions for manipulating path data for multihop swaps
library V3Path {
    using BytesLib for bytes;

    function decodeFirstToken(bytes memory path) internal pure returns (address tokenA) {
        tokenA = path.toAddress(0, path.length);
    }
}
