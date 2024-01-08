// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILBP {
  function setSwapEnabled(bool swapEnabled) external;

  function getSwapEnabled() external returns (bool);

  /**
   * @dev Schedule a gradual weight change, from the current weights to the given
   * endWeights, over startTime to endTime
   */
  function updateWeightsGradually(
    uint256 startTime,
    uint256 endTime,
    uint256[] memory endWeights
  ) external;

  function getPoolId() external returns (bytes32 poolID);
}
