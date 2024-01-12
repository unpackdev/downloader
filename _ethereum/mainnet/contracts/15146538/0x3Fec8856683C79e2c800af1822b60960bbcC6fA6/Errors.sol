// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
pragma abicoder v1;

error EthValueAmountMismatch();
error MinReturnError(uint256, uint256);
error EmptySwap();
error TransactionExpired(uint256, uint256);
error NotEnoughApprovedFundsForSwap(uint256, uint256);
error PermitNotAllowedForEthSwap();
error AmountExceedsQuote(uint256, uint256);
error SwapTotalAmountCannotBeZero();
error SwapAmountCannotBeZero();
error DirectEthDepositIsForbidden();
error MStableInvalidSwapType(uint256);
error AddressCannotBeZero();
