// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import "./IERC165.sol";
import "./ISimulationAdapter.sol";

/**
 * @title Simulation Adapter
 * @author Sam Bugs
 * @notice This contracts adds off-chain simulation capabilities to existing contracts. It works similarly to a
 *         multicall, but the state is not modified in each subcall.
 */
abstract contract SimulationAdapter is IERC165, ISimulationAdapter {
  /// @notice An error that contains a simulation's result
  error SimulatedCall(SimulationResult result);

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return _interfaceId == type(ISimulationAdapter).interfaceId || _interfaceId == type(IERC165).interfaceId;
  }

  /// @inheritdoc ISimulationAdapter
  function simulate(bytes[] calldata _calls) external payable returns (SimulationResult[] memory _results) {
    _results = new SimulationResult[](_calls.length);
    for (uint256 i = 0; i < _calls.length; i++) {
      _results[i] = _simulate(_calls[i]);
    }
    return _results;
  }

  /**
   * @notice Executes a simulation and returns the result
   * @param _call The call to simulate
   * @return _simulationResult The simulation's result
   */
  function _simulate(bytes calldata _call) internal returns (SimulationResult memory _simulationResult) {
    (bool _success, bytes memory _result) =
    // solhint-disable-next-line avoid-low-level-calls
     address(this).delegatecall(abi.encodeWithSelector(this.simulateAndRevert.selector, _call));
    require(!_success, "WTF? Should have failed!");
    // Move pointer to ignore selector
    // solhint-disable-next-line no-inline-assembly
    assembly {
      _result := add(_result, 0x04)
    }
    (_simulationResult) = abi.decode(_result, (SimulationResult));
  }

  /**
   * @notice Executes a call agains this contract and reverts with the result
   * @dev This is meant to be used internally, do not call!
   * @param _call The call to simulate
   */
  function simulateAndRevert(bytes calldata _call) external payable {
    uint256 _gasAtStart = gasleft();
    // solhint-disable-next-line avoid-low-level-calls
    (bool _success, bytes memory _result) = address(this).delegatecall(_call);
    uint256 _gasSpent = _gasAtStart - gasleft();
    revert SimulatedCall(SimulationResult({ success: _success, result: _result, gasSpent: _gasSpent }));
  }
}
