//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./RewardPeriodLib.sol";

interface IRewardPeriodsRegistry {
    event RewardPeriodCreated(
        address indexed creator,
        uint256 period,
        uint256 startPeriodTimestamp,
        uint256 endPeriodTimestamp,
        uint256 endRedeemablePeriodTimestamp,
        uint256 availableRewards
    );

    event RewardPeriodRemoved(
        address indexed remover,
        uint256 period,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 availableRewards
    );

    function settings() external view returns (address);

    function getRewardPeriod(uint256 id)
        external
        view
        returns (RewardPeriodLib.RewardPeriod memory);

    function notifyRewardsSent(uint256 period, uint256 totalRewardsSent)
        external
        returns (uint256 newTotalAvailableRewards);

    function createRewardPeriod(
        uint256 startPeriodTimestamp,
        uint256 endPeriodTimestamp,
        uint256 endRedeemablePeriodTimestamp,
        uint256 availableRewards
    ) external;

    function getRewardPeriods() external view returns (RewardPeriodLib.RewardPeriod[] memory);

    function getLastRewardPeriod()
        external
        view
        returns (
            uint256 periodId,
            uint256 startPeriodTimestamp,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            uint256 totalRewards,
            uint256 availableRewards,
            bool exists
        );

    function getRewardPeriodById(uint256 periodId)
        external
        view
        returns (
            uint256 id,
            uint256 startPeriodTimestamp,
            uint256 endPeriodTimestamp,
            uint256 endRedeemablePeriodTimestamp,
            uint256 totalRewards,
            uint256 availableRewards,
            bool exists
        );
}
