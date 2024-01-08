// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./IBPool.sol";

interface IBRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external returns (uint256 poolTokens);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 poolAmountIn
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function getPoolByTokens(address tokenA, address tokenB) external view returns (IBPool pool);
}
