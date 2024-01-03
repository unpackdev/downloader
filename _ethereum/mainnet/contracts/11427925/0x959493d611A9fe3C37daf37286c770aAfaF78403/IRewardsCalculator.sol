//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface IRewardsCalculator {
    function getRewards(
        uint256 period,
        address account,
        uint256 totalRewards,
        uint256 totalAvailableRewards
    ) external view returns (uint256);

    function processRewards(
        uint256 period,
        address account,
        uint256 totalRewards,
        uint256 totalAvailableRewards
    ) external returns (uint256 rewardsForAccount);
}
