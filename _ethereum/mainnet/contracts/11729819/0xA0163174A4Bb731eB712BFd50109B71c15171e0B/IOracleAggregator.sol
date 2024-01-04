// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOracleAggregator {
    function getExpectedReturnAmount(
        uint256 amountIn,
        address inToken,
        address outToken
    ) external view returns (uint256 returnAmount, uint256 outTokenDecimals);
}
