// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

/// @title Escrows assets and deposits them into a yield source.  Exposes interest to Prize Strategy.  Users deposit and withdraw from this contract to participate in Prize Pool.
/// @notice Accounting is managed using Controlled Tokens, whose mint and burn functions can only be called by this contract.
/// @dev Must be inherited to provide specific yield-bearing asset control, such as Compound cTokens
interface PrizePoolInterface {
    function withdrawReserve(address to) external returns (uint256);
}