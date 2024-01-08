// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface ILiquidityMiningStaking {
    function blocksWithRewardsPassed() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address _account) external view returns (uint256);

    function earnedSlashed(address _account) external view returns (uint256);

    function stakeFor(address _user, uint256 _amount) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function getReward() external;

    function restake() external;

    function exit() external;

    function getAPY() external view returns (uint256);
}
