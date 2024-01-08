// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

/**
 * @title IVesting
 * @author Enjinstarter
 */
interface IVesting {
    enum ReleaseMethod {
        IntervalEnd, // 0: at end of each interval
        LinearlyPerSecond //  1: linearly per second across interval
    }

    function addVestingGrant(
        address account,
        uint256 grantAmount,
        bool isRevocable
    ) external;

    function revokeVestingGrant(address account) external;

    function release() external;

    function transferUnusedTokens() external;

    function addVestingGrantsBatch(
        address[] memory accounts,
        uint256[] memory grantAmounts,
        bool[] memory isRevocables
    ) external;

    function setScheduleStartTimestamp(uint256 scheduleStartTimestamp_)
        external;

    function setGovernanceAccount(address account) external;

    function setVestingAdmin(address account) external;

    function getVestingSchedule()
        external
        view
        returns (
            uint256 cliffDurationDays,
            uint256 percentReleaseAtGrantStart,
            uint256 percentReleaseAtIntervalStart,
            uint256 intervalDays,
            uint256 gapDays,
            uint256 numberOfIntervals,
            ReleaseMethod releaseMethod
        );

    function vestingGrantFor(address account)
        external
        view
        returns (
            uint256 grantAmount,
            bool isRevocable,
            bool isRevoked,
            bool isActive
        );

    function revoked(address account) external view returns (bool isRevoked);

    function releasedAmountFor(address account)
        external
        view
        returns (uint256 releasedAmount);

    function releasableAmountFor(address account)
        external
        view
        returns (uint256 unreleasedAmount);

    function vestedAmountFor(address account)
        external
        view
        returns (uint256 vestedAmount);

    function unvestedAmountFor(address account)
        external
        view
        returns (uint256 unvestedAmount);

    event VestingGrantAdded(
        address indexed account,
        uint256 indexed grantAmount,
        bool isRevocable
    );
    event VestingGrantRevoked(
        address indexed account,
        uint256 remainderAmount,
        uint256 grantAmount,
        uint256 releasedAmount
    );
    event TokensReleased(address indexed account, uint256 amount);
    event ScheduleStartTimestampSet(
        address indexed account,
        uint256 newScheduleStartTimestamp,
        uint256 oldScheduleStartTimestamp
    );
}
