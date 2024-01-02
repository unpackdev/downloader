// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable2Step.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract TokenLock is Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 private immutable _token;

    // vesting schedule structure
    struct VestingSchedule {
        // beneficiary of tokens after they are released
        address beneficiary;
        // total amount of tokens to be vested
        uint256 amount;
        // vesting start timestamp in seconds
        uint256 vestingStart;
        // vesting end timestamp in seconds
        uint256 vestingEnd;
        // cliff timestamp in seconds
        uint256 cliff;
        // slice period for the vesting in seconds
        uint256 slicePeriod;
        // released amount of tokens
        uint256 releasedAmount;
    }

    /* distribution variables */

    // list of vesting schedule ids
    bytes32[] private _vestingScheduleIds;
    mapping(bytes32 => VestingSchedule) private _vestingSchedules;

    uint256 private _lockedTotalAmount;
    mapping(address => uint256) private _beneficiariesyVestingCount;

    /* ========== EVENTS ========== */

    event CreateLock(
        bytes32 indexed vestingScheduleId,
        address indexed beneficiary,
        uint256 amount,
        uint256 vestingStart,
        uint256 vestingEnd,
        uint256 cliff,
        uint256 slicePeriod
    );

    event TokensReleased(
        bytes32 indexed vestingScheduleId,
        address indexed beneficiary,
        uint256 amount
    );

    constructor(address token) {
        _token = IERC20(token);
    }

    /**
     * @notice Create a new vesting schedule for a beneficiary
     *
     * @param _beneficiary address of the beneficiary
     * @param _amount total amount of tokens to be vested
     * @param _vestingStart vesting start timestamp in seconds
     * @param _vestingEnd vesting end timestamp in seconds
     * @param _cliff cliff period in seconds
     */
    function createVestingSchedule(
        address _beneficiary,
        uint256 _amount,
        uint256 _vestingStart,
        uint256 _vestingEnd,
        uint256 _cliff,
        uint256 _slicePeriod
    ) external onlyOwner {
        require(
            _beneficiary != address(0),
            "TokenLock: beneficiary is the zero address"
        );
        require(
            getWithdrawableAmount() >= _amount,
            "TokenLock: not enough tokens to lock"
        );
        require(
            _vestingStart >= block.timestamp,
            "TokenLock: vesting start time is before current time"
        );
        require(
            _vestingEnd > _vestingStart,
            "TokenLock: vesting end time is before start time"
        );
        require(
            _cliff <= _vestingEnd,
            "TokenLock: cliff is longer than vesting period"
        );
        require(_slicePeriod > 0, "TokenLock: slice period must be > 0");

        bytes32 vestingScheduleId = computeNextVestingScheduleId(_beneficiary);

        _vestingSchedules[vestingScheduleId] = VestingSchedule({
            beneficiary: _beneficiary,
            amount: _amount,
            vestingStart: _vestingStart,
            vestingEnd: _vestingEnd,
            slicePeriod: _slicePeriod,
            cliff: _cliff,
            releasedAmount: 0
        });
        _lockedTotalAmount += _amount;
        _vestingScheduleIds.push(vestingScheduleId);
        _beneficiariesyVestingCount[_beneficiary] += 1;

        emit CreateLock(
            vestingScheduleId,
            _beneficiary,
            _amount,
            _vestingStart,
            _vestingEnd,
            _cliff,
            _slicePeriod
        );
    }

    function release(
        bytes32 _vestingScheduleId,
        uint256 _amount
    ) public nonReentrant {
        VestingSchedule storage schedule = _vestingSchedules[
            _vestingScheduleId
        ];
        bool isBeneficiary = msg.sender == schedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "TokenLock: only beneficiary or owner can release tokens"
        );
        uint256 releasableAmount = _computeReleasableAmount(schedule);
        require(
            releasableAmount >= _amount,
            "TokenLock: not enough vested tokens"
        );
        schedule.releasedAmount += _amount;
        _lockedTotalAmount -= _amount;
        _token.safeTransfer(schedule.beneficiary, _amount);

        emit TokensReleased(_vestingScheduleId, schedule.beneficiary, _amount);
    }

    /**
     * @notice Returns the number of vesting schedules associated to a beneficiary.
     * @param _beneficiary address of the beneficiary
     */
    function getVestingSchedulesCountByBeneficiary(
        address _beneficiary
    ) public view returns (uint256) {
        return _beneficiariesyVestingCount[_beneficiary];
    }

    function getVestingScheduleIdAtIndex(
        uint256 index
    ) external view returns (bytes32) {
        require(
            index < _vestingScheduleIds.length,
            "TokenLock: index out of bounds"
        );
        return _vestingScheduleIds[index];
    }

    function getVestingScheduleByAddressAndIndex(
        address _beneficiary,
        uint256 _index
    ) external view returns (VestingSchedule memory) {
        return
            getVestingSchedule(
                computeVestingScheduleIdForAddressAndIndex(_beneficiary, _index)
            );
    }

    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return _lockedTotalAmount;
    }

    function getToken() external view returns (address) {
        return address(_token);
    }

    function getVestingSchedulesCount() public view returns (uint256) {
        return _vestingScheduleIds.length;
    }

    function computeReleasableAmount(
        bytes32 vestingScheduleId
    ) external view returns (uint256) {
        VestingSchedule storage vestingSchedule = _vestingSchedules[
            vestingScheduleId
        ];
        return _computeReleasableAmount(vestingSchedule);
    }

    function getVestingSchedule(
        bytes32 _vestingScheduleId
    ) public view returns (VestingSchedule memory) {
        return _vestingSchedules[_vestingScheduleId];
    }

    /**
     * @notice Get the total amount of tokens that not locked in the contract.
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return _token.balanceOf(address(this)) - _lockedTotalAmount;
    }

    function computeNextVestingScheduleId(
        address _beneficiary
    ) public view returns (bytes32) {
        return
            computeVestingScheduleIdForAddressAndIndex(
                _beneficiary,
                _beneficiariesyVestingCount[_beneficiary]
            );
    }

    function computeVestingScheduleIdForAddressAndIndex(
        address _beneficiary,
        uint256 _index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_beneficiary, _index));
    }

    function _computeReleasableAmount(
        VestingSchedule memory _vestingSchedule
    ) internal view returns (uint256) {
        // retrieve the current timestamp
        uint256 currentTime = block.timestamp;
        // if the current time is before the cliff or start time,
        // no tokens are releasable.
        if (
            currentTime < _vestingSchedule.cliff ||
            currentTime < _vestingSchedule.vestingStart
        ) {
            return 0;
        }
        // if the current time is after the vesting end, all tokens are releasable,
        // minus the amount already released.
        if (currentTime >= _vestingSchedule.vestingEnd) {
            return _vestingSchedule.amount - _vestingSchedule.releasedAmount;
        }
        // otherwise, releasable amount is calculated as a fraction of the total amount,
        // the fraction is determined by the time passed since the vesting start
        // divided by the vesting period.
        uint256 totalVestingPeriod = _vestingSchedule.vestingEnd -
            _vestingSchedule.vestingStart;
        uint256 timeFromStart = currentTime - _vestingSchedule.vestingStart;
        uint256 vestedSeconds = (timeFromStart / _vestingSchedule.slicePeriod) *
            _vestingSchedule.slicePeriod;

        uint256 releasableAmount = (_vestingSchedule.amount * vestedSeconds) /
            totalVestingPeriod;

        return releasableAmount - _vestingSchedule.releasedAmount;
    }
}
