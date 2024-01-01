// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IWooRouterV2 {
    /* ----- State Variables ----- */

    function WETH() external view returns (address);

    function wooPool() external view returns (address);

    /* ----- Functions ----- */

    function querySwap(address fromToken, address toToken, uint256 fromAmount) external view returns (uint256 toAmount);

    function tryQuerySwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 toAmount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        address rebateTo
    ) external payable returns (uint256 realToAmount);

    function externalSwap(
        address approveTarget,
        address swapTarget,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minToAmount,
        address payable to,
        bytes calldata data
    ) external payable returns (uint256 realToAmount);
}
