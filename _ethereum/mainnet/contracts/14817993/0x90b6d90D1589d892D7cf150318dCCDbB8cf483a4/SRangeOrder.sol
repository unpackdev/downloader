// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IUniswapV3Pool.sol";

struct RangeOrderParams {
    IUniswapV3Pool pool;
    bool zeroForOne;
    int24 tickThreshold;
    uint256 amountIn;
    uint256 minLiquidity;
    address payable receiver;
    uint256 maxFeeAmount;
}
