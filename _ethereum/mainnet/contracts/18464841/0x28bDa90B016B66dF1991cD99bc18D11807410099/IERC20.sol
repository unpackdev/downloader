//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);
}