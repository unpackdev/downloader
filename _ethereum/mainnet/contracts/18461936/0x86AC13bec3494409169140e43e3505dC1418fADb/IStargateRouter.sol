// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

interface IStargateRouter {
    /* ----- Structs ----- */

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    /* ----- Functions ----- */

    function addLiquidity(uint256 poolId, uint256 amountLD, address to) external;

    function swap(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address payable refundAddress,
        uint256 amountLD,
        uint256 minAmountLD,
        lzTxObj memory lzTxParams,
        bytes calldata to,
        bytes calldata payload
    ) external payable;

    function redeemRemote(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address payable refundAddress,
        uint256 amountLP,
        uint256 minAmountLD,
        bytes calldata to,
        lzTxObj memory lzTxParams
    ) external payable;

    function instantRedeemLocal(uint16 srcPoolId, uint256 amountLP, address to) external returns (uint256 amountSD);

    function redeemLocal(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address payable refundAddress,
        uint256 amountLP,
        bytes calldata to,
        lzTxObj memory lzTxParams
    ) external payable;

    function sendCredits(
        uint16 dstChainId,
        uint256 srcPoolId,
        uint256 dstPoolId,
        address payable refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 dstChainId,
        uint8 functionType,
        bytes calldata toAddress,
        bytes calldata transferAndCallPayload,
        lzTxObj memory lzTxParams
    ) external view returns (uint256 nativeAmount, uint256 zroAmount);
}
