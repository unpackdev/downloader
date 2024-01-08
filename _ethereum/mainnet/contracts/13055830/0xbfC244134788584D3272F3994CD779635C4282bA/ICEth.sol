// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";

import "./IGenCToken.sol";

interface ICEth is IGenCToken {
  function mint() external payable;

  function repayBorrow() external payable;

  function repayBorrowBehalf(address borrower) external payable;
}
