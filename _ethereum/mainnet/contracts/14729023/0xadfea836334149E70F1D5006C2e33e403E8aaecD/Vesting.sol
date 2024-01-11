// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.9;

import "./IERC20.sol";
import "./AccessControl.sol";
import "./Mnt.sol";
import "./Buyback.sol";
import "./ErrorCodes.sol";

/**
 * @title Vesting contract provides unlocking of tokens on a schedule. It uses the *graded vesting* way,
 * which unlocks a specific amount of balance every period of time, until all balance unlocked.
 *
 * Vesting Schedule.
 *
 * The schedule of a vesting is described by data structure `VestingSchedule`: starting from the start timestamp
 * throughout the duration, the entire amount of totalAmount tokens will be unlocked.
 *
 * Interface.
 *
 * - `withdraw` - withdraw released tokens.
 * - `createVestingSchedule` - allows admin to create a new vesting schedule for an account.
 * - `revokeVestingSchedule` - allows admin to revoke the vesting schedule. Tokens already vested
 * transfer to the account, the rest are returned to the vesting contract.
 */

contract Vesting is AccessControl {
    /**
     * @notice The structure is used in the contract constructor for create vesting schedules
     * during contract deploying.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param target the address that will receive tokens according to schedule parameters.
     * @param start the timestamp in minutes at which vesting starts. Must not be equal to zero, as it is used to
     * check for the existence of a vesting schedule.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * @param revocable whether the vesting is revocable or not.
     */
    struct ScheduleData {
        uint256 totalAmount;
        address target;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /**
     * @notice Vesting schedules of an account.
     * @param totalAmount the number of tokens to be vested during the vesting duration.
     * @param released the amount of the token released. It means that the account has called withdraw() and received
     * @param start the timestamp in minutes at which vesting starts. Must not be equal to zero, as it is used to
     * check for the existence of a vesting schedule.
     * @param duration duration in minutes of the period in which the tokens will vest.
     * `released amount` of tokens to his address.
     * @param revocable whether the vesting is revocable or not.
     */
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 released;
        uint32 start;
        uint32 duration;
        bool revocable;
    }

    /**
     * @notice The address of the Minterest governance token.
     */
    IERC20 public mnt;

    /**
     * @notice Vesting schedule of an account.
     */
    mapping(address => VestingSchedule) public schedules;

    /**
     * @notice The number of MNT tokens that are currently not allocated in the vesting. This number of tokens
     * is free and can used to create vesting schedule for accounts. When the contract are deployed,
     * all tokens (49,967,630 MNT tokens) are vested according to the account's vesting schedules
     * and this value is equal to zero.
     */
    uint256 public freeAllocation = 49_967_630 ether;

    /**
     * @notice The address of the Minterest buyback.
     */
    Buyback public buyback;

    /// @notice Whether or not the account is in the delay list
    mapping(address => bool) public delayList;

    /// @notice is stake function paused
    bool public isWithdrawPaused;

    /// @notice The right part is the keccak-256 hash of variable name
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);

    /// @notice An event that's emitted when a new vesting schedule for a account is created.
    event VestingScheduleAdded(address target, VestingSchedule schedule);

    /// @notice An event that's emitted when a vesting schedule revoked.
    event VestingScheduleRevoked(address target, uint256 unreleased, uint256 locked);

    /// @notice An event that's emitted when the account Withdrawn the released tokens.
    event Withdrawn(address, uint256 withdrawn);

    /// @notice Emitted when buyback is changed
    event NewBuyback(Buyback oldBuyback, Buyback newBuyback);

    /// @notice Emitted when an action is paused
    event VestingActionPaused(string action, bool pauseState);

    /// @notice Emitted when an account is added to the delay list
    event AddedToDelayList(address account);

    /// @notice Emitted when an account is removed from the delay list
    event RemovedFromDelayList(address account);

    /**
     * @notice Construct a vesting contract.
     * @param _admin The address of the Admin
     * @param _mnt The address of the MNT contract.
     */
    constructor(address _admin, IERC20 _mnt) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(GATEKEEPER, _admin);
        mnt = _mnt;
    }

    function setBuyback(Buyback buyback_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Buyback oldBuyback = buyback;
        require(oldBuyback != buyback_, ErrorCodes.IDENTICAL_VALUE);
        buyback = buyback_;
        emit NewBuyback(oldBuyback, buyback_);
    }

    /**
     * @notice function to change withdraw enabled mode
     * @param isPaused_ new state of stake allowance
     */
    function setWithdrawPaused(bool isPaused_) external onlyRole(GATEKEEPER) {
        emit VestingActionPaused("Withdraw", isPaused_);
        isWithdrawPaused = isPaused_;
    }

    /**
     * @notice Withdraw the specified number of tokens. For a successful transaction, the requirement
     * `amount_ > 0 && amount_ <= unreleased` must be met.
     * If `amount_ == MaxUint256` withdraw all unreleased tokens.
     * @param amount_ The number of tokens to withdraw.
     */
    function withdraw(uint256 amount_) external {
        require(!isWithdrawPaused, ErrorCodes.OPERATION_PAUSED);
        require(!delayList[msg.sender], ErrorCodes.DELAY_LIST_LIMIT);

        VestingSchedule storage schedule = schedules[msg.sender];

        require(schedule.start != 0, ErrorCodes.NO_VESTING_SCHEDULES);

        uint256 unreleased = releasableAmount(msg.sender);
        if (amount_ == type(uint256).max) {
            amount_ = unreleased;
        }
        require(amount_ > 0 && amount_ <= unreleased, ErrorCodes.INSUFFICIENT_UNRELEASED_TOKENS);

        uint256 mntRemaining = mnt.balanceOf(address(this));
        require(amount_ <= mntRemaining, ErrorCodes.INSUFFICIENT_TOKEN_IN_VESTING_CONTRACT);

        schedule.released = schedule.released + amount_;
        // Remove the vesting schedule if all tokens were released to the account.
        if (schedule.released == schedule.totalAmount) {
            delete schedules[msg.sender];
        }

        emit Withdrawn(msg.sender, amount_);
        if (buyback != Buyback(address(0))) buyback.restakeFor(msg.sender);

        require(mnt.transfer(msg.sender, amount_));
    }

    /// @notice Allows the admin to create a new vesting schedules.
    /// @param schedulesData an array of vesting schedules that will be created.
    function createVestingScheduleBatch(ScheduleData[] memory schedulesData) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 length = schedulesData.length;

        uint256 mntRemaining = mnt.balanceOf(address(this));
        for (uint256 i = 0; i < length; i++) {
            ScheduleData memory schedule = schedulesData[i];

            ensureValidVestingSchedule(schedule.target, schedule.start, schedule.totalAmount);
            require(schedules[schedule.target].start == 0, ErrorCodes.VESTING_SCHEDULE_ALREADY_EXISTS);

            require(
                freeAllocation >= schedule.totalAmount && mntRemaining >= freeAllocation,
                ErrorCodes.INSUFFICIENT_TOKENS_TO_CREATE_SCHEDULE
            );

            schedules[schedule.target] = VestingSchedule({
                totalAmount: schedule.totalAmount,
                released: 0,
                start: schedule.start,
                duration: schedule.duration,
                revocable: schedule.revocable
            });

            //slither-disable-next-line costly-loop
            freeAllocation -= schedule.totalAmount;

            emit VestingScheduleAdded(schedule.target, schedules[schedule.target]);
            //slither-disable-next-line calls-loop
            if (buyback != Buyback(address(0))) buyback.restakeFor(schedule.target);
        }
    }

    /// @notice Allows the admin to revoke the vesting schedule. Tokens already vested
    ///  transfer to the account, the rest are returned to the vesting contract.
    /// @param target_ the address from which the vesting schedule is revoked.
    function revokeVestingSchedule(address target_) external onlyRole(GATEKEEPER) {
        require(schedules[target_].start != 0, ErrorCodes.NO_VESTING_SCHEDULE);
        require(schedules[target_].revocable, ErrorCodes.SCHEDULE_IS_IRREVOCABLE);

        uint256 locked = lockedAmount(target_);
        uint256 unreleased = releasableAmount(target_);
        uint256 mntRemaining = mnt.balanceOf(address(this));

        require(mntRemaining >= unreleased, ErrorCodes.INSUFFICIENT_TOKENS_FOR_RELEASE);

        freeAllocation += locked;
        delete schedules[target_];
        delete delayList[target_];

        emit VestingScheduleRevoked(target_, unreleased, locked);
        if (buyback != Buyback(address(0))) buyback.restakeFor(target_);

        require(mnt.transfer(target_, unreleased));
    }

    /// @notice Calculates the end of the vesting.
    /// @param who_ account address for which the parameter is returned.
    /// @return the end of the vesting.
    function endOfVesting(address who_) external view returns (uint256) {
        VestingSchedule storage schedule = schedules[who_];
        return uint256(schedule.start) + uint256(schedule.duration);
    }

    /// @notice Calculates locked amount for a given `time`.
    /// @param who_ account address for which the parameter is returned.
    /// @return locked amount for a given `time`.
    function lockedAmount(address who_) public view returns (uint256) {
        // lockedAmount = (end - time) * totalAmount / duration;
        // if the parameter `duration` is zero, it means that the allocated tokens are not locked for address `who`.

        // solhint-disable-next-line not-rely-on-time
        uint256 _now = getTime();
        VestingSchedule storage schedule = schedules[who_];

        uint256 _start = uint256(schedule.start);
        uint256 _duration = uint256(schedule.duration);
        uint256 _end = _start + _duration;
        if (schedule.duration == 0 || _now > _end) {
            return 0;
        }
        if (_now < _start) {
            return schedule.totalAmount;
        }
        return ((_end - _now) * schedule.totalAmount) / _duration;
    }

    /// @notice Calculates the amount that has already vested.
    /// @param who_ account address for which the parameter is returned.
    /// @return the amount that has already vested.
    function vestedAmount(address who_) public view returns (uint256) {
        return schedules[who_].totalAmount - lockedAmount(who_);
    }

    /// @notice Calculates the amount that has already vested but hasn't been released yet.
    /// @param who_ account address for which the parameter is returned.
    /// @return the amount that has already vested but hasn't been released yet.
    function releasableAmount(address who_) public view returns (uint256) {
        return vestedAmount(who_) - schedules[who_].released;
    }

    /// @notice Checks if the Vesting schedule is correct.
    /// @param target_ the address on which the vesting schedule is created.
    /// @param start_ the time (as Unix time) at which point vesting starts.
    /// @param amount_ the balance for which the vesting schedule is created.
    function ensureValidVestingSchedule(
        address target_,
        uint32 start_,
        uint256 amount_
    ) public pure {
        require(target_ != address(0), ErrorCodes.TARGET_ADDRESS_CANNOT_BE_ZERO);
        require(amount_ > 0, ErrorCodes.MNT_AMOUNT_IS_ZERO);
        // Star should not be zero, because this parameter is used to check for the existence of a schedule.
        require(start_ > 0, ErrorCodes.SCHEDULE_START_IS_ZERO);
    }

    /// @notice Add an account with revocable schedule to the delay list
    /// @param who_ The account that is being added to the delay list
    function addToDelayList(address who_) external onlyRole(GATEKEEPER) {
        require(schedules[who_].revocable, ErrorCodes.SHOULD_HAVE_REVOCABLE_SCHEDULE);
        emit AddedToDelayList(who_);
        delayList[who_] = true;
    }

    /// @notice Remove an account from the delay list
    /// @param who_ The account that is being removed from the delay list
    function removeFromDelayList(address who_) external onlyRole(GATEKEEPER) {
        require(delayList[who_], ErrorCodes.MEMBER_NOT_IN_DELAY_LIST);
        emit RemovedFromDelayList(who_);
        delete delayList[who_];
    }

    /// @return timestamp truncated to minutes
    //slither-disable-next-line dead-code
    function getTime() internal view virtual returns (uint256) {
        return block.timestamp / 1 minutes;
    }
}
