// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @notice Interface for Uniswap's router.
 */
interface IUniswapRouter {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external;
}