// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

interface IRangoThorchain {

    function swapInToThorchain(
        address token,
        uint amount,
        address tcRouter,
        address tcVault,
        string calldata thorchainMemo,
        uint expiration
    ) external payable;

}