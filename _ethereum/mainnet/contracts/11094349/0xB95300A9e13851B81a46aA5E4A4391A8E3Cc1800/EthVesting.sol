pragma solidity ^0.6.0;

import "./SafeMath.sol";

/**
 * @title EthVesting
 * @dev A eth holder contract that can release its eth balance gradually like a
 * typical vesting scheme, with a cliff and vesting period.
 */
contract EthVesting {
    // The vesting schedule is time-based (i.e. using block timestamps as opposed to e.g. block numbers), and is
    // therefore sensitive to timestamp manipulation (which is something miners can do, to a certain degree). Therefore,
    // it is recommended to avoid using short time durations (less than a minute). Typical vesting schemes, with a
    // cliff period of a year and a duration of four years, are safe to use.
    // solhint-disable not-rely-on-time

    using SafeMath for uint256;

    event EthReleased(uint256 amount);
    event EthReleasedBackup(uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    // beneficiary of tokens after they are released
    address payable private _beneficiary;
    address payable private _backupBeneficiary;

    // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
    uint256 private _cliff;
    uint256 private _start;
    uint256 private _duration;
    uint256 private _backupReleaseGracePeriod;

    uint256 private _released;

    /**
     * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
     * beneficiary, gradually in a linear fashion until start + duration. By then all
     * of the balance will have vested.
     * @param beneficiary address of the beneficiary to whom vested tokens are transferred
     * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
     * @param start the time (as Unix time) at which point vesting starts
     * @param duration duration in seconds of the period in which the tokens will vest
     * @param backupReleaseGracePeriod the period after the duration in completed before the backup beneficiary can withdraw
     */
    constructor (address payable beneficiary, address payable backupBeneficiary, uint256 start, uint256 cliffDuration, uint256 duration, uint256 backupReleaseGracePeriod) public {
        require(beneficiary != address(0), "EthVesting: beneficiary is the zero address");
        // solhint-disable-next-line max-line-length
        require(cliffDuration <= duration, "EthVesting: cliff is longer than duration");
        require(duration > 0, "EthVesting: duration is 0");
        // solhint-disable-next-line max-line-length
        require(start.add(duration) > block.timestamp, "EthVesting: final time is before current time");

        _beneficiary = beneficiary;
        _backupBeneficiary = backupBeneficiary;
        _duration = duration;
        _cliff = start.add(cliffDuration);
        _start = start;
        _backupReleaseGracePeriod = backupReleaseGracePeriod;
    }

    /**
     * @return the beneficiary of the ether.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the backup beneficiary of the ether.
     */
    function backupBeneficiary() public view returns (address) {
        return _backupBeneficiary;
    }

    /**
     * @return the period after the duration in completed before the backup beneficiary can withdraw.
     */
    function backupReleaseGracePeriod() public view returns (uint256) {
        return _backupReleaseGracePeriod;
    }

    /**
     * @return the cliff time of the eth vesting.
     */
    function cliff() public view returns (uint256) {
        return _cliff;
    }

    /**
     * @return the start time of the eth vesting.
     */
    function start() public view returns (uint256) {
        return _start;
    }

    /**
     * @return the duration of the eth vesting.
     */
    function duration() public view returns (uint256) {
        return _duration;
    }

    /**
     * @return the amount of the token released.
     */
    function released() public view returns (uint256) {
        return _released;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     */
    function release() public {
        uint256 unreleased = _releasableAmount();

        require(unreleased > 0, "EthVesting: no eth is due");

        _released = _released.add(unreleased);

        _beneficiary.transfer(unreleased);

        emit EthReleased(unreleased);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     */
    function _releasableAmount() private view returns (uint256) {
        return _vestedAmount().sub(_released);
    }

    /**
     * @dev Calculates the amount that has already vested.
     */
    function _vestedAmount() private view returns (uint256) {
        uint256 currentBalance = address(this).balance;
        uint256 totalBalance = currentBalance.add(_released);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration)) {
            return totalBalance;
        } else {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        }
    }

    /**
     * @dev After the vesting period is complete, allows for withdrawal by backup beneficiary if funds are unclaimed after the post-duration grace period
     */
    function backupRelease() public {
        require(block.timestamp >= _start.add(_duration).add(_backupReleaseGracePeriod));
        _backupBeneficiary.transfer(address(this).balance);

        emit EthReleasedBackup(address(this).balance);
    }

    // Allow Recieve Ether
    receive () external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }
}