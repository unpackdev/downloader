// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IERC165.sol";
import "./JBBallotState.sol";
import "./IJBFundingCycleStore.sol";

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}
