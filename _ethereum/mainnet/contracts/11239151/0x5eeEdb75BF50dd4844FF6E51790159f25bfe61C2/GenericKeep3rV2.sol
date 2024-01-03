// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import "./SafeMath.sol";
import "./EnumerableSet.sol";

import "./IStrategyKeep3r.sol";
import "./IBaseStrategy.sol";

import "./Governable.sol";
import "./CollectableDust.sol";

import "./Keep3rAbstract.sol";

contract GenericKeep3rV2 is Governable, CollectableDust, Keep3r, IStrategyKeep3r {
    using SafeMath for uint256;

    EnumerableSet.AddressSet internal availableStrategies;
    mapping(address => uint256) public requiredHarvest;
    mapping(address => uint256) public requiredTend;

    constructor(address _keep3r) public Governable(msg.sender) CollectableDust() Keep3r(_keep3r) {}

    // Unique method to add a strategy to the system
    // If you don't require tend, use _requiredTend = 0
    // If you don't require harvest, use _requiredHarvest = 0
    function addStrategy(
        address _strategy,
        uint256 _requiredHarvest,
        uint256 _requiredTend
    ) external override onlyGovernor {
        require(_requiredHarvest > 0 || _requiredTend > 0, "generic-keep3r-v2::add-strategy:should-need-harvest-or-tend");
        if (_requiredHarvest > 0) {
            _addHarvestStrategy(_strategy, _requiredHarvest);
        }

        if (_requiredTend > 0) {
            _addTendStrategy(_strategy, _requiredTend);
        }

        availableStrategies.add(_strategy);
    }

    function _addHarvestStrategy(address _strategy, uint256 _requiredHarvest) internal {
        require(requiredHarvest[_strategy] == 0, "generic-keep3r-v2::add-harvest-strategy:strategy-already-added");
        _setRequiredHarvest(_strategy, _requiredHarvest);
        emit HarvestStrategyAdded(_strategy, _requiredHarvest);
    }

    function _addTendStrategy(address _strategy, uint256 _requiredTend) internal {
        require(requiredTend[_strategy] == 0, "generic-keep3r-v2::add-tend-strategy:strategy-already-added");
        _setRequiredTend(_strategy, _requiredTend);
        emit TendStrategyAdded(_strategy, _requiredTend);
    }

    function updateRequiredHarvestAmount(address _strategy, uint256 _requiredHarvest) external override onlyGovernor {
        require(requiredHarvest[_strategy] > 0, "generic-keep3r-v2::update-required-harvest:strategy-not-added");
        _setRequiredHarvest(_strategy, _requiredHarvest);
        emit HarvestStrategyModified(_strategy, _requiredHarvest);
    }

    function updateRequiredTendAmount(address _strategy, uint256 _requiredTend) external override onlyGovernor {
        require(requiredTend[_strategy] > 0, "generic-keep3r-v2::update-required-tend:strategy-not-added");
        _setRequiredTend(_strategy, _requiredTend);
        emit TendStrategyModified(_strategy, _requiredTend);
    }

    function removeHarvestStrategy(address _strategy) external override onlyGovernor {
        require(requiredHarvest[_strategy] > 0, "generic-keep3r-v2::remove-harvest-strategy:strategy-not-added");
        requiredHarvest[_strategy] = 0;

        if (requiredTend[_strategy] == 0) {
            availableStrategies.remove(_strategy);
        }

        emit HarvestStrategyRemoved(_strategy);
    }

    function removeTendStrategy(address _strategy) external override onlyGovernor {
        require(requiredTend[_strategy] > 0, "generic-keep3r-v2::remove-tend-strategy:strategy-not-added");
        requiredTend[_strategy] = 0;

        if (requiredHarvest[_strategy] == 0) {
            availableStrategies.remove(_strategy);
        }

        emit TendStrategyRemoved(_strategy);
    }

    function setKeep3r(address _keep3r) external override onlyGovernor {
        _setKeep3r(_keep3r);
        emit Keep3rSet(_keep3r);
    }

    function _setRequiredHarvest(address _strategy, uint256 _requiredHarvest) internal {
        require(_requiredHarvest > 0, "generic-keep3r-v2::set-required-harvest:should-not-be-zero");
        requiredHarvest[_strategy] = _requiredHarvest;
    }

    function _setRequiredTend(address _strategy, uint256 _requiredTend) internal {
        require(_requiredTend > 0, "generic-keep3r-v2::set-required-tend:should-not-be-zero");
        requiredTend[_strategy] = _requiredTend;
    }

    // Getters
    function name() external pure override returns (string memory) {
        return "Generic Vault V2 Strategy Keep3r";
    }

    function strategies() public view override returns (address[] memory _strategies) {
        _strategies = new address[](availableStrategies.length());
        for (uint256 i; i < availableStrategies.length(); i++) {
            _strategies[i] = availableStrategies.at(i);
        }
    }

    function harvestable(address _strategy) public view override returns (bool) {
        require(requiredHarvest[_strategy] > 0, "generic-keep3r-v2::harvestable:strategy-not-added");
        return IBaseStrategy(_strategy).harvestTrigger(requiredHarvest[_strategy]);
    }

    function tendable(address _strategy) public view override returns (bool) {
        require(requiredTend[_strategy] > 0, "generic-keep3r-v2::tendable:strategy-not-added");
        return IBaseStrategy(_strategy).tendTrigger(requiredTend[_strategy]);
    }

    // Keep3r actions
    function harvest(address _strategy) external override paysKeeper {
        require(harvestable(_strategy), "generic-keep3r-v2::harvest:not-workable");
        _harvest(_strategy);
        emit HarvestedByKeeper(_strategy);
    }

    function tend(address _strategy) external override paysKeeper {
        require(tendable(_strategy), "generic-keep3r-v2::tend:not-workable");
        _tend(_strategy);
        emit TendedByKeeper(_strategy);
    }

    function _harvest(address _strategy) internal {
        IBaseStrategy(_strategy).harvest();
    }

    function _tend(address _strategy) internal {
        IBaseStrategy(_strategy).tend();
    }

    // Governable
    function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
        _setPendingGovernor(_pendingGovernor);
    }

    function acceptGovernor() external override onlyPendingGovernor {
        _acceptGovernor();
    }

    // Collectable Dust
    function sendDust(
        address _to,
        address _token,
        uint256 _amount
    ) external override onlyGovernor {
        _sendDust(_to, _token, _amount);
    }
}
