// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.2;

interface IERC20 {
  /** @dev Events */

  event Approval(address indexed account, address indexed trust, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /** @dev Views */

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function allowance(address account, address trust) external view returns (uint256);

  /** @dev Mutators */

  function approve(address trust, uint256 amount) external returns (bool);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);
}
