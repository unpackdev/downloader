// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title TimeOracle
/// @author Civilization
/// @notice This contract is used to track periods of time based on a given epoch duration
/// @dev The owner of the contract can change the epoch duration
contract TimeOracle {
    address public owner; // Owner of the contract
    uint public startTime; // Start time of the tracking
    uint public epochDuration; // Duration of each period in seconds
    uint public currentPeriod; // Current periods elapsed from the start

    /// @notice Initializes the contract with a given epoch duration
    /// @param _epochDuration Duration of each period in seconds
    constructor(uint _epochDuration) {
        owner = msg.sender; // Set the deployer as the owner
        startTime = block.timestamp; // Initialization at deployment time
        epochDuration = _epochDuration;
    }

    /// @notice Calculates the start time for current period
    /// @return currentPeriodStartTime The start time for the current period
    function getCurrentPeriod()
        external
        view
        returns (uint currentPeriodStartTime)
    {
        require(
            block.timestamp >= startTime,
            "TimeOracle: Query before start time"
        );

        // Calculate how many periods have passed since the start
        uint period = (block.timestamp - startTime) /
            epochDuration;

        // Calculate the start time for the current period
        currentPeriodStartTime = startTime + period * epochDuration;

        return currentPeriodStartTime;
    }

    /// @notice Allows the owner to set a new epoch duration
    /// @param _newEpochDuration The new epoch duration in seconds
    function setEpochDuration(uint _newEpochDuration) external {
        require(
            msg.sender == owner,
            "TimeOracle: Only owner can change epochDuration"
        );

        // Calculate the current period before changing epochDuration
        currentPeriod += (block.timestamp - startTime) / epochDuration;

        // Update startTime to now
        startTime = block.timestamp;

        // Update epochDuration
        epochDuration = _newEpochDuration;
    }
}
