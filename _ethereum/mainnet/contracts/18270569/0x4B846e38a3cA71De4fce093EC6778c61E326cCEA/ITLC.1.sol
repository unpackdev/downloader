//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

import "./IERC20Upgradeable.sol";
import "./IVotesUpgradeable.sol";

import "./IERC20VestableVotesUpgradeable.1.sol";

/// @title TLC Interface (v1)
/// @author Alluvial
/// @notice TLC token interface
interface ITLCV1 is IERC20VestableVotesUpgradeableV1, IVotesUpgradeable, IERC20Upgradeable {
    /// @notice Initializes the TLC Token
    /// @param _account The initial account to grant all the minted tokens
    function initTLCV1(address _account) external;

    /// @notice Migrates the vesting schedule state structures
    function migrateVestingSchedules() external;
}
