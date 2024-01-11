// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface MultichainRouter {
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
    function anySwapOutNative(address token, address to, uint toChainID) external payable;
    function anySwapOut(address token, address to, uint amount, uint toChainID) external;
}