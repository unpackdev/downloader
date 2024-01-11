// SPDX-License-Identifier: GPL-3
pragma solidity =0.7.6;

import "./IImpossiblePair.sol";

interface IImpossibleRouterExtension {
    function factory() external returns (address factoryAddr);

    function swap(uint256[] memory amounts, address[] memory path) external;

    function swapSupportingFeeOnTransferTokens(address[] memory path) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        address pair,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    ) external view returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}
