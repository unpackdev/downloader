//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDagenItems {
  /**
   * @dev Returns the amount of tokens of token type `id` owned by `account`.
   *
   * Requirements:
   *
   * - `account` cannot be the zero address.
   */
  function balanceOf(address account, uint256 id) external view returns (uint256);

  /**
   * @dev Total amount of tokens in with a given id.
   */
  function totalSupply(uint256 id) external view returns (uint256);

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;
}
