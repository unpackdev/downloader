// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./Initializable.sol";
import "./Errors.sol";

/**
 * @dev Describe a request to create a vesting schedule for an account.
 */
struct VestingScheduleRequest {
    // the total amount to be released
    uint256 allocation;
    // the amount available immediately after the cliff
    uint256 cliffRelease;
    // cliff datetime
    uint256 cliffTimestamp;
    // number of periods of release after the cliff
    // (allocation - cliffRelease) will be released in even tranches over these periods
    uint256 periodsOfRelease;
    // length of a post-cliff release period, in seconds
    uint256 periodLength;
}

/**
 * @dev In-storage representation of a vesting schedule's state.
 */
struct VestingSchedule {
    uint256 allocation;
    uint256 cliffRelease;
    uint256 cliffTimestamp;
    uint256 periodsOfRelease;
    uint256 periodLength;
    // the total claimed by the account
    uint256 claimed;
}

contract VestingWallet is Initializable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Emitted when a vesting schedule is successfully created. Duplicates
     *   the request in full for audit purposes.
     */
    event VestingScheduleCreated(address indexed account, VestingScheduleRequest indexed vs);

    /**
     * @dev Emitted when tokens are claimed by an account.
     */
    event VestedTokensClaimed(address indexed account, uint256 indexed amount);

    // the amount of $CAFE locked in all VestingSchedules
    uint256 public totalAllocated;

    // the total amount claimed from all VestingSchedules
    uint256 public totalClaimed;

    // Map account => VestingSchedule
    mapping(address => VestingSchedule) public schedules;

    // The $CAFE contract
    IERC20Upgradeable public cafeToken;

    /* ========== INITIALIZER ========== */

    function initialize(address cafeToken_) external initializer {
        if (!cafeToken_.isContract())
            revert ContractAddressExpected(cafeToken_);

        __Ownable_init();

        cafeToken = IERC20Upgradeable(cafeToken_);
    }

    /* ========== MUTATORS ========== */

    /**
     * @dev Set up vesting for an account. Emit {VestingScheduleCreated} on success.
     *
     * @param account A non-zero beneficiary address.
     * @param vs Vesting schedule parameters. (See VestingScheduleRequest)
     *
     * Requirements:
     * - `account` must be a non-zero address
     * - no previous schedule must exist for `account` (reverts with `VSExistsForAccount`)
     * - `vs.cliffTimestamp` must exceed block.timestamp (reverts with `VSInvalidCliff`)
     * - `vs.allocation` must be above zero (reverts with `ZeroAmount`)
     * - `vs.allocation` must not be below `vs.cliffRelease` (reverts with `VSInvalidAllocation`)
     * - `vs.periodsOfRelease` and `vs.PeriodLength` must both be either zero or non-zero; otherwise,
     *   the period specification is considered invalid (reverts with `VSInvalidPeriodSpec`)
     * - If `vs.periodsOfRelease` is 0, `vs.cliffRelease` must equal `vs.allocation` (reverts with `VSCliffNERelease`)
     * - The $CAFE balance of the contract cannot be lower than `vs.allocation` plus $CAFE owed
     *   throughout existing vesting schedules (reverts with `InsufficientCAFE`).
     */
    function create(address account, VestingScheduleRequest calldata vs)
        external
    {
        _onlyOwner();

        if (account == address(0)) revert ZeroAddress();

        _vsValid(account, vs);

        schedules[account] = VestingSchedule(
            vs.allocation,
            vs.cliffRelease,
            vs.cliffTimestamp,
            vs.periodsOfRelease,
            vs.periodLength,
            0
        );

        totalAllocated += vs.allocation;

        emit VestingScheduleCreated(account, vs);
    }

    /**
     * @dev Claim all vested $CAFE. Uses claimable() to calculate the vested amount.
     *    Emits `VestedTokensClaimed` on success.
     *
     * Requirements:
     * - A vesting schedule must exist for `msg.sender`
     * - The cliff datetime must be reached
     */
    function claim() external {
        _vsExists(msg.sender);
        _vsCliffReached(msg.sender);

        uint256 amount = claimable();

        if (amount == 0) revert NothingVested();

        totalClaimed += amount;
        schedules[msg.sender].claimed += amount;

        emit VestedTokensClaimed(msg.sender, amount);
        cafeToken.safeTransfer(msg.sender, amount);
    }

    /* ========== VIEWS ========== */

    /**
     * @dev Calculate claimable $CAFE.
     *
     * Requirements: A vesting schedule must exist for `msg.sender`.
     */
    function claimable() public view returns (uint256) {
        _vsExists(msg.sender);

        VestingSchedule storage vs = schedules[msg.sender];

        uint256 now_ = block.timestamp;
        bool single = vs.periodLength == 0;

        if (now_ < vs.cliffTimestamp) {
            return 0;
        } else if (single || now_ < vs.cliffTimestamp + vs.periodLength) {
            return vs.cliffRelease - vs.claimed;
        } else {
            uint256 fullPeriods = ((now_ - vs.cliffTimestamp) /
                vs.periodLength);
            uint256 vested = (fullPeriods * (vs.allocation - vs.cliffRelease)) /
                vs.periodsOfRelease;
            return vs.cliffRelease + vested - vs.claimed;
        }
    }

    /* ========== INTERNALS/MODIFIERS ========== */

    function _vsValid(address account, VestingScheduleRequest calldata vs)
        internal
        view
    {
        if (schedules[account].cliffTimestamp > 0)
            revert VSExistsForAccount(account);

        if (vs.cliffTimestamp <= block.timestamp) revert VSInvalidCliff();

        if (vs.allocation == 0) revert ZeroAmount();

        if (vs.allocation < vs.cliffRelease) revert VSInvalidAllocation();

        uint256 owed = totalAllocated - totalClaimed;
        if (vs.allocation + owed > cafeToken.balanceOf(address(this)))
            revert InsufficientCAFE();

        if (
            (vs.periodsOfRelease == 0 && vs.periodLength != 0) ||
            (vs.periodsOfRelease != 0 && vs.periodLength == 0)
        ) revert VSInvalidPeriodSpec();

        if ((vs.periodsOfRelease == 0) && (vs.cliffRelease != vs.allocation))
            revert VSCliffNERelease();
    }

    function _vsExists(address account) internal view {
        if (schedules[account].cliffTimestamp == 0) revert VSMissing(account);
    }

    function _vsCliffReached(address account) internal view {
        if (block.timestamp < schedules[account].cliffTimestamp)
            revert VSCliffNotReached();
    }

    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert Unauthorized();
    }
}
