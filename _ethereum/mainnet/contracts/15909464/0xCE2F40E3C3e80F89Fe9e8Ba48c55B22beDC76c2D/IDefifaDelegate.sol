// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./IJB721TieredGovernance.sol";
import "./DefifaTierRedemptionWeight.sol";

interface IDefifaDelegate is IJB721TieredGovernance {
  function TOTAL_REDEMPTION_WEIGHT() external returns (uint256);

  function tierRedemptionWeights() external returns (uint256[100] memory);

  function setTierRedemptionWeights(DefifaTierRedemptionWeight[] memory _tierWeights) external;
}
