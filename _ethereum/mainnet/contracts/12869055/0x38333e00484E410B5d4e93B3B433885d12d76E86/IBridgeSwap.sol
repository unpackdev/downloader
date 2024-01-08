// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IERC20.sol";

interface IBridgeSwap {

    function swap(
        IERC20 tokenIn,
        uint amount,
        IERC20 tokenOut,
        address to,
        address[] calldata swapPath
    ) external returns (uint out);

    function swapToNative(
        IERC20 tokenIn,
        uint amount,
        address payable to,
        address[] calldata swapPath
    ) external returns (uint out);

    function swapFromNative(
        IERC20 tokenOut,
        address to,
        address[] calldata swapPath
    ) external payable returns (uint out);

}
