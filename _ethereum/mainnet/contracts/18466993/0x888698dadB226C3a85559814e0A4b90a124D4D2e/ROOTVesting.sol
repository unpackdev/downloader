// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./Ownable.sol";

/**
 * @title ROOTVesting
 * @notice This is a simple vesting contract that allows to create vesting schedules for a beneficiary with 
 * daily/weekly/monthly and/or cliff unlocking.
 */
contract ROOTVesting is Ownable {
    using SafeERC20 for IERC20;

    /**
     * @notice The token to be vested
     */
    IERC20 public immutable token;

    struct VestingSchedule {
        // beneficiary of tokens after they are released
        address beneficiary;
        // start time of the vesting period
        uint256 start;
        // duration of the vesting period in months
        uint256 duration;
        // total amount of tokens to be released at the end of the vesting;
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
    }

    /**
     * @notice List of vesting schedules for each beneficiary
     */
    mapping(address => VestingSchedule[]) public vestingSchedules;

    /**
     * @notice Emitted when a vesting schedule is created
     * @param beneficiary The address of the beneficiary
     * @param start The start UNIX timestamp of the vesting period
     * @param duration The duration of the vesting period in months
     */
    event VestingScheduleCreated(
        address indexed beneficiary, uint256 start, uint256 duration, uint256 amountTotal
    );

    /**
     * @notice Emitted when tokens are released
     * @param beneficiary The address of the beneficiary
     * @param amount The amount of tokens released
     */
    event TokensReleased(address indexed beneficiary, uint256 amount);

    /**
     * @param _token The token to be vested
     */
    constructor(IERC20 _token) {
        token = _token;
    }

    /**
     * @notice Creates a vesting schedule
     * @param _beneficiary The address of the beneficiary
     * @param _start The start UNIX timestamp of the vesting period
     * @param _duration The duration of the vesting period in months
     * @param _amountTotal The total amount of tokens to be vested
     * @dev Approve the contract to transfer the tokens before calling this function
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _start,
        uint256 _duration,
        uint256 _amountTotal
) 
external 
{
        // perform input checks
        require(_beneficiary != address(0), "ROOTVesting: beneficiary is the zero address");
        require(_amountTotal > 0, "ROOTVesting: amount is 0");

        // transfer the tokens to be locked to the contract
        token.safeTransferFrom(msg.sender, address(this), _amountTotal);

        // create the vesting schedule and add it to the list of schedules for the beneficiary
        vestingSchedules[_beneficiary].push(
            VestingSchedule({
                beneficiary: _beneficiary,
                start: _start,
                duration: _duration,
                amountTotal: _amountTotal,
                released: 0
            })
        );

        emit VestingScheduleCreated(_beneficiary, _start, _duration, _amountTotal);
    }

    /**
     * @notice Releases the vested tokens for a beneficiary
     * @param _beneficiary The address of the beneficiary
     */
    function release(address _beneficiary) external {
        VestingSchedule[] storage schedules = vestingSchedules[_beneficiary];
        uint256 schedulesLength = schedules.length;
        require(schedulesLength > 0, "ROOTVesting: no vesting schedules for beneficiary");

        uint256 totalRelease;

        for (uint256 i = 0; i < schedulesLength; i++) {
            VestingSchedule storage schedule = schedules[i];

            // calculate the releasable amount
            uint256 amountToSend = releasableAmount(schedule);
            if (amountToSend > 0) {
                // update the released amount
                schedule.released += amountToSend;
                // update the total released amount
                totalRelease += amountToSend;
                // transfer the tokens to the beneficiary
                token.safeTransfer(schedule.beneficiary, amountToSend);
            }
        }

        emit TokensReleased(_beneficiary, totalRelease);
    }

    /**
     * @notice Returns the releasable amount of tokens for a beneficiary
     * @param _beneficiary The address of the beneficiary
     */
    function getReleaseableAmount(address _beneficiary) external view returns (uint256) {
        VestingSchedule[] memory schedules = vestingSchedules[_beneficiary];
        if (schedules.length == 0) return 0;

        uint256 amountToSend = 0;
        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule memory schedule = vestingSchedules[_beneficiary][i];
            amountToSend += releasableAmount(schedule);
        }
        return amountToSend;
    }

    /**
     * @notice Returns the releasable amount of tokens for a vesting schedule
     * @param _schedule The vesting schedule
     */
    function releasableAmount(VestingSchedule memory _schedule) public view returns (uint256) {
        return vestedAmount(_schedule) - _schedule.released;
    }

    /**
     * @notice Returns the vested amount of tokens for a vesting schedule
     * @param _schedule The vesting schedule
     */
    function vestedAmount(VestingSchedule memory _schedule) public view returns (uint256) {
        if (_schedule.duration == 0) {
            if (block.timestamp >= _schedule.start) {
                return _schedule.amountTotal;
            } else {
                return 0;
            }
        }
        uint256 sliceInSeconds = 30 days;
        
        if (block.timestamp < _schedule.start) {
            return 0;
        } else if (block.timestamp >= _schedule.start + _schedule.duration * sliceInSeconds) {
            return _schedule.amountTotal;
        } else {
            uint256 monthsPassed = (block.timestamp - _schedule.start) / sliceInSeconds;
            return (_schedule.amountTotal * monthsPassed) / _schedule.duration;
        }
    }
}