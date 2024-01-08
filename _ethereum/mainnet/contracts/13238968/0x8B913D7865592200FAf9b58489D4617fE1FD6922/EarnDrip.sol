// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

import "./PoolRewards.sol";
import "./IVesperPool.sol";

contract VesperEarnDrip is PoolRewards {
    /**
     * @dev Notify that reward is added.
     * Also updates reward rate and reward earning period.
     */
    function notifyRewardAmount(
        address _rewardToken,
        uint256 _rewardAmount,
        uint256 _rewardDuration
    ) external override {
        (bool isStrategy, , , , , , , ) = IVesperPool(pool).strategy(msg.sender);
        require(msg.sender == IVesperPool(pool).governor() || isStrategy, "not-authorized");
        super._notifyRewardAmount(_rewardToken, _rewardAmount, _rewardDuration, IVesperPool(pool).totalSupply());
    }
}
