// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPactSwapRouter {
    function removeIncentivesPoolLiquidity(
        address tokenA,
        address tokenB,
        uint amountTokenAMin,
        uint amountTokenBMin,
        uint deadline
    ) external returns (uint amountToken, uint amountPact);
}
