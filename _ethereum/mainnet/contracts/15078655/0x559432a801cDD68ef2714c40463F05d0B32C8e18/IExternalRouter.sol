// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

interface IExternalRouter {
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns(uint256 amountA, uint256 amountB);
}
