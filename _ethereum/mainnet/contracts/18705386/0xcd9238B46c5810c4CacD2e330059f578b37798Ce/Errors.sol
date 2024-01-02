// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.21;

library Errors {
    error UnauthorizedAccess();
    error UnknownFeeType(uint8 feeType);
    error NotPartialSwap();
    error ZeroAmount();
    error ExpiredSwap();
    error ClaimOwnSwap();
    error NotAbandonedSwap();
    error InvalidTokenAddress();
    error InvalidTokenBalance();
    error NativeTransferFailed();
    error InvalidAddress();
    error InvalidMultiClaimSwapCount(uint256 maxSwaps, uint256 swapCount);
    error InvalidSwapCount(uint256 maxSwaps, uint256 swapCount);
    error InvalidArguments();
    error NonMatchingToken();
    error NonMatchingAmount();
    error IncorrectNativeAmountSent(uint256 expectedAmount, uint256 actualAmount);
    error InvalidClaimAmounts();
    error RewardHandlerLogFailed();
    error InvalidFeeNumerator();
    error InvalidFixedFee();
}