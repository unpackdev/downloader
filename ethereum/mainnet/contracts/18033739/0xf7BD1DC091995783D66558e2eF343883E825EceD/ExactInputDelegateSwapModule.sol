// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/// @title Interface for ExactInputDelegateSwapModule
interface ExactInputDelegateSwapModule {
    struct ExactInputParams {
        uint256 inputTokenAmount;
        uint256 paymentTokenAmountMin;
        uint256 deadline;
        bytes swapData;
    }

    function exactInputNativeSwap(ExactInputParams calldata swapParams) external payable returns (uint256);

    function exactInputSwap(ExactInputParams calldata swapParams) external returns (uint256);

    function decodeSwapData(bytes calldata swapData) external returns (address, address, address);
}
