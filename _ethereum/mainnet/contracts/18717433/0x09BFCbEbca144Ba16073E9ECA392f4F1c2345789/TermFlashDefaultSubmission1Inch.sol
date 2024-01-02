//SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.18;


/// @dev TermFlashDefaultSubmission1Inch contains arguments needed for performing a term default liquidation using uniswap flash swaps
struct TermFlashDefaultSubmission1Inch {
    address termRepoCollateralManager;
    address termRepoLocker;
    address borrower;
    address repaymentToken;
    uint256 coverAmount;
    address collateralToken;
    bool unwrapCollateralToken;
    bytes oneInchSwapCalldata;
}