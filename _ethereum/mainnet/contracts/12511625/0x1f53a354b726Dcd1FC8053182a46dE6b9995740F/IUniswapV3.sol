// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

// See https://github.com/sohkai/uniswap-v3-cross-pool-oracle
interface IUniswapV3CrossPoolOracle {
    function assetToAsset(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint32 twapPeriod
    ) external view returns (uint256 amountOut);
}
