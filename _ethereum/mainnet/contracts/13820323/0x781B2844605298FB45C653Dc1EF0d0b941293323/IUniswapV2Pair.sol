// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.6;

import "IERC20.sol";

interface IUniswapV2Pair is IERC20 {
    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}
