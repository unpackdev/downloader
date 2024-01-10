//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAnySwapBridge {
    function anySwapOut(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external payable;

    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external payable;

    function anySwapOutNative(
        address token,
        address to,
        uint256 toChainID
    ) external payable;
}
