// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

// solhint-disable-next-line no-unused-import
import "./Permit2Transfers.sol";
import "./Token.sol";
import "./IArbitraryExecutionPermit2Adapter.sol";
import "./BasePermit2Adapter.sol";

/**
 * @title Arbitrary Execution Permit2 Adapter
 * @author Sam Bugs
 * @notice This contracts adds Permit2 capabilities to existing contracts by acting as a proxy
 * @dev It's important to note that this contract should never hold any funds outside of the scope of a transaction,
 *      nor should it be granted "regular" ERC20 token approvals. This contract is meant to be used as a proxy, so
 *      the only tokens approved/transferred through Permit2 should be entirely spent in the same transaction.
 *      Any unspent allowance or remaining tokens on the contract can be transferred by anyone, so please be careful!
 */
abstract contract ArbitraryExecutionPermit2Adapter is BasePermit2Adapter, IArbitraryExecutionPermit2Adapter {
  using Permit2Transfers for IPermit2;
  using Token for address;
  using Token for IERC20;

  /// @inheritdoc IArbitraryExecutionPermit2Adapter
  function executeWithPermit(
    SinglePermit calldata _permit,
    AllowanceTarget[] calldata _allowanceTargets,
    ContractCall[] calldata _contractCalls,
    TransferOut[] calldata _transferOut,
    uint256 _deadline
  )
    external
    payable
    checkDeadline(_deadline)
    returns (bytes[] memory _executionResults, uint256[] memory _tokenBalances)
  {
    PERMIT2.takeFromCaller(_permit.token, _permit.amount, _permit.nonce, _deadline, _permit.signature);
    return _approveExecuteAndTransfer(_allowanceTargets, _contractCalls, _transferOut);
  }

  /// @inheritdoc IArbitraryExecutionPermit2Adapter
  function executeWithBatchPermit(
    BatchPermit calldata _batchPermit,
    AllowanceTarget[] calldata _allowanceTargets,
    ContractCall[] calldata _contractCalls,
    TransferOut[] calldata _transferOut,
    uint256 _deadline
  )
    external
    payable
    checkDeadline(_deadline)
    returns (bytes[] memory _executionResults, uint256[] memory _tokenBalances)
  {
    PERMIT2.batchTakeFromCaller(_batchPermit.tokens, _batchPermit.nonce, _deadline, _batchPermit.signature);
    return _approveExecuteAndTransfer(_allowanceTargets, _contractCalls, _transferOut);
  }

  function _approveExecuteAndTransfer(
    AllowanceTarget[] calldata _allowanceTargets,
    ContractCall[] calldata _contractCalls,
    TransferOut[] calldata _transferOut
  )
    internal
    returns (bytes[] memory _executionResults, uint256[] memory _tokenBalances)
  {
    // Approve targets
    for (uint256 i; i < _allowanceTargets.length;) {
      IERC20(_allowanceTargets[i].token).maxApprove(_allowanceTargets[i].allowanceTarget);
      unchecked {
        ++i;
      }
    }

    // Call contracts
    _executionResults = new bytes[](_contractCalls.length);
    for (uint256 i; i < _contractCalls.length;) {
      _executionResults[i] = _callContract(_contractCalls[i].target, _contractCalls[i].data, _contractCalls[i].value);
      unchecked {
        ++i;
      }
    }

    // Reset allowance to prevent attacks. Also, we are setting it to 1 instead of 0 for gas optimization
    for (uint256 i; i < _allowanceTargets.length;) {
      IERC20(_allowanceTargets[i].token).setAllowance(_allowanceTargets[i].allowanceTarget, 1);
      unchecked {
        ++i;
      }
    }

    // Distribute tokens
    _tokenBalances = new uint256[](_transferOut.length);
    for (uint256 i; i < _transferOut.length;) {
      _tokenBalances[i] = _transferOut[i].token.distributeTo(_transferOut[i].distribution);
      unchecked {
        ++i;
      }
    }
  }
}
