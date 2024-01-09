//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.12;

import "./IERC20.sol";

interface IRewarder {
    function onRewardTokenReward(uint256 pid, address user, address recipient, uint256 rewardTokenAmount, uint256 newLpAmount) external;
    function pendingTokens(uint256 pid, address user, uint256 rewardTokenAmount) external view returns (IERC20[] memory, uint256[] memory);
}
