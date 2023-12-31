// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "Ownable.sol";
import "ERC20.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "SafeMath.sol";
import "ReentrancyGuard.sol";

/**
 * Vesting Manager core functionality based on standard Myceleium 
 (formerly Tracer DAO) vesting contract. Source code 
 available at: https://github.com/tracer-protocol/vesting/blob/master/contracts/Vesting.sol.

 Vesting Manager can vest multiple tokens.
 An address can have multiple vesting schedules for multiple assets. 
 */

contract VestingManager is Ownable {
    /* ========== State Variables ========== */

    address payable immutable TREASURY =
        payable(0xf950a86013bAA227009771181a885E369e158da3);

    /* ========== Structs ========== */

    /**
     * @dev Represents a vesting schedule for an account.
     *
     * @param totalAmount Total amount of tokens that will be vested.
     * @param claimedAmount Amount of tokens that have already been claimed.
     * @param startTime Unix timestamp for the start of the vesting schedule.
     * @param cliffTime The timestamp at which the cliff period ends. No tokens can be claimed before the cliff.
     * @param endTime The timestamp at which the vesting schedule ends. All tokens can be claimed after endTime.
     * @param isFixed Flag indicating if the vesting schedule is fixed or can be modified.
     * @param asset The address of the token being vested.
     */
    struct Schedule {
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 cliffTime;
        uint256 endTime;
        bool isFixed;
        address asset;
    }

    /**
     * @dev Represents a summary of a vesting schedule.
     *
     * @param id Unique identifier for the vesting schedule.
     * @param cliffTime The timestamp at which the cliff period ends. No tokens can be claimed before the cliff.
     * @param endTime The timestamp at which the vesting schedule ends. All tokens can be claimed after endTime.
     
     */
    struct ScheduleInfo {
        uint256 id;
        uint256 startTime;
        uint256 cliffTime;
        uint256 endTime;
        uint256 claimedAmount;
        uint256 totalAmount;
        address asset;
    }

    /**
     * @dev Struct to represent amount of vested tokens claimable for a vesting schedule
     * @param scheduleID ID of vesting schedule
     * @param claimableTokens number of vesting tokens claimable as of the current time
     */
    struct ClaimableInfo {
        uint256 scheduleID;
        uint256 claimableTokens;
    }

    /**
     * @dev Struct to represent amount of vested tokens claimable for a vesting schedule
     * @param scheduleID ID of vesting schedule
     * @param claimableTokens number of vesting tokens claimable as of the current time
     */
    struct TokenClaimInfo {
        address asset;
        uint256 scheduleID;
        uint256 claimedAmount;
    }

    /* ========== Mappings ========== */

    // Maps a user address to a schedule ID, which can be used to identify a vesting schedule
    mapping(address => mapping(uint256 => Schedule)) public schedules;

    // Maps a user address to number of schedules created for the account
    mapping(address => uint256) public numberOfSchedules;

    //Provides number of total tokens locked for a specific asset
    mapping(address => uint256) public locked;

    //Maps an address to token claim information associated with a specific address
    mapping(address => TokenClaimInfo[]) public tokenClaimInfo;

    /* ========== Events ========== */

    event vestingClaim(
        uint256 scheduleID,
        address indexed claimer,
        uint256 tokenAmountClaimed,
        uint256 tokensClaimedToDate
    );
    event vestingCancelled(uint256 scheduleID, address account);

    event VestingScheduleCreated(
        address indexed account,
        uint256 indexed currentNumSchedules,
        uint256 amount,
        uint256 startTime,
        uint256 cliffTime,
        uint256 vestingTime,
        bool isFixed,
        address indexed asset
    );

    event processLog(string description, uint256 number);

    /* ========== Constructor ========== */
    // Owner will be set to VestingExecutor contract
    constructor(address initialOwner) {
        transferOwnership(initialOwner);
    }

    /* ========== Views ========== */

    /**
     * @notice Fetches locked amount of a specific asset.
     * @param _assetAddress The address of the asset.
     * @return The amount of the asset currently locked.
     */
    function getLockedAmount(
        address _assetAddress
    ) public view returns (uint256) {
        return locked[_assetAddress];
    }

    /**
     * @notice Returns information about all vesting schedules for a given account
     * @param account The address of the account for which to return vesting schedule information
     * @return An array of ScheduleInfo structs, each containing the ID, cliff timestamp, and end timestamp for a vesting schedule (related to the account)
     */
    function getScheduleInfo(
        address account
    ) public view returns (ScheduleInfo[] memory) {
        uint256 count = numberOfSchedules[account];
        ScheduleInfo[] memory scheduleInfoList = new ScheduleInfo[](count);
        for (uint256 i = 0; i < count; i++) {
            scheduleInfoList[i] = ScheduleInfo(
                i,
                schedules[account][i].startTime,
                schedules[account][i].cliffTime,
                schedules[account][i].endTime,
                schedules[account][i].claimedAmount,
                schedules[account][i].totalAmount,
                schedules[account][i].asset
            );
        }
        return scheduleInfoList;
    }

    /**
     * @notice Retrieves the number of claimable tokens per vesting schedule for a given account
     * @dev This function utilizes the calcVestingDistribution function to determine claimable tokens based on the current block timestamp
     * @param account The address of the account to retrieve claimable tokens for
     * @return An array of structs, each containing the scheduleID and the corresponding number of claimable tokens
     */
    function retrieveClaimableTokens(
        address account
    ) public view returns (ClaimableInfo[] memory) {
        ScheduleInfo[] memory scheduleInfoList = getScheduleInfo(account);

        ClaimableInfo[] memory claimableInfoList = new ClaimableInfo[](
            scheduleInfoList.length
        );

        for (uint256 i = 0; i < scheduleInfoList.length; i++) {
            uint256 claimableTokens = calcVestingDistribution(
                scheduleInfoList[i].totalAmount,
                block.timestamp,
                scheduleInfoList[i].startTime,
                scheduleInfoList[i].endTime
            );

            // Cap the claimable tokens to the total amount allocated for vesting
            claimableTokens = claimableTokens > scheduleInfoList[i].totalAmount
                ? scheduleInfoList[i].totalAmount
                : claimableTokens;

            // Adjust the amount based on the amount the user has claimed
            uint256 claimableAmount = claimableTokens >
                scheduleInfoList[i].claimedAmount
                ? claimableTokens - scheduleInfoList[i].claimedAmount
                : 0;

            claimableInfoList[i] = ClaimableInfo(i, claimableAmount);
        }

        return claimableInfoList;
    }

    /**
     * @notice Internal function to record vestor's claiming activity.
     * @param _vestor The address of the vestor.
     * @param _asset The address of the vesting asset.
     * @param _scheduleID The ID of the vesting schedule.
     * @param _claimedAmount The total amount claimed.
     */
    function _setTotalClaimedData(
        address _vestor,
        address _asset,
        uint256 _scheduleID,
        uint256 _claimedAmount
    ) internal {
        tokenClaimInfo[_vestor].push(
            TokenClaimInfo(_asset, _scheduleID, _claimedAmount)
        );
    }

    /**
     * @notice Retrieves token claim data for a vestor address.
     * @param _address The vestor address for which to retrieve the token claim data.
     * @return An array of TokenClaimInfo containing token claim data for the.
     */
    function getTokenClaimData(
        address _address
    ) public view returns (TokenClaimInfo[] memory) {
        return tokenClaimInfo[_address];
    }

    /* ========== Vesting Functions ========== */

    /**
     * @notice Sets up a vesting schedule for a set user.
     * @dev Adds a new Schedule to the schedules mapping.
     * @param account The account that a vesting schedule is being set up for. Account will be able to claim tokens post-cliff period
     * @param amount The amount of ERC20 tokens being vested for the user.
     * @param asset The ERC20 asset being vested
     * @param isFixed If true, the vesting schedule cannot be cancelled
     * @param cliffWeeks Important parameter that determines how long the vesting cliff will be. During a cliff, no tokens can be claimed and vesting is paused
     * @param vestingWeeks The number of weeks a token will be vested over (linear in this immplementation)
     * @param startTime The start time for the vesting period ( in UNIX)
     */
    function vest(
        address account,
        uint256 amount,
        address asset,
        bool isFixed,
        uint256 cliffWeeks,
        uint256 vestingWeeks,
        uint256 startTime
    ) public onlyOwner {
        // ensure cliff is shorter than vesting (vesting includes the cliff duration)
        require(
            vestingWeeks > 0 && vestingWeeks >= cliffWeeks && amount > 0,
            "Vesting: invalid vesting params set"
        );

        uint256 currentLocked = locked[asset];

        // require enough unlocked token is present to vest the desired amount
        require(
            IERC20(asset).balanceOf(address(this)) >= currentLocked + amount,
            "Vesting: Not enough unlocked supply available to to vest"
        );

        // create the schedule
        uint256 currentNumSchedules = numberOfSchedules[account];
        schedules[account][currentNumSchedules] = Schedule(
            amount,
            0,
            startTime,
            startTime + (cliffWeeks * 1 weeks),
            startTime + (vestingWeeks * 1 weeks),
            isFixed,
            asset
        );

        numberOfSchedules[account] = currentNumSchedules + 1; //Update number of schedules
        locked[asset] = currentLocked + amount; //Update amount of asset locked in vesting schedule

        emit VestingScheduleCreated(
            account,
            currentNumSchedules,
            amount,
            startTime,
            startTime + (cliffWeeks * 1 weeks),
            startTime + (vestingWeeks * 1 weeks),
            isFixed,
            asset
        );
    }

    /**
     * @notice Post-cliff period, users can claim their tokens
     * @param scheduleNumber which schedule the user is claiming against
     */
    function claim(
        uint256 scheduleNumber,
        address vestor,
        address asset
    ) external onlyOwner {
        Schedule storage schedule = schedules[vestor][scheduleNumber];
        require(
            schedule.cliffTime <= block.timestamp,
            "Vesting: cliff not reached"
        );
        require(schedule.totalAmount > 0, "Vesting: Token not claimable");

        // Get the amount to be distributed
        uint256 amount = calcVestingDistribution(
            schedule.totalAmount,
            block.timestamp,
            schedule.startTime,
            schedule.endTime
        );

        // Caps the claim amount to the total amount allocated to be vested to the address
        amount = amount > schedule.totalAmount ? schedule.totalAmount : amount;
        uint256 amountToTransfer = amount - schedule.claimedAmount;
        schedule.claimedAmount = amount; // set new claimed amount based off the curve
        locked[schedule.asset] = locked[schedule.asset] - amountToTransfer;

        _setTotalClaimedData(vestor, asset, scheduleNumber, amount);

        require(
            IERC20(schedule.asset).transfer(vestor, amountToTransfer),
            "Vesting: transfer failed"
        );

        emit vestingClaim(scheduleNumber, vestor, amountToTransfer, amount);
    }

    /**
     * @notice Allows an individual vesting schedule to be cancelled.
     * @dev Any outstanding tokens are returned to the system.
     * @param account the account of the user whos vesting schedule is being cancelled.
     * @param scheduleId the schedule ID of the vesting schedule being cancelled
     */
    function cancelVesting(
        address account,
        uint256 scheduleId
    ) external onlyOwner {
        Schedule storage schedule = schedules[account][scheduleId];
        require(!schedule.isFixed, "Vesting: Account is fixed");
        uint256 outstandingAmount = schedule.totalAmount -
            schedule.claimedAmount;
        require(outstandingAmount != 0, "Vesting: no outstanding tokens");
        schedule.totalAmount = 0;
        locked[schedule.asset] = locked[schedule.asset] - outstandingAmount;
        require(
            IERC20(schedule.asset).transfer(TREASURY, outstandingAmount),
            "Vesting: transfer failed"
        );
        emit vestingCancelled(scheduleId, account);
    }

    /**
     * @return calculates the amount of tokens to distribute to an account at any instance in time, based off some
     *         total claimable amount.
     * @param amount the total outstanding amount to be claimed for this vesting schedule.
     * @param currentTime the current timestamp.
     * @param startTime the timestamp this vesting schedule started.
     * @param endTime the timestamp this vesting schedule ends.
     */
    function calcVestingDistribution(
        uint256 amount,
        uint256 currentTime,
        uint256 startTime,
        uint256 endTime
    ) public pure returns (uint256) {
        // avoid uint underflow
        if (currentTime < startTime) {
            return 0;
        }

        // if endTime < startTime, this will throw. Since endTime should never be
        // less than startTime in safe operation, this is fine.
        return (amount * (currentTime - startTime)) / (endTime - startTime);
    }

    /**
     * @notice Withdraws vesting tokens from the contract.
     * @dev blocks withdrawing locked tokens.
     */
    function withdrawVestingTokens(
        uint256 amount,
        address asset
    ) external onlyOwner {
        IERC20 token = IERC20(asset);
        require(
            token.balanceOf(address(this)) - locked[asset] >= amount,
            "Vesting: Can't withdraw"
        );
        require(token.transfer(owner(), amount), "Vesting: withdraw failed");
    }

    //End of contract
}
