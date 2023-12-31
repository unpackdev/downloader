// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardManager {
    function withdrawRewardTokens(
        address _token,
        address _recipient,
        uint256 _amount
    ) external;

    function totalRewardCount(address _token) external view returns (uint256);

    function getRewardFrom(
        address _token,
        uint256 _index
    ) external view returns (uint256);

    function totalAddedRewards(
        address _token,
        uint256 index
    ) external view returns (uint256);

    function rewardAddTime(address _token) external view returns (uint256);

    function totalTokens() external view returns (uint256);

    function rewardToken(uint256 _index) external view returns (address);

    function isRewardToken(address _token) external view returns (bool);

    function totalRewardShareTribot(
        address _token,
        uint256 index
    ) external view returns (uint256);

    function totalRewardShareUsdt(
        address _token,
        uint256 index
    ) external view returns (uint256);

    function totalRewardSharePlus(
        address _token,
        uint256 index
    ) external view returns (uint256);

    function getRewardPoolShare(
        address _user
    ) external view returns (uint256 currentShare);
}
