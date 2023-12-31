// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IStaking {
    /// @notice Stake exceeds stake pool limit
    /// @dev returns amount of tokens remaining before stake limit will be reached
    error ExceedsStakingLimit(uint256 remainingLimit);

    /// @notice Could not withdraw if no tokens were staked
    error NoStake();

    /// @notice Thrown when trying to run function in wrong time
    error InvalidTimePeriod();

    /// @notice Could not deposit if user not participated in presale
    error NotPresaleParticipant();

    /// @notice Could not withdraw if already withdrawn
    error AlreadyWithdrawn();

    event Staked (
        address indexed user,
        uint256 indexed amount,
        uint256 timestamp
    );

    event Withdrawn (
        address indexed user,
        uint256 indexed amount,
        uint256 timestamp
    );
}
