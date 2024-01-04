// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


interface IScoringStrategy {
  function getTokenScores(address[] calldata tokens) external view returns (uint256[] memory scores);
}