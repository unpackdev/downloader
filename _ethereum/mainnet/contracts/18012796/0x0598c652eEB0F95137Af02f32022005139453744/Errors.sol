//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Errors {
    // General errors
    error ZeroValue();
    error ZeroAddress();
    error EmptyArray();
    error DifferentSizeArrays(uint256 length1, uint256 length2);

    // Fee errors
    error InvalidFee();

    // Swapper errors
    error SwapError();

    // Weighted tokens errors
    error RatioOverflow();
    error NoWeightedTokens();

    // Operator errors
    error NotOperator();
    error NotOperatorOrOwner();

    // Swapper errors
    error NotVault();
}
