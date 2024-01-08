// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import "./EnumerableSet.sol";
import "./IStrategy.sol";
import "./IAlphaJob.sol";
import "./Governable.sol";
import "./Keep3rJob.sol";
import "./Pausable.sol";

contract AlphaJob is IAlphaJob, Governable, Pausable, Keep3rJob {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet internal _strategies;

  constructor(
    address _governor,
    address _keep3r,
    address _bond,
    uint256 _minBond,
    uint256 _earned,
    uint256 _age,
    bool _onlyEOA
  ) Governable(_governor) Keep3rJob(_keep3r, _bond, _minBond, _earned, _age, _onlyEOA) {}

  function strategies() external view override returns (address[] memory _list) {
    _list = new address[](_strategies.length());
    for (uint256 i; i < _strategies.length(); i++) {
      _list[i] = _strategies.at(i);
    }
  }

  function addStrategy(address _strategy) external override onlyGovernor {
    if (_strategies.contains(_strategy)) revert StrategyAlreadyAdded();

    _strategies.add(_strategy);
    emit StrategyAddition(_strategy);
  }

  function revokeStrategy(address _strategy) external override onlyGovernor {
    if (!_strategies.contains(_strategy)) revert StrategyNotExistent();

    _strategies.remove(_strategy);
    emit StrategyRevokation(_strategy);
  }

  function workable() public view override returns (address _workableStrategy) {
    if (paused) return address(0);

    for (uint256 _i = 0; _i < _strategies.length(); _i++) {
      address _strategy = _strategies.at(_i);
      if (IStrategy(_strategy).shouldRebalance()) {
        return _strategy;
      }
    }
  }

  function workable(address _strategy) public view override returns (bool) {
    return !paused && IStrategy(_strategy).shouldRebalance();
  }

  function work(address _strategy) external override validateAndPayKeeper(msg.sender) {
    if (!workable(_strategy)) revert StrategyNotWorkable();
    IStrategy(_strategy).rebalance();
  }

  function forceWork(address _strategy) external override onlyGovernor {
    IStrategy(_strategy).rebalance();
  }
}
