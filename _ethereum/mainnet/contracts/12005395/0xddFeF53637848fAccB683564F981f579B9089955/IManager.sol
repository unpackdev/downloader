// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.12;

import "./IDerivative.sol";

interface ISynthereumManager {
  /**
   * @notice Allow to add roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which give the grant
   */
  function grantSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to revoke roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   * @param accounts Addresses to which revoke the grant
   */
  function revokeSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles,
    address[] calldata accounts
  ) external;

  /**
   * @notice Allow to renounce roles in derivatives and synthetic tokens contracts
   * @param contracts Derivatives or Synthetic role contracts
   * @param roles Roles id
   */
  function renounceSynthereumRole(
    address[] calldata contracts,
    bytes32[] calldata roles
  ) external;

  /**
   * @notice Allow to call emergency shutdown in derivative contracts
   * @param derivatives Derivate contracts to shutdown
   */
  function emergencyShutdown(IDerivative[] calldata derivatives) external;
}
