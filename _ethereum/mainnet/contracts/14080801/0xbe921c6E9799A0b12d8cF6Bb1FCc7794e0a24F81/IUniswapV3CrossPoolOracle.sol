// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IUniswapV3CrossPoolOracle {
    function assetToAsset(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint32 _twapPeriod
    ) external view returns (uint256 amountOut);
}
