/*
 * Copyright ©️ 2020 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2020 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Adminable.sol";

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 * There are 3 types of vesting schedule: CONTINUOUS, MONTHLY (every 30 days), QUARTERLY (every 90 days).
 */
contract TokenVesting is Adminable {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event ReservedAdded(address indexed beneficiary, uint256 reserved);
    event TokensReleased(address indexed beneficiary, address indexed transferredTo, uint256 amount);
    event TokensWithdrawnByAdmin(address indexed token, uint256 amount);

    // private VestingSchedule time constants
    uint256 private constant MONTHLY_TIME = 30 days;
    uint256 private constant QUARTERLY_TIME = 90 days;

    // TokenVesting name
    string public name;

    // ERC20 token which is being vested
    IERC20 public token;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 public cliff;       // the cliff time of the token vesting
    uint256 public start;       // the start time of the token vesting
    uint256 public duration;    // the duration of the token vesting

    // type of the token vesting
    enum VestingSchedule {CONTINUOUS, MONTHLY, QUARTERLY}
    VestingSchedule public schedule;

    // total reserved tokens for beneficiaries
    uint256 public reserved;

    // reserved tokens to beneficiary
    mapping(address => uint256) public reservedForBeneficiary;

    // total released (transferred) tokens
    uint256 public released;

    // released (transferred) tokens to beneficiary
    mapping(address => uint256) public releasedToBeneficiary;

    // array of beneficiaries for getters
    address[] internal beneficiaries;

    /**
     * @dev Creates a vesting contract that vests its balance of specific ERC20 token to the
     * beneficiaries, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param _token ERC20 token which is being vested
     * @param _cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param _start the time (as Unix time) at which point vesting starts
     * @param _duration duration in seconds of the period in which the tokens will vest
     * @param _schedule type of the token vesting: CONTINUOUS, MONTHLY, QUARTERLY
     * @param _name TokenVesting name
     */
    constructor(
        IERC20 _token,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _duration,
        VestingSchedule _schedule,
        string memory _name
    ) public {
        require(address(_token) != address(0), "TokenVesting: token is the zero address");
        require(_duration > 0, "TokenVesting: duration is 0");

        require(_cliffDuration <= _duration, "TokenVesting: cliff is longer than duration");
        require(_start.add(_duration) > block.timestamp, "TokenVesting: final time is before current time");

        token = _token;
        duration = _duration;
        cliff = _start.add(_cliffDuration);
        start = _start;
        schedule = _schedule;
        name = _name;
    }

    /**
     * @notice Calculates the total amount of vested tokens.
     */
    function totalVested() public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        return currentBalance.add(released);
    }

    /**
     * @notice Calculates the amount that has already vested but hasn't been released yet.
     * @param _beneficiary Address of vested tokens beneficiary
     */
    function releasableAmount(address _beneficiary) public view returns (uint256) {
        return _vestedAmount(_beneficiary).sub(releasedToBeneficiary[_beneficiary]);
    }

    /**
     * @notice Get a beneficiary address with current index.
     */
    function getBeneficiary(uint256 index) public view returns (address) {
        return beneficiaries[index];
    }

    /**
     * @notice Get an array of beneficiary addresses.
     */
    function getBeneficiaries() public view returns (address[] memory) {
        return beneficiaries;
    }

    /**
     * @notice Adds beneficiaries to TokenVesting by admin.
     *
     * Requirements:
     * - can only be called by admin.
     *
     * @param _beneficiaries Addresses of beneficiaries
     * @param _amounts Amounts of tokens reserved for beneficiaries
     */
    function addBeneficiaries(
        address[] memory _beneficiaries,
        uint256[] memory _amounts
    ) external onlyAdmin {
        uint256 len = _beneficiaries.length;
        require(len == _amounts.length, "TokenVesting: Array lengths do not match");

        uint256 amountToBeneficiaries = 0;
        for (uint256 i = 0; i < len; i++) {
            amountToBeneficiaries = amountToBeneficiaries.add(_amounts[i]);

            // add new beneficiary to array
            if (reservedForBeneficiary[_beneficiaries[i]] == 0) {
                beneficiaries.push(_beneficiaries[i]);
            }

            reservedForBeneficiary[_beneficiaries[i]] = reservedForBeneficiary[_beneficiaries[i]].add(_amounts[i]);
            emit ReservedAdded(_beneficiaries[i], _amounts[i]);
        }

        reserved = reserved.add(amountToBeneficiaries);

        // check reserved condition
        require(reserved <= totalVested(), "TokenVesting: reserved exceeds totalVested");
    }

    /**
     * @notice Withdraws ERC20 token funds by admin (except vested token).
     *
     * Requirements:
     * - can only be called by admin.
     *
     * @param _token Token address (except vested token)
     * @param _amount The amount of token to withdraw
     **/
    function withdrawFunds(IERC20 _token, uint256 _amount) external onlyAdmin {
        require(_token != token, "TokenVesting: vested token is not available for withdrawal");
        _token.safeTransfer(msg.sender, _amount);
        emit TokensWithdrawnByAdmin(address(_token), _amount);
    }

    /**
     * @notice Withdraws ERC20 vested token by admin.
     *
     * Requirements:
     * - can only be called by admin.
     *
     * @param _amount The amount of token to withdraw
     **/
    function emergencyWithdraw(uint256 _amount) external onlyAdmin {
        require(block.timestamp < start, "TokenVesting: vesting has already started");
        token.safeTransfer(msg.sender, _amount);
        emit TokensWithdrawnByAdmin(address(token), _amount);
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * @param _beneficiary Address of vested tokens beneficiary
     */
    function release(address _beneficiary) public {
        _release(_beneficiary, _beneficiary);
    }

    /**
     * @notice Transfers vested tokens of sender to specified address.
     * @param _transferTo Address to which tokens are transferred
     */
    function releaseToAddress(address _transferTo) public {
        _release(msg.sender, _transferTo);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param _beneficiary Address of vested tokens beneficiary
     */
    function _vestedAmount(address _beneficiary) private view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start.add(duration)) {
            return reservedForBeneficiary[_beneficiary];
        } else {
            return reservedForBeneficiary[_beneficiary].mul(_vestedPeriod()).div(duration);
        }
    }

    /**
     * @dev Calculates the duration of period that is already unlocked according to VestingSchedule type.
     */
    function _vestedPeriod() private view returns (uint256 period) {
        period = block.timestamp.sub(start);  // CONTINUOUS

        if (schedule == VestingSchedule.MONTHLY) {
            period = period.sub(period % MONTHLY_TIME);
        } else if (schedule == VestingSchedule.QUARTERLY) {
            period = period.sub(period % QUARTERLY_TIME);
        }
    }

    /**
     * @dev Transfers vested tokens.
     * @param _beneficiary Address of vested tokens beneficiary
     * @param _transferTo Address to which tokens are transferred
     */
    function _release(address _beneficiary, address _transferTo) private {
        uint256 unreleased = releasableAmount(_beneficiary);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        releasedToBeneficiary[_beneficiary] = releasedToBeneficiary[_beneficiary].add(unreleased);
        released = released.add(unreleased);

        token.safeTransfer(_transferTo, unreleased);

        emit TokensReleased(_beneficiary, _transferTo, unreleased);
    }
}
