// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAipSwapManager {
    function bestLiquidityPool(address token0, address token1)
        external
        view
        returns (address pool, uint256 price);

    function getPool(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (address pool);

    function poolPrice(
        address token0,
        address token1,
        uint24 fee
    ) external view returns (uint256 price);

    function swap(
        address token0,
        address token1,
        uint24 fee,
        address recipient,
        bool zeroForOne,
        uint256 amount
    ) external returns (int256 amount0, int256 amount1);
}
