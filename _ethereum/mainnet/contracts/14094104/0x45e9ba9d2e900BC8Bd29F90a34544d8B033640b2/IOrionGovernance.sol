// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

interface IOrionGovernance
{
    function stake(uint56 adding_amount) external;
    function withdraw(uint56 removing_amount) external;

    //  Accepting lock by absolute value
    function acceptNewLockAmount(address user, uint56 new_lock_amount) external;

    //  Accepting lock by diff
    function acceptLock(address user, uint56 lock_increase_amount) external;
    function acceptUnlock(address user, uint56 lock_decrease_amount) external;

    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function getRewardForDuration() external view returns (uint256);

    function getReward() external;
    function exit() external;
}
