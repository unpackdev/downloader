// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./TokenSwap.sol";

/**
 * @title Echo Token Vesting
 * @dev This is the Echo Token vesting.
 */
contract EchoSwap is TokenSwap {
    constructor(
        IERC20Upgradeable oldToken,
        IERC20Upgradeable newToken
    ) 
    TokenSwap(oldToken, newToken) {}
}