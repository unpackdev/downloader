// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "./IPermit2.sol";

/// @notice The interface all Permit2 adapters should implement
interface IBasePermit2Adapter {

  /// @notice Thrown when the user tries to execute an invalid contract call
  error InvalidContractCall();
  
  /**
   * @notice Thrown when a transaction deadline has passed
   * @param current The current time
   * @param deadline The set deadline
   */
  error TransactionDeadlinePassed(uint256 current, uint256 deadline);

  /**
   * @notice Returns the address that represents the native token
   * @dev This value is constant and cannot change
   * @return The address that represents the native token
   */
  function NATIVE_TOKEN() external view returns (address);

  /**
   * @notice Returns the address of the Permit2 contract
   * @dev This value is constant and cannot change
   * @return The address of the Permit2 contract
   */
  function PERMIT2() external view returns (IPermit2);
}
