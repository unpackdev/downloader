// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./SafeMath.sol";
import "./TotemVesting.sol";
import "./BasisPoints.sol";

contract PrivateSaleVesting is TotemVesting {
    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public constant TOTAL_AMOUNT = 2000000 * (10**18);
    uint256 public constant WITHDRAW_INTERVAL = 30 days;
    uint256 public constant RELEASE_PERIODS = 5;
    uint256 public constant LOCK_PERIODS = 0;

    uint256 public constant INITIAL_UNLOCK = 2250;

    constructor(TotemToken _totemToken)
        TotemVesting(
            _totemToken,
            TOTAL_AMOUNT,
            WITHDRAW_INTERVAL,
            RELEASE_PERIODS,
            LOCK_PERIODS
        )
    {}

    // Returns the amount of tokens you can withdraw
    function vested(address beneficiary)
        public
        view
        override
        returns (uint256 _amountVested)
    {
        VestingSchedule memory _vestingSchedule = recipients[beneficiary];
        if (
            !isStartTimeSet ||
            (_vestingSchedule.totalAmount == 0) ||
            (lockPeriods == 0 && releasePeriods == 0) ||
            (block.timestamp < startTime)
        ) {
            return 0;
        }

        uint256 endLock = withdrawInterval.mul(lockPeriods);
        if (block.timestamp < startTime.add(endLock)) {
            return 0;
        }

        uint256 _end = withdrawInterval.mul(lockPeriods.add(releasePeriods));
        if (block.timestamp >= startTime.add(_end)) {
            return _vestingSchedule.totalAmount;
        }

        uint256 period =
            block.timestamp.sub(startTime).div(withdrawInterval) + 1;
        if (period <= lockPeriods) {
            return 0;
        }
        if (period >= lockPeriods.add(releasePeriods)) {
            return _vestingSchedule.totalAmount;
        }

        uint256 initialUnlockAmount =
            _vestingSchedule.totalAmount.mulBP(INITIAL_UNLOCK);

        if (period.sub(lockPeriods) == 1) {
            return initialUnlockAmount;
        }

        uint256 lockAmount =
            _vestingSchedule.totalAmount.sub(initialUnlockAmount).div(
                releasePeriods - 1
            );

        uint256 vestedAmount =
            period.sub(lockPeriods + 1).mul(lockAmount).add(
                initialUnlockAmount
            );
        return vestedAmount;
    }
}
