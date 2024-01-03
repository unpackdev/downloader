//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.4;

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address recipient, uint256 amount) external returns (bool);
}
