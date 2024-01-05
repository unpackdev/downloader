// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./TotemToken.sol";

contract TotemVesting is Context, Ownable {
    using SafeMath for uint256;

    struct VestingSchedule {
        uint256 totalAmount; // Total amount of tokens to be vested.
        uint256 amountWithdrawn; // The amount that has been withdrawn.
    }

    mapping(address => VestingSchedule) public recipients;

    uint256 public startTime;
    bool public isStartTimeSet;
    uint256 public withdrawInterval; // Amount of time in seconds between withdrawal periods.
    uint256 public releasePeriods; // Number of periods from start release until done.
    uint256 public lockPeriods; // Number of periods before start release.

    uint256 public totalAmount; // Total amount of tokens to be vested.
    uint256 public unallocatedAmount; // The amount of tokens that are not allocated yet.

    TotemToken public totemToken;

    event VestingScheduleRegistered(
        address registeredAddress,
        uint256 totalAmount
    );
    event Withdraw(address registeredAddress, uint256 amountWithdrawn);
    event StartTimeSet(uint256 startTime);

    constructor(
        TotemToken _totemToken,
        uint256 _totalAmount,
        uint256 _withdrawInterval,
        uint256 _releasePeriods,
        uint256 _lockPeriods
    ) {
        require(_totalAmount > 0);
        require(_withdrawInterval > 0);
        require(_releasePeriods > 0);

        totemToken = _totemToken;

        totalAmount = _totalAmount;
        unallocatedAmount = _totalAmount;
        withdrawInterval = _withdrawInterval;
        releasePeriods = _releasePeriods;
        lockPeriods = _lockPeriods;

        isStartTimeSet = false;
    }

    function addRecipient(address _newRecipient, uint256 _totalAmount)
        public
        onlyOwner
    {
        // Only allow to add recipient before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp);

        require(_newRecipient != address(0));

        // If the vesting amount for the recipient was already set, remove it and update with the new amount
        if (recipients[_newRecipient].totalAmount > 0) {
            unallocatedAmount = unallocatedAmount.add(
                recipients[_newRecipient].totalAmount
            );
        }
        require(_totalAmount > 0 && _totalAmount <= unallocatedAmount);

        recipients[_newRecipient] = VestingSchedule({
            totalAmount: _totalAmount,
            amountWithdrawn: 0
        });
        unallocatedAmount = unallocatedAmount.sub(_totalAmount);

        emit VestingScheduleRegistered(_newRecipient, _totalAmount);
    }

    function setStartTime(uint256 _newStartTime) public onlyOwner {
        // Only allow to change start time before the counting starts
        require(!isStartTimeSet || startTime > block.timestamp);
        require(_newStartTime > block.timestamp);

        startTime = _newStartTime;
        isStartTimeSet = true;

        emit StartTimeSet(_newStartTime);
    }

    // Returns the amount of tokens you can withdraw
    function vested(address beneficiary)
        public
        view
        virtual
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

        uint256 lockAmount = _vestingSchedule.totalAmount.div(releasePeriods);

        uint256 vestedAmount = period.sub(lockPeriods).mul(lockAmount);
        return vestedAmount;
    }

    function withdrawable(address beneficiary)
        public
        view
        returns (uint256 amount)
    {
        return vested(beneficiary).sub(recipients[beneficiary].amountWithdrawn);
    }

    function withdraw() public {
        VestingSchedule storage vestingSchedule = recipients[_msgSender()];
        if (vestingSchedule.totalAmount == 0) return;

        uint256 _vested = vested(msg.sender);
        uint256 _withdrawable = withdrawable(msg.sender);
        vestingSchedule.amountWithdrawn = _vested;

        if (_withdrawable > 0) {
            require(totemToken.transfer(_msgSender(), _withdrawable));
            emit Withdraw(_msgSender(), _withdrawable);
        }
    }
}
