// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Math.sol";
import "./ITokenLock.sol";

// this contract is based on GraphTokenLock
// see https://github.com/graphprotocol/token-distribution/blob/main/contracts/GraphTokenLock.sol

/**
 * @title TokenLock
 * @notice Contract that manages an unlocking schedule of tokens.
 * The contract lock holds a certain amount of tokens deposited  and insures that
 * they can only be released under certain time conditions.
 *
 * This contract implements a release scheduled based on periods and tokens are released in steps
 * after each period ends. It can be configured with one period in which case it is like a plain TimeLock.
 * The contract also supports revocation to be used for vesting schedules. In case that the contract is configured to be  revocable,
 * the owner can revoke the contract at any time and the unvested tokens will be sent back to the owner, even if the 
 * the beneficiary has accepted the lock.
 *
 * The contract supports receiving extra funds than the managed tokens ones that can be
 * withdrawn by the beneficiary at any time.
 *
 * A releaseStartTime parameter is included to override the default release schedule and
 * perform the first release on the configured time. After that it will continue with the
 * default schedule.
 */
// solhint-disable-next-line indent
abstract contract TokenLock is Ownable, ITokenLock {
    using SafeERC20 for IERC20;

    // -- Errors --

    error OnlyBeneficiary();
    error BeneficiaryCannotBeZero();
    error CannotCancelAfterLockIsAccepted();
    error NoAmountAvailableToRelease();
    error AmountCannotBeZero();
    error AmountRequestedBiggerThanSurplus();
    error LockIsNonRevocable();
    error LockIsAlreadyRevoked();
    error NoAvailableUnvestedAmount();
    error OnlySweeper();
    error CannotSweepVestedToken();
    error AlreadyInitialized();
    error TokenCannotBeZero();
    error ManagedAmountCannotBeZero();
    error StartTimeCannotBeZero();
    error StartTimeMustBeBeforeEndTime();
    error PeriodsCannotBeBelowMinimum();
    error ReleaseStartTimeMustBeBeforeEndTime();
    error CliffTimeMustBeBeforeEndTime();

    uint256 private constant MIN_PERIOD = 1;

    // -- State --

    IERC20 public token;
    address public beneficiary;

    // Configuration

    // Amount of tokens managed by the contract schedule
    uint256 public managedAmount;

    uint256 public startTime; // Start datetime (in unixtimestamp)
    uint256 public endTime; // Datetime after all funds are fully vested/unlocked (in unixtimestamp)
    uint256 public periods; // Number of vesting/release periods

    // First release date for tokens (in unixtimestamp)
    // If set, no tokens will be released before releaseStartTime ignoring
    // the amount to release each period
    uint256 public releaseStartTime;
    // A cliff set a date to which a beneficiary needs to get to vest
    // all preceding periods
    uint256 public vestingCliffTime;
    bool public revocable; // determines whether the owner can revoke all unvested tokens

    // State

    bool public isRevoked;
    bool public isInitialized;
    bool public isAccepted;
    uint256 public releasedAmount;

    // -- Events --

    event TokensReleased(address indexed beneficiary, uint256 amount);
    event TokensWithdrawn(address indexed beneficiary, uint256 amount);
    event TokensRevoked(address indexed beneficiary, uint256 amount);
    event BeneficiaryChanged(address newBeneficiary);
    event LockAccepted();
    event LockCanceled();

    /**
     * @dev Only allow calls from the beneficiary of the contract
     */
    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary) 
            revert OnlyBeneficiary();
        _;
    }

    constructor() {
        endTime = type(uint256).max;
        isInitialized = true;
    }

    /**
     * @notice Change the beneficiary of funds managed by the contract
     * @dev Can only be called by the beneficiary
     * @param _newBeneficiary Address of the new beneficiary address
     */
    function changeBeneficiary(address _newBeneficiary) external onlyBeneficiary {
        if (_newBeneficiary == address(0))
            revert BeneficiaryCannotBeZero();
        beneficiary = _newBeneficiary;
        emit BeneficiaryChanged(_newBeneficiary);
    }

    /**
     * @notice Beneficiary accepts the lock, the owner cannot cancel the lock. But in case that the contract is defined as revocable,
     * the owner can revoke the contract at any time and retrieve all unvested tokens.
     * @dev Can only be called by the beneficiary
     */
    function acceptLock() external onlyBeneficiary {
        isAccepted = true;
        emit LockAccepted();
    }

    /**
     * @notice Owner cancel the lock and return the balance in the contract
     * @dev Can only be called by the owner
     */
    function cancelLock() external onlyOwner {
        if (isAccepted)
            revert CannotCancelAfterLockIsAccepted();

        token.safeTransfer(owner(), currentBalance());

        emit LockCanceled();
    }

    // -- Value Transfer --

    /**
     * @notice Releases tokens based on the configured schedule
     * @dev All available releasable tokens are transferred to beneficiary
     */
    function release() external override onlyBeneficiary {
        uint256 amountToRelease = releasableAmount();
        if (amountToRelease == 0)
            revert NoAmountAvailableToRelease();

        releasedAmount += amountToRelease;

        token.safeTransfer(beneficiary, amountToRelease);

        emit TokensReleased(beneficiary, amountToRelease);

        trySelfDestruct();
    }

    /**
     * @notice Withdraws surplus, unmanaged tokens from the contract
     * @dev Tokens in the contract over outstanding amount are considered as surplus
     * @param _amount Amount of tokens to withdraw
     */
    function withdrawSurplus(uint256 _amount) external override onlyBeneficiary {
        if (_amount == 0)
            revert AmountCannotBeZero();
        if (surplusAmount() < _amount)
        revert AmountRequestedBiggerThanSurplus();

        token.safeTransfer(beneficiary, _amount);

        emit TokensWithdrawn(beneficiary, _amount);

        trySelfDestruct();
    }

    /**
     * @notice Revokes a vesting schedule and return the unvested tokens to the owner
     * @dev Vesting schedule is always calculated based on managed tokens
     */
    function revoke() external override onlyOwner {
        if (!revocable)
            revert LockIsNonRevocable();

        if (isRevoked)
            revert LockIsAlreadyRevoked();

        uint256 vestedAmount = vestedAmount();

        uint256 unvestedAmount = managedAmount - vestedAmount;
        if (unvestedAmount == 0)
            revert NoAvailableUnvestedAmount();

        isRevoked = true;

        managedAmount = vestedAmount;

        // solhint-disable-next-line not-rely-on-time
        endTime = block.timestamp;

        token.safeTransfer(owner(), unvestedAmount);

        emit TokensRevoked(beneficiary, unvestedAmount);

        trySelfDestruct();
    }

    /**
     * @notice Sweeps out accidentally sent tokens
     * @param _token Address of token to sweep
     */
    function sweepToken(IERC20 _token) external override {
        address sweeper = owner() == address(0) ? beneficiary : owner();
        if (msg.sender != sweeper)
            revert OnlySweeper();
        if (_token == token)
            revert CannotSweepVestedToken();
        uint256 tokenBalance = _token.balanceOf(address(this));
        if (tokenBalance > 0) {
            _token.safeTransfer(sweeper, tokenBalance);
        }
    }

    // -- Balances --

    /**
     * @notice Returns the amount of tokens currently held by the contract
     * @return Tokens held in the contract
     */
    function currentBalance() public override view returns (uint256) {
        return token.balanceOf(address(this));
    }

    // -- Time & Periods --

    /**
     * @notice Returns the current block timestamp
     * @return Current block timestamp
     */
    function currentTime() public override view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /**
     * @notice Gets duration of contract from start to end in seconds
     * @return Amount of seconds from contract startTime to endTime
     */
    function duration() public override view returns (uint256) {
        return endTime - startTime;
    }

    /**
     * @notice Gets time elapsed since the start of the contract
     * @dev Returns zero if called before conctract starTime
     * @return Seconds elapsed from contract startTime
     */
    function sinceStartTime() public override view returns (uint256) {
        uint256 current = currentTime();
        if (current <= startTime) {
            return 0;
        }
        return current - startTime;
    }

    /**
     * @notice Returns amount available to be released after each period according to schedule
     * @return Amount of tokens available after each period
     */
    function amountPerPeriod() public override view returns (uint256) {
        return managedAmount / periods;
    }

    /**
     * @notice Returns the duration of each period in seconds
     * @return Duration of each period in seconds
     */
    function periodDuration() public override view returns (uint256) {
        return duration() / periods;
    }

    /**
     * @notice Gets the current period based on the schedule
     * @return A number that represents the current period
     */
    function currentPeriod() public override view returns (uint256) {
        return sinceStartTime() / periodDuration() + MIN_PERIOD;
    }

    /**
     * @notice Gets the number of periods that passed since the first period
     * @return A number of periods that passed since the schedule started
     */
    function passedPeriods() public override view returns (uint256) {
        return currentPeriod() - MIN_PERIOD;
    }

    // -- Locking & Release Schedule --

    /**
     * @notice Gets the currently available token according to the schedule
     * @dev Implements the step-by-step schedule based on periods for available tokens
     * @return Amount of tokens available according to the schedule
     */
    function availableAmount() public override view returns (uint256) {
        uint256 current = currentTime();

        // Before contract start no funds are available
        if (current < startTime) {
            return 0;
        }

        // After contract ended all funds are available
        if (current > endTime) {
            return managedAmount;
        }

        // Get available amount based on period
        return passedPeriods() * amountPerPeriod();
    }

    /**
     * @notice Gets the amount of currently vested tokens
     * @dev Similar to available amount, but is fully vested when contract is non-revocable
     * @return Amount of tokens already vested
     */
    function vestedAmount() public override view returns (uint256) {
        // If non-revocable it is fully vested
        if (!revocable) {
            return managedAmount;
        }

        // Vesting cliff is activated and it has not passed means nothing is vested yet
        if (vestingCliffTime > 0 && currentTime() < vestingCliffTime) {
            return 0;
        }

        return availableAmount();
    }

    /**
     * @notice Gets tokens currently available for release
     * @dev Considers the schedule and takes into account already released tokens
     * @return Amount of tokens ready to be released
     */
    function releasableAmount() public override view returns (uint256) {
        // If a release start time is set no tokens are available for release before this date
        // If not set it follows the default schedule and tokens are available on
        // the first period passed
        if (releaseStartTime > 0 && currentTime() < releaseStartTime) {
            return 0;
        }

        // Vesting cliff is activated and it has not passed means nothing is vested yet
        // so funds cannot be released
        if (revocable && vestingCliffTime > 0 && currentTime() < vestingCliffTime) {
            return 0;
        }

        // A beneficiary can never have more releasable tokens than the contract balance
        uint256 releasable = availableAmount() - releasedAmount;
        return Math.min(currentBalance(), releasable);
    }

    /**
     * @notice Gets the outstanding amount yet to be released based on the whole contract lifetime
     * @dev Does not consider schedule but just global amounts tracked
     * @return Amount of outstanding tokens for the lifetime of the contract
     */
    function totalOutstandingAmount() public override view returns (uint256) {
        return managedAmount - releasedAmount;
    }

    /**
     * @notice Gets surplus amount in the contract based on outstanding amount to release
     * @dev All funds over outstanding amount is considered surplus that can be withdrawn by beneficiary
     * @return Amount of tokens considered as surplus
     */
    function surplusAmount() public override view returns (uint256) {
        uint256 balance = currentBalance();
        uint256 outstandingAmount = totalOutstandingAmount();
        if (balance > outstandingAmount) {
            return balance - outstandingAmount;
        }
        return 0;
    }

    /**
     * @notice Initializes the contract
     * @param _tokenLockOwner Address of the contract owner
     * @param _beneficiary Address of the beneficiary of locked tokens
     * @param _managedAmount Amount of tokens to be managed by the lock contract
     * @param _startTime Start time of the release schedule
     * @param _endTime End time of the release schedule
     * @param _periods Number of periods between start time and end time
     * @param _releaseStartTime Override time for when the releases start
     * @param _vestingCliffTime Override time for when the vesting start
     * @param _revocable Whether the contract is revocable
     */
    function _initialize(
        address _tokenLockOwner,
        address _beneficiary,
        address _token,
        uint256 _managedAmount,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _periods,
        uint256 _releaseStartTime,
        uint256 _vestingCliffTime,
        bool _revocable
    ) internal {
        if (isInitialized)
            revert AlreadyInitialized();
        if (_beneficiary == address(0))
            revert BeneficiaryCannotBeZero();
        if (_token == address(0))
            revert TokenCannotBeZero();
        if (_managedAmount == 0)
            revert ManagedAmountCannotBeZero();
        if (_startTime == 0)
            revert StartTimeCannotBeZero();
        if (_startTime >= _endTime)
            revert StartTimeMustBeBeforeEndTime();
        if (_periods < MIN_PERIOD)
            revert PeriodsCannotBeBelowMinimum();
        if (_releaseStartTime >= _endTime)
            revert ReleaseStartTimeMustBeBeforeEndTime();
        if (_vestingCliffTime >= _endTime)
            revert CliffTimeMustBeBeforeEndTime();

        isInitialized = true;

        _transferOwnership(_tokenLockOwner);
        beneficiary = _beneficiary;
        token = IERC20(_token);

        managedAmount = _managedAmount;

        startTime = _startTime;
        endTime = _endTime;
        periods = _periods;

        // Optionals
        releaseStartTime = _releaseStartTime;
        vestingCliffTime = _vestingCliffTime;
        revocable = _revocable;
    }

    function trySelfDestruct() private {
        if (currentTime() >= endTime && currentBalance() == 0) {
            selfdestruct(payable(msg.sender));
        }
    }
}
