// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IMultiplier.sol";
import "./IStakingPool.sol";

contract ConstantMultiplier is IMultiplier {
    struct MultiplierThreshold {
        uint256 threshold;
        uint256 multiplier;
    }

    // Multiplier Thresholds
    MultiplierThreshold[] public amountThresholds;
    MultiplierThreshold[] public durationThresholds;

    uint256 public constant MULTIPLIER_BASIS = 1e4;

    /**
     * @notice Both arrays should be in ascending order.
     * @param _amountThresholds The amount thresholds
     * @param _durationThresholds The duration thresholds
     */
    constructor(MultiplierThreshold[] memory _amountThresholds, MultiplierThreshold[] memory _durationThresholds) {
        for (uint256 i = 0; i < _amountThresholds.length; i++) {
            MultiplierThreshold memory threshold = _amountThresholds[i];
            require(threshold.threshold > 0, "ConstantMultiplier::setMultiplierThresholds: threshold = 0");
            require(threshold.multiplier > 0, "ConstantMultiplier::setMultiplierThresholds: multiplier = 0");
            amountThresholds.push(threshold);
        }

        for (uint256 i = 0; i < _durationThresholds.length; i++) {
            MultiplierThreshold memory threshold = _durationThresholds[i];
            require(threshold.threshold > 0, "ConstantMultiplier::setMultiplierThresholds: threshold = 0");
            require(threshold.multiplier > 0, "ConstantMultiplier::setMultiplierThresholds: multiplier = 0");
            durationThresholds.push(threshold);
        }
    }

    function applyMultiplier(
        uint256 _amount,
        address _beneficiary,
        address _pool
    ) external view override returns (uint256) {
        uint256 multiplier = getMultiplier(_beneficiary, _pool);
        return (_amount * multiplier) / MULTIPLIER_BASIS;
    }

    function getDurationGroup(uint256 _duration) public view override returns (uint8) {
        for (uint256 i = 0; i < durationThresholds.length; i++) {
            // The duration thresholds are sorted in ascending order
            MultiplierThreshold memory threshold = durationThresholds[i];
            if (_duration <= threshold.threshold) {
                return uint8(i);
            }
        }
        return uint8(durationThresholds.length - 1);
    }

    function getDurationMultiplier(uint256 _duration) public view override returns (uint256) {
        uint8 group = getDurationGroup(_duration);
        return durationThresholds[group].multiplier;
    }

    function getAmountGroup(uint256 _amount) public view override returns (uint8) {
        for (uint256 i = 0; i < amountThresholds.length; i++) {
            // The duration thresholds are sorted in ascending order
            MultiplierThreshold memory threshold = amountThresholds[i];
            if (_amount <= threshold.threshold) {
                return uint8(i);
            }
        }
        return uint8(amountThresholds.length - 1);
    }

    function getAmountMultiplier(uint256 _amount) public view override returns (uint256) {
        uint8 group = getAmountGroup(_amount);
        return amountThresholds[group].multiplier;
    }

    function getAmountThresholds() external view returns (MultiplierThreshold[] memory) {
        return amountThresholds;
    }

    function getDurationThresholds() external view returns (MultiplierThreshold[] memory) {
        return durationThresholds;
    }

    function getMultiplier(address _beneficiary, address _pool) public view override returns (uint256) {
        uint256 stakedAmount = IStakingPool(_pool).balanceOf(_beneficiary);
        uint256 stakedDuration = IStakingPool(_pool).userStakeDuration(_beneficiary);
        return getMultiplierForAmountAndDuration(stakedAmount, stakedDuration);
    }

    function getMultiplierForAmountAndDuration(uint256 _amount, uint256 _duration) public view returns (uint256) {
        return (getAmountMultiplier(_amount) * getDurationMultiplier(_duration)) / MULTIPLIER_BASIS;
    }
}
