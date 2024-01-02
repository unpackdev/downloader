// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.21;

/**
 * @title ICurveAddressProvider interface
 * @notice Interface for the Curve Address Provider.
 **/

interface ICurveAddressProvider {
  function get_address(uint256 id) external view returns (address);
}
