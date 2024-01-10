// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INamespaceMinter {
  /**
   * @dev Allow admin to mint a name without paying (used for airdrops)
   */
  function mint(address recipient, string memory namespace) external;
}