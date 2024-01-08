// SPDX-License-Identifier: Apache-2.0
// Copyright 2021 Enjinstarter
pragma solidity ^0.7.6;

import "./SafeERC20.sol";
import "./IVesting.sol";

/**
 * @title Vesting
 * @author Enjinstarter
 */
contract Vesting is IVesting {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct VestingSchedule {
        uint256 cliffDurationDays; // Cliff duration in days with respect to the start of vesting schedule
        uint256 percentReleaseAtScheduleStart; // Percentage of grant amount to be released in wei at start of vesting schedule
        uint256 percentReleaseForEachInterval; // Percentage of grant amount to be released in wei for each interval after cliff duration
        uint256 intervalDays; // Vesting interval in days
        uint256 gapDays; // Gap between intervals in days
        uint256 numberOfIntervals; // Number of intervals
        ReleaseMethod releaseMethod;
    }

    struct VestingGrant {
        uint256 grantAmount; // Total number of tokens granted
        bool isRevocable; // true if vesting grant is revocable (a gift), false if irrevocable (purchased)
        bool isRevoked; // true if vesting grant has been revoked
        bool isActive; // true if vesting grant is active
    }

    uint256 public constant BATCH_MAX_NUM = 200;
    uint256 public constant PERCENT_100_WEI = 100 ether;
    uint256 public constant SECONDS_IN_DAY = 86400;

    address public governanceAccount;
    address public vestingAdmin;
    address public tokenAddress;
    uint256 public totalGrantAmount;
    uint256 public totalReleasedAmount;
    uint256 public scheduleStartTimestamp;
    bool public allowAccumulate;

    VestingSchedule private _vestingSchedule;
    mapping(address => VestingGrant) private _vestingGrants;
    mapping(address => uint256) private _released;

    constructor(
        address tokenAddress_,
        uint256 cliffDurationDays,
        uint256 percentReleaseAtScheduleStart,
        uint256 percentReleaseForEachInterval,
        uint256 intervalDays,
        uint256 gapDays,
        uint256 numberOfIntervals,
        ReleaseMethod releaseMethod,
        bool allowAccumulate_
    ) {
        require(tokenAddress_ != address(0), "Vesting: zero token address");
        require(
            percentReleaseAtScheduleStart <= PERCENT_100_WEI,
            "Vesting: percent release at grant start > 100%"
        );
        require(
            percentReleaseForEachInterval <= PERCENT_100_WEI,
            "Vesting: percent release for each interval > 100%"
        );
        require(intervalDays > 0, "Vesting: zero interval");
        require(
            percentReleaseAtScheduleStart.add(
                percentReleaseForEachInterval.mul(numberOfIntervals)
            ) <= PERCENT_100_WEI,
            "Vesting: total percent release > 100%"
        );

        governanceAccount = msg.sender;
        vestingAdmin = msg.sender;
        tokenAddress = tokenAddress_;

        _vestingSchedule.cliffDurationDays = cliffDurationDays;
        _vestingSchedule
            .percentReleaseAtScheduleStart = percentReleaseAtScheduleStart;
        _vestingSchedule
            .percentReleaseForEachInterval = percentReleaseForEachInterval;
        _vestingSchedule.intervalDays = intervalDays;
        _vestingSchedule.gapDays = gapDays;
        _vestingSchedule.numberOfIntervals = numberOfIntervals;
        _vestingSchedule.releaseMethod = releaseMethod;

        allowAccumulate = allowAccumulate_;
    }

    modifier onlyBy(address account) {
        require(msg.sender == account, "Vesting: sender unauthorized");
        _;
    }

    /**
     * @dev isRevocable will be ignored if grant already added but amount allowed to accumulate.
     */
    function addVestingGrant(
        address account,
        uint256 grantAmount,
        bool isRevocable
    ) external override onlyBy(vestingAdmin) {
        _addVestingGrant(account, grantAmount, isRevocable);
    }

    function revokeVestingGrant(address account)
        external
        override
        onlyBy(vestingAdmin)
    {
        _revokeVestingGrant(account);
    }

    function release() external override {
        uint256 releasableAmount = releasableAmountFor(msg.sender);

        _release(msg.sender, releasableAmount);
    }

    function transferUnusedTokens()
        external
        override
        onlyBy(governanceAccount)
    {
        uint256 unusedAmount = IERC20(tokenAddress)
            .balanceOf(address(this))
            .add(totalReleasedAmount)
            .sub(totalGrantAmount);
        require(unusedAmount > 0, "Vesting: nothing to transfer");

        IERC20(tokenAddress).safeTransfer(governanceAccount, unusedAmount);
    }

    function addVestingGrantsBatch(
        address[] memory accounts,
        uint256[] memory grantAmounts,
        bool[] memory isRevocables
    ) external override onlyBy(vestingAdmin) {
        require(accounts.length > 0, "Vesting: empty");
        require(accounts.length <= BATCH_MAX_NUM, "Vesting: exceed max");
        require(
            grantAmounts.length == accounts.length,
            "Vesting: grant amounts length different"
        );
        require(
            isRevocables.length == accounts.length,
            "Vesting: is revocables length different"
        );

        for (uint256 i = 0; i < accounts.length; i++) {
            _addVestingGrant(accounts[i], grantAmounts[i], isRevocables[i]);
        }
    }

    function setScheduleStartTimestamp(uint256 scheduleStartTimestamp_)
        external
        override
        onlyBy(vestingAdmin)
    {
        require(
            scheduleStartTimestamp_ > block.timestamp,
            "Vesting: start before current timestamp"
        );

        uint256 oldScheduleStartTimestamp = scheduleStartTimestamp;
        require(
            oldScheduleStartTimestamp == 0 ||
                block.timestamp < oldScheduleStartTimestamp,
            "Vesting: already started"
        );

        scheduleStartTimestamp = scheduleStartTimestamp_;

        emit ScheduleStartTimestampSet(
            msg.sender,
            scheduleStartTimestamp_,
            oldScheduleStartTimestamp
        );
    }

    function setGovernanceAccount(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(account != address(0), "Vesting: zero account");

        governanceAccount = account;
    }

    function setVestingAdmin(address account)
        external
        override
        onlyBy(governanceAccount)
    {
        require(account != address(0), "Vesting: zero account");

        vestingAdmin = account;
    }

    function getVestingSchedule()
        external
        view
        override
        returns (
            uint256 cliffDurationDays,
            uint256 percentReleaseAtScheduleStart,
            uint256 percentReleaseForEachInterval,
            uint256 intervalDays,
            uint256 gapDays,
            uint256 numberOfIntervals,
            ReleaseMethod releaseMethod
        )
    {
        VestingSchedule memory vestingSchedule = _vestingSchedule;
        cliffDurationDays = vestingSchedule.cliffDurationDays;
        percentReleaseAtScheduleStart = vestingSchedule
            .percentReleaseAtScheduleStart;
        percentReleaseForEachInterval = vestingSchedule
            .percentReleaseForEachInterval;
        intervalDays = vestingSchedule.intervalDays;
        gapDays = vestingSchedule.gapDays;
        numberOfIntervals = vestingSchedule.numberOfIntervals;
        releaseMethod = vestingSchedule.releaseMethod;
    }

    function vestingGrantFor(address account)
        external
        view
        override
        returns (
            uint256 grantAmount,
            bool isRevocable,
            bool isRevoked,
            bool isActive
        )
    {
        require(account != address(0), "Vesting: zero account");

        VestingGrant memory vestingGrant = _vestingGrants[account];
        grantAmount = vestingGrant.grantAmount;
        isRevocable = vestingGrant.isRevocable;
        isRevoked = vestingGrant.isRevoked;
        isActive = vestingGrant.isActive;
    }

    function revoked(address account)
        public
        view
        override
        returns (bool isRevoked)
    {
        require(account != address(0), "Vesting: zero account");

        isRevoked = _vestingGrants[account].isRevoked;
    }

    function releasedAmountFor(address account)
        public
        view
        override
        returns (uint256 releasedAmount)
    {
        require(account != address(0), "Vesting: zero account");

        releasedAmount = _released[account];
    }

    function releasableAmountFor(address account)
        public
        view
        override
        returns (uint256 releasableAmount)
    {
        require(account != address(0), "Vesting: zero account");

        uint256 startTimestamp = scheduleStartTimestamp;
        require(startTimestamp > 0, "Vesting: undefined start time");
        require(block.timestamp >= startTimestamp, "Vesting: not started");

        require(!revoked(account), "Vesting: revoked");

        uint256 vestedAmount = vestedAmountFor(account);
        releasableAmount = vestedAmount.sub(releasedAmountFor(account));
    }

    function vestedAmountFor(address account)
        public
        view
        override
        returns (uint256 vestedAmount)
    {
        require(account != address(0), "Vesting: zero account");

        VestingGrant memory vestingGrant = _vestingGrants[account];
        require(vestingGrant.isActive, "Vesting: inactive");

        uint256 startTimestamp = scheduleStartTimestamp;

        if (startTimestamp == 0) {
            return 0;
        }

        if (block.timestamp < startTimestamp) {
            return 0;
        }

        if (revoked(account)) {
            return releasedAmountFor(account);
        }

        VestingSchedule memory vestingSchedule = _vestingSchedule;

        vestedAmount = 0;

        if (vestingSchedule.percentReleaseAtScheduleStart > 0) {
            vestedAmount = vestingGrant
                .grantAmount
                .mul(vestingSchedule.percentReleaseAtScheduleStart)
                .div(PERCENT_100_WEI);
        }

        uint256 cliffEndTimestamp = startTimestamp.add(
            vestingSchedule.cliffDurationDays.mul(SECONDS_IN_DAY)
        );
        if (block.timestamp < cliffEndTimestamp) {
            return vestedAmount;
        }

        uint256 intervalSeconds = vestingSchedule.intervalDays.mul(
            SECONDS_IN_DAY
        );
        uint256 gapSeconds = vestingSchedule.gapDays.mul(SECONDS_IN_DAY);
        uint256 scheduleEndTimestamp = cliffEndTimestamp
            .add(intervalSeconds.mul(vestingSchedule.numberOfIntervals))
            .add(gapSeconds.mul(vestingSchedule.numberOfIntervals.sub(1)));
        if (block.timestamp >= scheduleEndTimestamp) {
            vestedAmount = vestingGrant.grantAmount;
            return vestedAmount;
        }

        // https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
        // slither-disable-next-line divide-before-multiply
        uint256 intervalNumber = block.timestamp.sub(cliffEndTimestamp).div(
            intervalSeconds.add(gapSeconds)
        );
        require(
            intervalNumber < vestingSchedule.numberOfIntervals,
            "Vesting: unexpected interval number"
        );

        // https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
        // slither-disable-next-line divide-before-multiply
        uint256 totalPercentage = vestingSchedule
            .percentReleaseForEachInterval
            .mul(intervalNumber);
        if (vestingSchedule.releaseMethod == ReleaseMethod.IntervalEnd) {
            // solhint-disable-previous-line no-empty-blocks
        } else if (
            vestingSchedule.releaseMethod == ReleaseMethod.LinearlyPerSecond
        ) {
            // https://github.com/crytic/slither/wiki/Detector-Documentation#divide-before-multiply
            // slither-disable-next-line divide-before-multiply
            uint256 secondsInInterval = block.timestamp.sub(
                cliffEndTimestamp.add(
                    intervalSeconds.add(gapSeconds).mul(intervalNumber)
                )
            );
            totalPercentage = secondsInInterval >= intervalSeconds
                ? totalPercentage.add(
                    vestingSchedule.percentReleaseForEachInterval
                )
                : totalPercentage.add(
                    vestingSchedule
                        .percentReleaseForEachInterval
                        .mul(secondsInInterval)
                        .div(intervalSeconds)
                );
        } else {
            require(false, "Vesting: unexpected release method");
        }

        uint256 maxPercentage = PERCENT_100_WEI.sub(
            vestingSchedule.percentReleaseAtScheduleStart
        );
        if (totalPercentage > maxPercentage) {
            totalPercentage = maxPercentage;
        }

        vestedAmount = vestedAmount.add(
            vestingGrant.grantAmount.mul(totalPercentage).div(PERCENT_100_WEI)
        );
    }

    function unvestedAmountFor(address account)
        external
        view
        override
        returns (uint256 unvestedAmount)
    {
        require(account != address(0), "Vesting: zero account");

        VestingGrant memory vestingGrant = _vestingGrants[account];
        require(vestingGrant.isActive, "Vesting: inactive");

        if (revoked(account)) {
            unvestedAmount = 0;
        } else {
            unvestedAmount = vestingGrant.grantAmount.sub(
                vestedAmountFor(account)
            );
        }
    }

    function _addVestingGrant(
        address account,
        uint256 grantAmount,
        bool isRevocable
    ) private {
        require(account != address(0), "Vesting: zero account");
        require(grantAmount > 0, "Vesting: zero grant amount");

        uint256 startTimestamp = scheduleStartTimestamp;
        require(
            startTimestamp == 0 || block.timestamp < startTimestamp,
            "Vesting: already started"
        );

        VestingGrant memory vestingGrant = _vestingGrants[account];
        require(
            allowAccumulate || !vestingGrant.isActive,
            "Vesting: already added"
        );
        require(!revoked(account), "Vesting: already revoked");

        totalGrantAmount = totalGrantAmount.add(grantAmount);
        require(
            totalGrantAmount <= IERC20(tokenAddress).balanceOf(address(this)),
            "Vesting: total grant amount exceed balance"
        );

        if (vestingGrant.isActive) {
            _vestingGrants[account].grantAmount = vestingGrant.grantAmount.add(
                grantAmount
            );
            // _vestingGrants[account].isRevocable = isRevocable;
        } else {
            _vestingGrants[account] = VestingGrant({
                grantAmount: grantAmount,
                isRevocable: isRevocable,
                isRevoked: false,
                isActive: true
            });
        }

        emit VestingGrantAdded(account, grantAmount, isRevocable);
    }

    function _revokeVestingGrant(address account) private {
        require(account != address(0), "Vesting: zero account");

        VestingGrant memory vestingGrant = _vestingGrants[account];
        require(vestingGrant.isActive, "Vesting: inactive");
        require(vestingGrant.isRevocable, "Vesting: not revocable");
        require(!revoked(account), "Vesting: already revoked");

        uint256 releasedAmount = releasedAmountFor(account);
        uint256 remainderAmount = vestingGrant.grantAmount.sub(releasedAmount);
        totalGrantAmount = totalGrantAmount.sub(remainderAmount);
        _vestingGrants[account].isRevoked = true;

        emit VestingGrantRevoked(
            account,
            remainderAmount,
            vestingGrant.grantAmount,
            releasedAmount
        );
    }

    function _release(address account, uint256 amount) private {
        require(account != address(0), "Vesting: zero account");
        require(amount > 0, "Vesting: zero amount");

        _released[account] = _released[account].add(amount);
        totalReleasedAmount = totalReleasedAmount.add(amount);

        emit TokensReleased(account, amount);

        IERC20(tokenAddress).safeTransfer(account, amount);
    }
}
