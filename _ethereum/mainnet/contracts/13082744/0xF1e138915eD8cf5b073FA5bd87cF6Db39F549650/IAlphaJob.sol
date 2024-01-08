// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./IGovernable.sol";
import "./IKeep3rJob.sol";
import "./IPausable.sol";

interface IAlphaJob is IGovernable, IPausable, IKeep3rJob {
  // errors
  error StrategyNotWorkable();
  error StrategyNotExistent();
  error StrategyAlreadyAdded();

  // methods
  function strategies() external view returns (address[] memory _strategies);

  function addStrategy(address _strategy) external;

  function revokeStrategy(address _strategy) external;

  function workable() external view returns (address _workableStrategy);

  function workable(address _strategy) external view returns (bool _isWorkable);

  function work(address _strategy) external;

  function forceWork(address _strategy) external;

  // events
  event StrategyAddition(address _strategy);
  event StrategyRevokation(address _strategy);
}
