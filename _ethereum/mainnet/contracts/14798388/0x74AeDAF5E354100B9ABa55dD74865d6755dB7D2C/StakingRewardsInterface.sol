// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface StakingRewardsInterface {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function lastTimeRewardApplicable(address _rewardsToken)
        external
        view
        returns (uint256);

    function rewardPerToken(address _rewardsToken)
        external
        view
        returns (uint256);

    function earned(address _rewardsToken, address account)
        external
        view
        returns (uint256);

    function getRewardRate(address _rewardsToken)
        external
        view
        returns (uint256);

    function getRewardForDuration(address _rewardsToken)
        external
        view
        returns (uint256);

    function getRewardsTokenCount() external view returns (uint256);

    function getAllRewardsTokens() external view returns (address[] memory);

    function getStakingToken() external view returns (address);

    function stake(uint256 amount) external;

    function stakeFor(address account, uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawFor(address account, uint256 amount) external;

    function getReward() external;

    function getRewardFor(address account) external;

    function exit() external;
}
