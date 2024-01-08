// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWERC20Val is IERC20 {
  function wrap() payable external;

  function unwrap(uint256 debtAmount) external;

  function underlyingToDebt(uint256 underlyingAmount) external view returns (uint256);

  function debtToUnderlying(uint256 debtAmount) external view returns (uint256);

  function underlyingBalanceOf(address owner) external view returns (uint256);
}

