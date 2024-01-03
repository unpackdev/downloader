// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

struct UserDeposit {
    uint256 cumulativeBalance;
    uint256 averageDepositTime;
    uint256 rewardsAccumulatedPerToken;
    uint256 rewardsOutstanding;
}

interface IAcrossStaker {
    function getUserStake(
        address stakedToken,
        address account
    ) external view returns (UserDeposit memory);

    function getOutstandingRewards(
        address stakedToken,
        address account
    ) external view returns (uint256);

    function unstake(address stakedToken, uint256 amount) external;

    function withdrawReward(address stakedToken) external;

    function stake(address stakedToken, uint256 amount) external;
}
