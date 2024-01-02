// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IMultiplier.sol";
import "./IPenaltyFee.sol";
import "./IStakingPool.sol";

contract PenaltyFee is IPenaltyFee {
    uint256 public constant MULTIPLIER_BASIS = 1e4;
    uint256[] public penaltyFeePerGroup;

    constructor(uint256[] memory _penaltyFeePerGroup) {
        for (uint256 i = 0; i < _penaltyFeePerGroup.length; i++) {
            require(_penaltyFeePerGroup[i] < MULTIPLIER_BASIS, "PenaltyFee::constructor: penaltyBasis >= MAX_ALLOWED_PENALTY");
        }
        penaltyFeePerGroup = _penaltyFeePerGroup;
    }

    function calculate(
        uint256 _amount,
        uint256 _duration,
        address _pool
    ) external view override returns (uint256) {
        IMultiplier rewardsMultiplier = IStakingPool(_pool).rewardsMultiplier();
        uint256 group = rewardsMultiplier.getDurationGroup(_duration);
        return (_amount * penaltyFeePerGroup[group]) / MULTIPLIER_BASIS;
    }
}
