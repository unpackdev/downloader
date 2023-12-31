// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./Utils.sol";

/**
 * this multicall extension is useful for chaining permissioned calls
 * in other words, calls that operate on the senders funds or settings
 */
contract MulticallExtension is Utils {
  error BlockHash(bytes32 expected, bytes32 actual);
  error Deadline(uint256 deadline, uint256 currentTime);
  event TxFailed(uint256 indexed index, bytes result);
  /**
   * call a series of functions on a contract that inherits this method
   * @param calls the calls to perform on this contract
   * @param allowFailures whether to allow failures or to error out
   */
  function multicall(
    bytes[] calldata calls,
    bool allowFailures
  ) external {
    _multicall({
      calls: calls,
      allowFailures: allowFailures
    });
  }
  /**
   * call multiple methods and pass a deadline, after which the transaction should fail
   * @param deadline the timestamp, in seconds
   * @param calls the calldata to run on the external method
   * @param allowFailures allows failures when true
   */
  function multicallWithDeadline(
    uint256 deadline,
    bytes[] calldata calls,
    bool allowFailures
  ) external {
    if (block.timestamp > deadline) {
      revert Deadline({
        deadline: deadline,
        currentTime: block.timestamp
      });
    }
    _multicall({
      calls: calls,
      allowFailures: allowFailures
    });
  }
  /**
   * pass the previous block hash to enable mev uncle bandit protection
   * @param previousBlockhash the previously mined block - useful for mev protected uncle bandit risks
   * @param calls the calldata to run on the external method
   * @param allowFailures allows failures when true
   */
  function multicallWithPreviousBlockHash(
    bytes32 previousBlockhash,
    bytes[] calldata calls,
    bool allowFailures
  ) external {
    if (blockhash(block.number - 1) != previousBlockhash) {
      revert BlockHash({
        expected: previousBlockhash,
        actual: blockhash(block.number - 1)
      });
    }
    _multicall({
      calls: calls,
      allowFailures: allowFailures
    });
  }
  /**
   * call multiple / arbitrary steps allowing each to fail independently or requiring all to succeed
   * @param calls the sequence of calls that is requested
   * @param allowFailures allows the calls to fail separately or requires all to succeed or fail
   */
  function _multicall(bytes[] calldata calls, bool allowFailures) internal {
    uint256 len = calls.length;
    uint256 i;
    bool success;
    bytes memory result;
    do {
      (success, result) = address(this).delegatecall(calls[i]);
      if (!success) {
        if (allowFailures) {
          emit TxFailed({
            index: i,
            result: result
          });
        } else {
          _bubbleRevert(result);
        }
      }
      unchecked {
        ++i;
      }
    } while (i < len);
  }
}
