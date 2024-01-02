// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

import "./IERC20.sol";
import "./SafeERC20.sol";

/**
 * @title TokenVesting
 * @notice Vesting contract that allows configuring periodic vesting with start tokens and cliff time.
 */
abstract contract TokenVesting {
    // -----------------------------------------------------------------------
    // Library usage
    // -----------------------------------------------------------------------

    using SafeERC20 for IERC20;

    // -----------------------------------------------------------------------
    // Errors
    // -----------------------------------------------------------------------

    error Error_TokenZeroAddress();
    error Error_InvalidPercents();
    error Error_InvalidRecurrences();
    error Error_NothingToClaim();
    error Error_InvalidTimestamps();

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------

    /**
     * @notice This event is emitted when a user claims vested tokens.
     * @param id The ID of the vesting schedule.
     * @param user The address of the user who claimed the tokens.
     * @param amount The amount of tokens claimed.
     */
    event Claimed(uint256 indexed id, address indexed user, uint256 amount);

    // -----------------------------------------------------------------------
    // Storage variables
    // -----------------------------------------------------------------------

    /**
     * @notice A struct representing the parameters of a vesting schedule.
     * @dev This struct contains the following fields:
     *      - `start`: the timestamp at which the vesting begins
     *      - `cliff`: the duration of the cliff period in seconds
     *      - `end`: the timestamp at which the vesting ends
     *      - `recurrences`: the number of times tokens are released
     *      - `startBPS`: the basis points of tokens released at the start of vesting
     */
    struct VestingSchedule {
        uint40 start;
        uint32 cliff;
        uint40 end;
        uint16 recurrences;
        uint16 startBPS;
    }

    /// @notice Basis points represented in 1/100th of a percent
    uint256 public constant BPS = 10000;
    /// @notice Duration of one month in seconds
    uint256 public constant MONTH = 30 days;

    /// @notice Address of vested token
    IERC20 public immutable vestedToken;

    /// @notice Mapping of vesting schedule for each vesting ID
    mapping(uint256 => VestingSchedule) public vestings;
    /// @notice Mapping of user's total amount of vested tokens for each vesting ID
    mapping(uint256 => mapping(address => uint256)) public vested;
    /// @notice Mapping of user's total amount of claimed tokens for each vesting ID
    mapping(uint256 => mapping(address => uint256)) public claimed;

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------

    /**
     * @notice Creates a new Vesting contract instance for the specified token.
     * @dev The token address must not be the zero address.
     *
     * @param _vestedToken Address of the token to be vested.
     */
    constructor(address _vestedToken) {
        if (_vestedToken == address(0)) {
            revert Error_TokenZeroAddress();
        }

        vestedToken = IERC20(_vestedToken);
    }

    // -----------------------------------------------------------------------
    // User actions
    // -----------------------------------------------------------------------

    /**
     * @notice Claim vested tokens for a given vesting schedule
     * @dev Calculates the amount of claimable tokens for a given user
     *      and vesting schedule and transfers them to the user.
     *      Throws an error if there are no tokens to claim.
     *
     * @param id The ID of the vesting schedule to claim tokens from
     *
     * Requirements:
     * - The caller must have vested tokens from the given vesting schedule.
     * - There must be tokens available to claim.
     *
     * Notes:
     * - The _claimable function return 0 for not exited vesting schedule.
     */
    function claim(uint256 id) external {
        uint256 claimable = _claimable(
            id,
            vested[id][msg.sender],
            claimed[id][msg.sender]
        );

        if (claimable == 0) {
            revert Error_NothingToClaim();
        }

        claimed[id][msg.sender] += claimable;

        emit Claimed(id, msg.sender, claimable);

        vestedToken.safeTransfer(msg.sender, claimable);
    }

    // -----------------------------------------------------------------------
    // Getters
    // -----------------------------------------------------------------------

    /**
     * @notice Calculates the amount of vested tokens claimable by a user for a specific vesting schedule
     *
     * @param id The id of the vesting schedule
     * @param user The address of the user to check for claimable tokens
     *
     * @return The amount of vested tokens claimable by the user
     */
    function getClaimable(
        uint256 id,
        address user
    ) external view returns (uint256) {
        return _claimable(id, vested[id][user], claimed[id][user]);
    }

    // -----------------------------------------------------------------------
    // Internal functions
    // -----------------------------------------------------------------------

    /**
     * @notice Adds a new vesting schedule
     *
     * @param id The id of the vesting schedule
     * @param start The timestamp of the start of the vesting schedule
     * @param cliff The duration in seconds of the cliff in the vesting schedule
     * @param recurrences The number of times tokens will vest after the cliff
     * @param startBPS The percentage of tokens that will vest at the start of the schedule, in basis points
     *
     * Requirements:
     * - The `startBPS` must be less than or equal to BPS
     * - The number of `recurrences` must be greater than 0
     */
    function _addVestingSchedule(
        uint256 id,
        uint40 start,
        uint32 cliff,
        uint16 recurrences,
        uint16 startBPS
    ) internal {
        if (startBPS > BPS) {
            revert Error_InvalidPercents();
        }

        if (recurrences == 0) {
            revert Error_InvalidRecurrences();
        }

        vestings[id] = VestingSchedule(
            start,
            cliff,
            start + cliff + recurrences * uint40(MONTH),
            recurrences,
            startBPS
        );
    }

    /**
     * @dev Calculates the amount of tokens that are currently claimable for a given vesting schedule.
     *
     * @param id The id of the vesting schedule.
     * @param vested_ The total amount of tokens that have been vested for the vesting schedule.
     * @param claimed_ The total amount of tokens that have already been claimed for the vesting schedule.
     *
     * @return claimable The amount of tokens that are currently claimable for the vesting schedule.
     *
     * Notes:
     * - Uses timestamp for comparison, but can't be affected by its manipulation.
     * - Function performs a multiplication on the result of a division, this is expected and safe.
     */
    function _claimable(
        uint256 id,
        uint256 vested_,
        uint256 claimed_
    ) private view returns (uint256 claimable) {
        uint256 timestamp = block.timestamp;

        uint256 startTime = vestings[id].start;
        uint256 cliffTime = startTime + uint256(vestings[id].cliff);
        uint256 endTime = vestings[id].end;
        uint256 startTokens = (vested_ * uint256(vestings[id].startBPS)) / BPS;
        uint256 recurrences = vestings[id].recurrences;

        // not started
        if (startTime > timestamp) return 0;

        if (timestamp <= cliffTime) {
            // we are after start but before cliff time
            // start tokens should be released
            claimable = startTokens;
        } else if (timestamp > cliffTime && timestamp < endTime) {
            // we are somewhere in the middle
            uint256 vestedAmount = vested_ - startTokens;
            uint256 everyRecurrenceReleaseAmount = vestedAmount / recurrences;

            uint256 occurrences = (timestamp - cliffTime) / MONTH;

            uint256 vestingUnlockedAmount = occurrences *
                everyRecurrenceReleaseAmount;

            claimable = vestingUnlockedAmount + startTokens;
        } else {
            // time has passed, we can take all tokens
            claimable = vested_;
        }

        // but maybe we take something earlier?
        claimable -= claimed_;
    }
}
