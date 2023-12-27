// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface ISimulationAdapter {
  /// @notice A simulation's result
  struct SimulationResult {
    bool success;
    bytes result;
    uint256 gasSpent;
  }

  /**
   * @notice Executes individual simulations against this contract but doesn't modify the state when doing so
   * @dev This function is meant to be used for off-chain simulation and should not be called on-chain
   * @param calls The calls to simulate
   * @return results Each simulation result
   */
  function simulate(bytes[] calldata calls) external payable returns (SimulationResult[] memory results);
}
