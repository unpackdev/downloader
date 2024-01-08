// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
  event Deposit(address indexed dst, uint wad);

  event Withdrawal(address indexed src, uint wad);

  function deposit() external payable;

  function withdraw(uint256) external;
}
