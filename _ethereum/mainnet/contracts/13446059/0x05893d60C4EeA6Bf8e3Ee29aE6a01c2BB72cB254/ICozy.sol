// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

/**
 * @dev Interfaces for Cozy contracts
 */

interface ICozyShared {
  function underlying() external returns (address);

  function borrow(uint256 borrowAmount) external returns (uint256);

  function borrowBalanceCurrent(address account) external returns (uint256);
}

interface ICozyToken is ICozyShared {
  function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

  function repayBorrow(uint256 repayAmount) external returns (uint256);
}

interface ICozyEther is ICozyShared {
  function repayBorrowBehalf(address borrower) external payable;
}

interface IMaximillion {
  function repayBehalfExplicit(address borrower, ICozyEther market) external payable;
}
