// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;

import "./IERC20.sol";

interface IMultiRewarderV2 {
    function lpToken() external view returns (IERC20 lpToken);

    function onReward(address _user, uint256 _lpAmount) external returns (uint256[] memory rewards);

    function addRewardToken(IERC20 _rewardToken, uint40 _startTimestamp, uint96 _tokenPerSec) external;

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}
