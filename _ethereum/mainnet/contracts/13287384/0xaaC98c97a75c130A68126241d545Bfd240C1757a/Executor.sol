// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./TimelockController.sol";
import "./Policy.sol";

contract Executor is TimelockController, Policy {
  event ExecutorInitialized();

  /// @param minDelay Minimum delay for propose execution
  /// @param proposers Governance core address
  /// @param executors Executors address
  /// @param token_ The address of the token representing voting rights
  /// @param minVotingPower Minimum voting power requirement
  /// @param quorumNumerator_ The quorum numerator
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors,
    address token_,
    uint256 minVotingPower,
    uint16 quorumNumerator_
  )
    TimelockController(minDelay, proposers, executors)
    Policy(token_, minVotingPower, quorumNumerator_)
  {}

  function init(address governanceCore) public {
    grantRole(POLICY_ADMIN_ROLE, governanceCore);
    grantRole(PROPOSER_ROLE, governanceCore);
    grantRole(EXECUTOR_ROLE, address(0));
    emit ExecutorInitialized();
  }
}
