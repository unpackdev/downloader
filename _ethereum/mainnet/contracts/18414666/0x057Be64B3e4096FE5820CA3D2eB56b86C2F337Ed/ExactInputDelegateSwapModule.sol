// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.21;

/// @title Interface for ExactInputDelegateSwapModule
interface ExactInputDelegateSwapModule {
    struct ExactInputParams {
        uint256 inputTokenAmount;
        uint256 paymentTokenAmountMin;
        uint256 deadline;
        bytes swapData;
    }

    function exactInputNativeSwap(bytes calldata swapParams) external returns (uint256);

    function exactInputSwap(bytes calldata swapParams) external returns (uint256);

    function decodeSwapData(bytes calldata swapData) external returns (address, address, address);
}
