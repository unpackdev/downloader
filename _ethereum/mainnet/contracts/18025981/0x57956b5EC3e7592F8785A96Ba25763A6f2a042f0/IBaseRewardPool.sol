// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IBaseRewardPool {
    function pid() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function stake(uint256 _amount) external returns (bool);

    function stakeAll() external returns (bool);

    function stakeFor(address _for, uint256 _amount) external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAll(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function getReward() external returns (bool);

    function getRewardFor(address _account, bool _claimExtras) external returns (uint256 rewardAmount);

    function processIdleRewards() external;

    function queueNewRewards(uint256 _rewards) external returns (bool);

    function extraRewardsLength() external view returns (uint256);

    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);
}
