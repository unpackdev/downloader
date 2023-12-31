// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IBaseRewardPool {
    function balanceOf(address account) external view returns (uint256);

    function extraRewards(uint256 i) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewards(address) external view returns (uint256);

    function rewardToken() external view returns (address);

    function userRewardPerTokenPaid(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReward() external returns (bool);

    function getReward(address _account, bool _claimExtras) external returns (bool);

    function withdrawAllAndUnwrap(bool claim) external;

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function operator() external returns (address);

    function queueNewRewards(uint256 _rewards) external returns (bool);
}
