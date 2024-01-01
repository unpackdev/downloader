// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title An interface for the ESASXVesting contract
 * @author Asymetrix Protocol Inc Team
 * @notice An interface that describes data structures and events for the ESASXVesting contract.
 */
interface IESASXVesting {
    /**
     * @notice Vesting Position structure.
     * @param lockPeriod A vesting period of esASX tokens.
     * @param amount An amount of esASX tokens to be vested.
     * @param releasedAmount An amount of ASX tokens has been released.
     * @param createdAt A timestamp when a vesting position created.
     */
    struct VestingPosition {
        uint256 lockPeriod;
        uint256 amount;
        uint256 releasedAmount;
        uint32 createdAt;
    }

    /**
     * @notice Event emitted when a part of ASX tokens from a vesting position was released.
     * @param vpid An ID of a vesting position.
     * @param recipient An address of ASX tokens recipient.
     * @param amount An amount of tokens that were released.
     */
    event Released(uint256 indexed vpid, address indexed recipient, uint256 amount);

    /**
     * @notice Event emitted when a part of ASX tokens from a vesting position was released with penalty.
     * @param vpid An ID of a vesting position.
     * @param recipient An address of ASX tokens recipient.
     * @param received An amount of tokens that were released.
     * @param lost An amount of tokens that were lost by user and put on sale with discount.
     */
    event ReleasedWithPenalty(uint256 indexed vpid, address indexed recipient, uint256 received, uint256 lost);

    /**
     * @notice Event emitted when a part of unused ASX tokens or other tokens (including ETH) was withdrawn by an owner.
     * @param token A token that was withdraw. If token address was equal to zero address - ETH were withdrawn.
     * @param owner An address of an owner that withdrawn unused tokens.
     * @param amount An amount of tokens that were withdrawn.
     */
    event Withdrawn(address indexed token, address indexed owner, uint256 amount);

    /**
     * @notice Event emitted when a vesting position is created.
     * @param positionId Id of the user vesting position.
     * @param user Address of the user.
     * @param vestingPosition Created vesting position.
     */
    event VestingPositionCreated(uint256 positionId, address user, VestingPosition vestingPosition);

    /**
     * @notice Creates a new vesting position.
     * @param user An address of a user for whom vestin position will be created.
     * @param amount An amount of esASX to be vested.
     */
    function createVestingPosition(address user, uint256 amount) external;

    /**
     * @notice Returns an amount of ASX tokens available for withdrawal (unused ASX tokens amount).
     * @return A withdrawable ASX amount.
     */
    function getWithdrawableASXAmount() external view returns (uint256);

    /**
     * @notice Returns the minimum vesting amount any user must set in order to create a vesting position.
     * @return Minimum vesting amount for a vesting position.
     */
    function getMinVestingAmount() external view returns (uint256);
}
