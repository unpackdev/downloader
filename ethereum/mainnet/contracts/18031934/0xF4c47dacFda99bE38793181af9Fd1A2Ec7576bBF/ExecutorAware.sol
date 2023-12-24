// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @notice Thrown if the executor is set to the zero address.
error ExecutorZeroAddress();

/**
 * @title ExecutorAware abstract contract
 * @notice The ExecutorAware contract allows contracts on a receiving chain to execute messages from an origin chain.
 *         These messages are sent by the `MessageDispatcher` contract which live on the origin chain.
 *         The `MessageExecutor` contract on the receiving chain executes these messages
 *         and then forward them to an ExecutorAware contract on the receiving chain.
 * @dev This contract implements EIP-2771 (https://eips.ethereum.org/EIPS/eip-2771)
 *      to ensure that messages are sent by a trusted `MessageExecutor` contract.
 */
abstract contract ExecutorAware {
  /* ============ Events ============ */

  /// @notice Emitted when a new trusted executor is set.
  /// @param previousExecutor The previous trusted executor address
  /// @param newExecutor The new trusted executor address
  event SetTrustedExecutor(address indexed previousExecutor, address indexed newExecutor);

  /* ============ Variables ============ */

  /// @notice Address of the trusted executor contract.
  address public trustedExecutor;

  /* ============ Constructor ============ */

  /**
   * @notice ExecutorAware constructor.
   * @param _executor Address of the `MessageExecutor` contract
   */
  constructor(address _executor) {
    _setTrustedExecutor(_executor);
  }

  /* ============ Public Functions ============ */

  /**
   * @notice Check which executor this contract trust.
   * @param _executor Address to check
   */
  function isTrustedExecutor(address _executor) public view returns (bool) {
    return _executor == trustedExecutor;
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Sets a new trusted executor.
   * @param _executor The new address to trust as the executor
   */
  function _setTrustedExecutor(address _executor) internal {
    if (address(0) == _executor) revert ExecutorZeroAddress();
    emit SetTrustedExecutor(trustedExecutor, _executor);
    trustedExecutor = _executor;
  }

}
