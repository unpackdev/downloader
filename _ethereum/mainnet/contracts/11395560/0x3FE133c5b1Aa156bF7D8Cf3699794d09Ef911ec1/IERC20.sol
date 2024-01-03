//SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.5;

interface IERC20 {
  function approve(address spender, uint256 amount) external returns (bool);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);
}
