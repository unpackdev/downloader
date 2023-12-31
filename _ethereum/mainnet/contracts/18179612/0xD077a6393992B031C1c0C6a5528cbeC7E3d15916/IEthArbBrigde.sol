// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IEthArbBrigde {
    function createRetryableTicket(
        address to,
        uint256 l2CallValue,
        uint256 maxSubmissionCost,
        address excessFeeRefundAddress,
        address callValueRefundAddress,
        uint256 gasLimit,
        uint256 maxFeePerGas,
        bytes calldata data
    ) external payable;
}
