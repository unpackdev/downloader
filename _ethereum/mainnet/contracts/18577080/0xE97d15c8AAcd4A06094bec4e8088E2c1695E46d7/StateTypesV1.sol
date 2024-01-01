// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

/**************************************

    security-contact:
    - security@angelblock.io

    maintainers:
    - marcin@angelblock.io
    - piotr@angelblock.io
    - mikolaj@angelblock.io
    - sebastian@angelblock.io

    contributors:
    - domenico@angelblock.io

**************************************/

import "./BaseTypesV1.sol";

/// @notice Library that defines state related data.
library StateTypesV1 {
    // -----------------------------------------------------------------------
    //                              Structs
    // -----------------------------------------------------------------------

    /// @dev Struct containing info about project state and investment data.
    /// @param raised Amount of raised base asset for fundraising
    /// @param invested Mapping that stores how much given address invested
    /// @param investmentRefunded Mapping that tracks if user was refunded
    /// @param collateralRefunded Boolean describing if startup was refunded
    /// @param reclaimed Boolean that shows if startup reclaimed unsold tokens
    struct ProjectInvestInfo {
        uint256 raised;
        mapping(address => uint256) invested;
        mapping(address => bool) investmentRefunded;
        bool collateralRefunded;
        bool reclaimed;
    }

    /// @dev Struct containing milestones and share data.
    /// @param milestones Ordered list of unlocked milestones containing all their details
    /// @param unlockedShares Sum of shares from all submitted milestones
    /// @param rejectedShares Amount of shares reverted back due to failed repair plan
    /// @param totalShares Sum of all unlocked and rejected shares (should not exceed 100%)
    struct ShareInfo {
        BaseTypesV1.Milestone[] milestones;
        uint256 unlockedShares;
        uint256 rejectedShares;
        uint256 totalShares;
    }

    /// @dev Struct containing frequently used storage for claiming purposes.
    /// @param investorClaimed Mapping that stores amount claimed of each investor
    /// @param startupClaimed Amount of claimed assets by startup owner
    struct ClaimingInfo {
        mapping(address => uint256) investorClaimed;
        uint256 startupClaimed;
    }
}
