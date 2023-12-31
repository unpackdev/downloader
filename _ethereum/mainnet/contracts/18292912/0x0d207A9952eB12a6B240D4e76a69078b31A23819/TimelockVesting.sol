// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./SafeERC20.sol";
import "./TwoStepOwnable.sol";

/**
 * @title TimelockVesting
 * @notice A token holder contract that can release its token balance gradually like a
 *         typical vesting scheme, with a cliff and vesting period. Owner has the power
 *         to change the beneficiary who receives the vested tokens.
 * @author Hourglass Foundation
 */
contract TimelockVesting is TwoStepOwnable {
    using SafeERC20 for IERC20;

    error InvalidTotalAmount();
    error InvalidAmount();
    error InvalidBeneficiary();
    error InvalidStartTimestamp();
    error InvalidCliffStart(uint256 cliffDate, uint256 paramTimestamp);
    error InvalidDuration();
    error InvalidReleaseAmount();

    /// @notice The vesting token
    address internal _vestingToken;

    /// @notice Vesting schedule parameters
    /// @param amount amount of tokens to be vested
    /// @param startTimestamp unix timestamp of the start of vesting
    /// @param cliff unix timestamp of the cliff, before which no vesting counts
    /// @param duration duration in seconds of the period in which the tokens will vest
    /// @param released amount of tokens released
    struct VestingSchedule {
        uint256 amount;
        uint256 startTimestamp;
        uint256 cliff;
        uint256 duration;
        uint256 released;
    }

    /// @notice Internal storage of beneficiary address --> vesting schedule array
    mapping(address => VestingSchedule[]) internal _schedules;


    /// @param __vestingToken address of the token that is subject to vesting
    constructor(address __vestingToken) {
        _setInitialOwner(msg.sender);
        require(__vestingToken != address(0));
        _vestingToken = __vestingToken;
    }

    /// @notice Allows for adding multiple vests with a single call.
    /// @param _beneficiaries array of addresses of the beneficiaries to whom vested tokens are transferred
    /// @param _amounts array of amounts of tokens to be vested
    /// @param _startTimestamps array of unix timestamps of the start of vesting
    /// @param _cliffDates array of unix timestamps of the cliff, before which no vesting counts
    /// @param _durationInSeconds array of durations in seconds of the period in which the tokens will vest
    /// @param _totalBatchTokenAmount total amount of tokens to be vested across all beneficiaries (sanity check)
    /// @dev Call this with a script that validates that all arrays are equal length & that
    ///      all addresses, amounts, timestamps & durations != 0
    function addBatchBeneficiaries(
        address[] calldata _beneficiaries,
        uint256[] calldata _amounts,
        uint256[] calldata _startTimestamps,
        uint256[] calldata _cliffDates,
        uint256[] calldata _durationInSeconds,
        uint256 _totalBatchTokenAmount
    ) external onlyOwner {
        // pull in the tokens for this batch
        IERC20(_vestingToken).safeTransferFrom(msg.sender, address(this), _totalBatchTokenAmount);

        uint256 totalVestingAmount;

        // add each vesting schedule
        uint256 numVests = _beneficiaries.length;
        for (uint256 i; i < numVests;) {
            _addBeneficiary(
                _beneficiaries[i],
                _amounts[i],
                _startTimestamps[i],
                _cliffDates[i],
                _durationInSeconds[i]
            );

            totalVestingAmount += _amounts[i];

            unchecked {
                ++i;
            }
        }
        
        if (totalVestingAmount != _totalBatchTokenAmount) {
            revert InvalidTotalAmount();
        }
    }

    /// @notice Initializes a vesting contract that vests its balance of any ERC20 token to the
    ///    _beneficiary in a linear fashion until duration has passed. By then all
    ///    of the balance will have vested.
    /// @param _beneficiary address of the beneficiary to whom vested tokens are transferred
    /// @param _amount amount of tokens to be vested
    /// @param _startTimestamp unix timestamp of the start of vesting
    /// @param _cliffDate unix timestamp of the cliff, before which no vesting counts
    /// @param _durationInSeconds duration in seconds of the period in which the tokens will vest
    function addBeneficiary(
        address _beneficiary,
        uint256 _amount,
        uint256 _startTimestamp,
        uint256 _cliffDate,
        uint256 _durationInSeconds
    ) public onlyOwner {
        // pull in the tokens for this beneficiary
        IERC20(_vestingToken).safeTransferFrom(msg.sender, address(this), _amount);

        _addBeneficiary(_beneficiary, _amount, _startTimestamp, _cliffDate, _durationInSeconds);
    }

    function _addBeneficiary(
        address _beneficiary,
        uint256 _amount,
        uint256 _startTimestamp,
        uint256 _cliffDate,
        uint256 _durationInSeconds
    ) internal {
        // sanity checks
        if (_amount == 0) revert InvalidAmount();
        if (_beneficiary == address(0)) revert InvalidBeneficiary();
        if (_startTimestamp == 0) revert InvalidStartTimestamp();
        if (_durationInSeconds == 0) revert InvalidDuration();
        if (_cliffDate <= _startTimestamp) revert InvalidCliffStart(_cliffDate, _startTimestamp);
        if (_cliffDate > _startTimestamp + _durationInSeconds) revert InvalidCliffStart(_cliffDate, _startTimestamp + _durationInSeconds);

        // add the vesting schedule
        _schedules[_beneficiary].push(VestingSchedule(
            _amount,
            _startTimestamp,
            _cliffDate,
            _durationInSeconds,
            0
        ));

        emit VestingInitialized(
            _beneficiary,
            _amount,
            _startTimestamp,
            _cliffDate,
            _durationInSeconds
        );
    }

    /// @notice Transfers vested tokens to beneficiary.
    /// @dev This won't revert if nothing is claimable, but nothing will be claimed.
    /// @param _beneficiary Address of beneficiary to claim tokens for.
    /// @param _scheduleId Id of schedule to claim tokens for.
    function release(address _beneficiary, uint256 _scheduleId) external {
        if (_beneficiary == address(0)) revert InvalidBeneficiary();

        // Transfer vested tokens to beneficiary
        IERC20(_vestingToken).safeTransfer(_beneficiary, _release(_beneficiary, _scheduleId));//releasedAmt);
    }

    /// @notice Allows beneficiary to claim vested tokens across multiple schedules.
    /// @dev This won't revert if nothing is claimable, but nothing will be transferred.
    /// @param _beneficiary Address of beneficiary to claim tokens for.
    /// @param _scheduleIds Array of schedule ids to claim tokens for.
    function releaseMultiple(address _beneficiary, uint256[] calldata _scheduleIds) external {
        uint256 numSchedules = _scheduleIds.length;
        uint256 releasedAmt;
        for (uint256 i; i < numSchedules; i++) {
            releasedAmt += _release(_beneficiary, _scheduleIds[i]);
        }

        // transfer vested tokens to beneficiary
        IERC20(_vestingToken).safeTransfer(_beneficiary, releasedAmt);
    }

    /// @notice Updates the amount released & returns the amount to distribute for this `_scheduleId`.
    function _release(address _beneficiary, uint256 _scheduleId) internal returns (uint256 vested) {
        VestingSchedule memory schedule = _schedules[_beneficiary][_scheduleId];

        vested = _vestedAmount(schedule);

        // instead of reverting, return 0 if nothing is due so multiple schedules can be checked
        if (vested == 0) {
            return 0;
        }

        // otherwise updated released amount
        _schedules[_beneficiary][_scheduleId].released += vested;

        // sanity check
        if (schedule.released > schedule.amount) revert InvalidReleaseAmount();

        emit Released(_beneficiary, _scheduleId, vested);
    }

    /// @notice Calculates the amount that has already vested but hasn't been released yet.
    function _vestedAmount(VestingSchedule memory schedule) internal view returns (uint256) {
        // cliff hasn't passed yet neither has start time, so 0 vested
        if (block.timestamp < schedule.cliff) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp - schedule.startTimestamp;

        // If over vesting duration, all tokens vested
        if (elapsedTime >= schedule.duration) {
            // deduct already released tokens
            return schedule.amount - schedule.released; 
        } else {
            // if 75 seconds have passed of the 100 seconds, then 3/4 of the amount should be released.
            uint256 vested = schedule.amount * elapsedTime / schedule.duration;
            return (vested - schedule.released); 
        }
    }

    /// @notice Changes beneficiary who receives the vested token.
    /// @dev Only governance can call this function. This is to be used in case the target address
    ///   needs to be updated. If the previous beneficiary has any unclaimed tokens, the new beneficiary
    ///   will be able to claim them and the rest of the vested tokens.
    /// @param oldBeneficiary address of the previous beneficiary
    /// @param newBeneficiary new address to become the beneficiary
    /// @param scheduleIds array of schedule ids to migrate to the new beneficiary
    function changeBeneficiary(address oldBeneficiary, address newBeneficiary, uint256[] calldata scheduleIds) external onlyOwner {
        if (newBeneficiary == address(0)) revert InvalidBeneficiary();
        if (newBeneficiary == oldBeneficiary) revert InvalidBeneficiary();

        uint256 numSchedules = scheduleIds.length;
        // iterate from the end to avoid having to delete & move every schedule element each iteration
        for (uint256 i; i < numSchedules; i++) {
            VestingSchedule memory schedule = _schedules[oldBeneficiary][scheduleIds[i]];

            // migrate the schedule to the new beneficiary
            _schedules[newBeneficiary].push(schedule);

            // rather than deleting, set amount to the amount released  & duration to 0
            //   to avoid having to delete & move every schedule element each iteration
            //   and to avoid breaking the amount released logic in _vestedAmount()
            _schedules[oldBeneficiary][scheduleIds[i]].amount = schedule.released;
            _schedules[oldBeneficiary][scheduleIds[i]].duration = 0;
            emit SetBeneficiary(oldBeneficiary, scheduleIds[i], newBeneficiary, _schedules[newBeneficiary].length - 1);
        }
    }

    /// @notice Allows the owner to terminate a vesting schedule and recover the unvested tokens.
    /// @param _beneficiary Address of beneficiary to terminate vesting for.
    /// @param _scheduleId Id of schedule to terminate.
    function terminateVest(address _beneficiary, uint256 _scheduleId) external onlyOwner {
        // _release(_beneficiary, _scheduleId);

        VestingSchedule memory schedule = _schedules[_beneficiary][_scheduleId];
        // calculate the amount accrued to date
        uint256 vested = _vestedAmount(schedule);// - schedule.released;
        uint256 unreleased = schedule.amount - (schedule.released + vested);

        // delete the vest
        delete _schedules[_beneficiary][_scheduleId];

        // transfer out the tokens
        IERC20(_vestingToken).safeTransfer(msg.sender, unreleased);
        IERC20(_vestingToken).safeTransfer(_beneficiary, vested);
    }


    ////////// Getter Functions //////////

    /// @notice Checks the amount of currently vested tokens available for release.
    /// @dev Note that this will return a value > 0 if there are any tokens available to claim,
    /// @param _beneficiary The address of the beneficiary.
    /// @param _scheduleId The index of the schedule array.
    /// @return The number of tokens that are vested and available to claim.
    function getClaimableAmount(address _beneficiary, uint256 _scheduleId) external view returns (uint256) {
        VestingSchedule memory schedule = _schedules[_beneficiary][_scheduleId];
        return _vestedAmount(schedule);
    }

    /// @notice Obtain a specific schedule for a user.
    /// @dev Note that this will return a schedule even if it has been transferred.
    /// @param _beneficiary The address of the beneficiary.
    /// @param _scheduleId The index of the schedule array.
    /// @return The vesting schedule.
    function getSchedule(address _beneficiary, uint256 _scheduleId) external view returns (VestingSchedule memory) {
        return _schedules[_beneficiary][_scheduleId];
    }

    /// @notice Obtain the length of a user's schedule array.
    /// @dev Note that this will return a length that includes deleted schedules.
    /// @param _beneficiary The address of the beneficiary.
    /// @return The length of the schedule array.
    function getNumberSchedules(address _beneficiary) external view returns (uint256) {
        return _schedules[_beneficiary].length;
    }

    /// @notice Obtain the total amount of tokens released to a user thus far.
    /// @param _beneficiary The address of the beneficiary.
    /// @return The total amount of tokens released.
    function getTotalAmountReleased(address _beneficiary) external view returns (uint256) {
        uint256 numSchedules = _schedules[_beneficiary].length;
        uint256 totalReleased;
        for (uint256 i; i < numSchedules; i++) {
            totalReleased += _schedules[_beneficiary][i].released;
        }
        return totalReleased;
    }

    /// @notice Get the token being vested.
    /// @return The token address.
    function vestingToken() public view returns (address) {
        return _vestingToken;
    }

    
    ////////// EVENTS //////////
    /// @notice Emitted when a beneficiary claims vested tokens.
    event Released(address indexed beneficiary, uint256 scheduleId, uint256 amount);
    /// @notice Emitted when a new vesting schedule is created.
    event VestingInitialized(
        address indexed beneficiary, 
        uint256 amount,
        uint256 startTimestamp,
        uint256 cliff,
        uint256 duration
    );
    /// @notice Emitted when a beneficiary is changed.
    event SetBeneficiary(address indexed oldBeneficiary, uint256 oldBeneficiaryScheduleIndex, address indexed newBeneficiary, uint256 newBeneficiaryScheduleIndex);
    /// @notice Emitted when whether votes can be counted is changed.
    event BeneficiaryVotes(bool voting);
}