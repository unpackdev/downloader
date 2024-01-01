// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IMultiplier.sol";

contract ConstantMultiplier is IMultiplier {
    struct MultiplierThreshold {
        uint256 threshold;
        uint256 multiplier;
    }

    MultiplierThreshold[] public durationThresholds;

    uint256 public constant MULTIPLIER_BASIS = 1e4;

    /**
     * @notice Both arrays should be in ascending order.
     * @param _durationThresholds The duration thresholds
     */
    constructor(MultiplierThreshold[] memory _durationThresholds) {
        for (uint256 i = 0; i < _durationThresholds.length; i++) {
            MultiplierThreshold memory threshold = _durationThresholds[i];
            require(threshold.threshold > 0, "ConstantMultiplier::setMultiplierThresholds: threshold = 0");
            require(threshold.multiplier > 0, "ConstantMultiplier::setMultiplierThresholds: multiplier = 0");
            durationThresholds.push(threshold);
        }
    }

    function applyMultiplier(uint256 _amount, uint256 _duration) external view override returns (uint256) {
        uint256 multiplier = getMultiplier(_amount, _duration);
        return (_amount * multiplier) / MULTIPLIER_BASIS;
    }

    function getMultiplier(uint256 _amount, uint256 _duration) public view override returns (uint256) {
        return getDurationMultiplier(_duration);
    }

    function getDurationGroup(uint256 _duration) public view override returns (uint256) {
        for (uint256 i = durationThresholds.length - 1; i > 0; i--) {
            // The duration thresholds are sorted in ascending order
            MultiplierThreshold memory threshold = durationThresholds[i];
            if (_duration >= threshold.threshold) {
                return i;
            }
        }
        return 0;
    }

    function getDurationMultiplier(uint256 _duration) public view override returns (uint256) {
        uint256 group = getDurationGroup(_duration);
        return durationThresholds[group].multiplier;
    }

    function getDurationThresholds() external view returns (MultiplierThreshold[] memory) {
        return durationThresholds;
    }
}
