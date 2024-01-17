// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DefifaTierRedemptionWeight.sol";
import "./IDefifaDelegate.sol";

interface IDefifaGovernor {
  function MAX_VOTING_POWER_TIER() external view returns (uint256);

  function defifaDelegate() external view returns (IDefifaDelegate);

  function votingStartTime() external view returns (uint256);

  function submitScorecards(DefifaTierRedemptionWeight[] calldata _tierWeights)
    external
    returns (uint256);

  function ratifyScorecard(DefifaTierRedemptionWeight[] calldata _tierWeights)
    external
    returns (uint256);
}
