// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IFeeHandler {
    function handleFees(uint256[] memory) external;
}