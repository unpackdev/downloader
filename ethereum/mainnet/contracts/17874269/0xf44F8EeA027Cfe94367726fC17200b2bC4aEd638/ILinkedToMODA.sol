// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

/**
 * @title Linked to moda Marker Interface
 *
 * @notice Marks smart contracts which are linked to ModaERC20 token instance upon construction,
 *      all these smart contracts share a common moda() address getter
 *
 * @notice Implementing smart contracts MUST verify that they get linked to real ModaERC20 instance
 *      and that moda() getter returns this very same instance address
 *
 * @author Basil Gorin
 */
interface ILinkedToMODA {
  /**
   * @notice Getter for a verified MODAERC20 instance address
   *
   * @return MODAERC20 token instance address smart contract is linked to
   */
  function moda() external view returns (address);
}