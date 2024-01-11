// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/// @title GaugeProxy contract
/// @notice Handles Curve gauges reward voting and distribution
interface IGaugeProxy {
  /// @dev Vote weight used on disabled pools is computed in totalWeight but not reflected in the actual distribution
  /// @return _totalWeight Sum of total weight used on all the pools
  function totalWeight() external returns (uint256 _totalWeight);

  /// @return _keeper Address with access permission to call distribute function
  function keeper() external returns (address _keeper);

  /// @notice Governance has permission to manage gauges, and force the distribution
  /// @return _gov Address of Governance
  function gov() external returns (address _gov);

  /// @return _nextGov Address of the proposed next governance
  function nextgov() external returns (address _nextGov);

  /// @return _commitGov Datetime when next governance can execute transition
  function commitgov() external returns (uint256 _commitGov);

  /// @return _delay Time in seconds to pass between a next governance proposal and it's execution
  function delay() external returns (uint256 _delay);

  /// @param _pool Address of the pool being checked
  /// @return _gauge Address of the gauge related to the input pool
  function gauges(address _pool) external view returns (address _gauge);

  /// @param _pool Address of the pool being checked
  /// @return _weight Amount of weight vote on the pool
  function weights(address _pool) external view returns (uint256 _weight);

  /// @dev The vote weight decays with time and this function does not reflect that
  /// @param _voter Address of the voter being checked
  /// @param _pool Address of the pool being checked
  /// @return _votes Amount of vote weight from the voter, on the pool
  function votes(address _voter, address _pool) external view returns (uint256 _votes);

  /// @param _voter Address of the voter being checked
  /// @param _i Index of the pool being checked
  /// @return _pool Addresses of the voted pools of a voter
  function tokenVote(address _voter, uint256 _i) external view returns (address _pool);

  /// @param _voter Address of the voter being checked
  /// @return _usedWeights Total amount of used weight of a voter
  function usedWeights(address _voter) external view returns (uint256 _usedWeights);

  /// @param _pool Address of the pool being checked
  /// @return _enabled Whether the pool is enabled
  function enabled(address _pool) external view returns (bool _enabled);

  /// @return _pools Array of pools added to the contract
  function tokens() external view returns (address[] memory _pools);

  /// @notice Allows governance to modify the keeper address
  /// @param _keeper Address of the new keeper being set
  function setKeeper(address _keeper) external;

  /// @notice Allows governance to propose a new governance
  function setGov(address _gov) external;

  /// @notice Allows new governance to execute the transition
  /// @dev Requires a delay time between the proposal and the execution
  function acceptGov() external;

  /// @notice Resets function caller vote distribution
  function reset() external;

  /// @notice Refresh a voter weight distributio to current state
  /// @dev Vote weight decays with time and this function allows to refresh it
  /// @param _voter Address of the voter veing poked
  function poke(address _voter) external;

  /// @notice Allows a voter to submit a vote distribution
  /// @dev Voter is always using its full weight, inputed weights get ponderated
  /// @param _poolVote Array of addresses being voted
  /// @param _weights Distribution of vote weight to use on addresses
  function vote(address[] calldata _poolVote, uint256[] calldata _weights) external;

  /// @notice Allows governance to register a new gauge
  /// @param _pool Address of the pool to reward
  /// @param _gauge Address of the gauge to reward the pool
  function addGauge(address _pool, address _gauge) external;

  /// @notice Allows governance to disable a pool reward
  /// @dev Vote weight deposited on disabled tokens is taken out of the total weight
  /// @param _pool Address of the pool being disabled
  function disable(address _pool) external;

  /// @notice Allows governance to reenable a pool reward
  /// @param _pool Address of the pool being enabled
  function enable(address _pool) external;

  /// returns _lenght Total amount of rewarded pools
  function length() external view returns (uint256 _lenght);

  /// @notice Allows governance to execute a reward distribution
  function forceDistribute() external;

  /// @notice Function to be upkeep responsible for executing rKP3Rs reward distribution
  function distribute() external;
}
