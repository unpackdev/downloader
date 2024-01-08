// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface GeneralTokenVesting {
    function startVest(
        address beneficiary,
        uint256 tokensToVest,
        uint256 vestDuration,
        address tokenAddress
    ) external;
}
