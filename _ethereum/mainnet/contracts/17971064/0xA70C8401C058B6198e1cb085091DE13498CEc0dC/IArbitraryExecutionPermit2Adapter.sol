// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "./Token.sol";
import "./IBasePermit2Adapter.sol";

interface IArbitraryExecutionPermit2Adapter is IBasePermit2Adapter {
  /// @notice Data necessary to execute a single permit transfer
  struct SinglePermit {
    address token;
    uint256 amount;
    uint256 nonce;
    bytes signature;
  }

  /// @notice Data necessary to execute a batch permit transfer
  struct BatchPermit {
    IPermit2.TokenPermissions[] tokens;
    uint256 nonce;
    bytes signature;
  }

  /// @notice Allowance target for a specific token
  struct AllowanceTarget {
    address token;
    address allowanceTarget;
  }

  /// @notice A specific contract call
  struct ContractCall {
    address target;
    bytes data;
    uint256 value;
  }

  /// @notice A token and how to distribute it
  struct TransferOut {
    address token;
    Token.DistributionTarget[] distribution;
  }

  /**
   * @notice Executes arbitrary calls by proxing to another contracts, but using Permit2 to transfer tokens from the
   *         caller
   * @param permit The permit data to use to transfer tokens from the user
   * @param allowanceTargets The contracts to approve before executing calls
   * @param contractCalls The calls to execute
   * @param transferOut The tokens to transfer out of our contract after all calls have been executed. Note that each
   *                    element of the array should handle different tokens
   * @param deadline The max time where this call can be executed
   * @return executionResults The results of each contract call
   * @return tokenBalances The balances held by the contract after contract calls were executed
   */
  function executeWithPermit(
    SinglePermit calldata permit,
    AllowanceTarget[] calldata allowanceTargets,
    ContractCall[] calldata contractCalls,
    TransferOut[] calldata transferOut,
    uint256 deadline
  )
    external
    payable
    returns (bytes[] memory executionResults, uint256[] memory tokenBalances);

  /**
   * @notice Executes arbitrary calls by proxing to another contracts, but using Permit2 to transfer tokens from the
   *         caller
   * @param batchPermit The permit data to use to batch transfer tokens from the user
   * @param allowanceTargets The contracts to approve before executing calls
   * @param contractCalls The calls to execute
   * @param transferOut The tokens to transfer out of our contract after all calls have been executed
   * @param deadline The max time where this call can be executed
   * @return executionResults The results of each contract call
   * @return tokenBalances The balances held by the contract after contract calls were executed
   */
  function executeWithBatchPermit(
    BatchPermit calldata batchPermit,
    AllowanceTarget[] calldata allowanceTargets,
    ContractCall[] calldata contractCalls,
    TransferOut[] calldata transferOut,
    uint256 deadline
  )
    external
    payable
    returns (bytes[] memory executionResults, uint256[] memory tokenBalances);
}
