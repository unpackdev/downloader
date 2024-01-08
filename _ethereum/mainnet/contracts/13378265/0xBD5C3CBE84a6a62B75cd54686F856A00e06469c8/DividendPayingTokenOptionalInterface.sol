// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {

  function withdrawnDividendOf(address _owner) external view returns(uint256);
}