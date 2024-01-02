// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "./IVault.sol";
import "./IERC20.sol";
import "./IVault.sol";

import "./Objects.sol";

/// @notice file of commons among prod code and tests

/// @notice data forwarded to the flash loan callback
/// @param loanId the id of the old loan to rollover
/// @param offerArg arguments for the loan offer to use for the new loan
/// @param collateral the collateral NFT used both in old and new loan
/// @param borrower the user rolling over its loan
/// @param amountToRepayOldLoan the amount to repay to close the old loan
struct ForwardedData {
    uint256 loanId;
    OfferArg offerArg;
    NFToken collateral;
    address borrower;
    uint256 amountToRepayOldLoan;
    uint256 receivedAmountFromNewLoan;
}

/// @notice put an address in an array of length 1
/// @dev the IERC20 -> balIErc20 cast is a purely syntaxic change for the compiler
function castToBalIErc20(IERC20 token) pure returns (balIErc20[] memory casted) {
    casted = new balIErc20[](1);
    casted[0] = balIErc20(address(token));
}

/// @notice put an uint256 in an array of length 1
function castToUint256Array(uint256 value) pure returns (uint256[] memory casted) {
    casted = new uint256[](1);
    casted[0] = value;
}

// balancer vault provider of free flash loans
/// @dev its the same address on every network where its deployed
IVault constant BALANCER_VAULT = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
