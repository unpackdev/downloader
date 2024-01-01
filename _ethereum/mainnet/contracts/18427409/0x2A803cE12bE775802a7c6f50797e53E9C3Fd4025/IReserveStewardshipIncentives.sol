// SPDX-License-Identifier: LicenseRef-Gyro-1.0
// for information on licensing please see the README in the GitHub repository <https://github.com/gyrostable/core-protocol>.
pragma solidity ^0.8.0;

import "DataTypes.sol";

/// @notice IReserveStewardshipIncentives lets governance set up *incentive initiatives* that reward the governance treasury, in GYD, for continued high reserve ratios and GYD supply.
interface IReserveStewardshipIncentives {
    // TODO stub, to be expanded with view methods etc.

    event InitiativeStarted(uint256 endTime, uint256 minCollateralRatio, uint256 rewardPercentage);
    event InitiativeCanceled();
    event InitiativeCompleted(uint256 startTime, uint256 rewardGYDAmount);

    /// @notice Create new incentive initiative.
    /// @param rewardPercentage Share of the average GYD supply over time that should be paid as a reward. How much *will* actually be paid will also depend on the system state when the incentive is completed.
    function startInitiative(uint256 rewardPercentage) external;

    /// @notice Cancel the active initiative without claming rewards
    function cancelInitiative() external;

    /// @notice Complete the active initiative and claim rewards. Rewards are sent to the governance treasury address.
    /// The initiative period must have passed while the reserve health conditions have held, and they must currently
    /// still hold. Callable by anyone.
    function completeInitiative() external;

    /// @notice Update the internally tracked variables. Called internally but can also be called by anyone.
    function checkpoint() external;

    /// @notice Variant of `checkpoint()` where the reserve state is passed in; only callable by Motherboard.
    function checkpoint(DataTypes.ReserveState memory reserveState) external;

    /// @notice Whether there is an active initiative.
    function hasActiveInitiative() external view returns (bool);

    /// @notice Whether the initiative has already failed. This does *not* include any information based on the current
    /// state that would be included when `checkpoint()` is called. `false` if there is no active initiative.
    function hasFailed() external view returns (bool);

    /// @notice Rewards (in GYD) that the governance treasury would receive if the initiative had ended and
    /// `completeInitiative()` was called now.
    function tentativeRewards() external view returns (uint256 gydAmount);
}
