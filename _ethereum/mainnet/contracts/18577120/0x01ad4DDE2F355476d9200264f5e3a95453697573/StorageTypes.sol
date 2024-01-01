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

// Local imports
import "./EnumTypes.sol";

/// @notice Library with core storage structs definition.
library StorageTypes {
    // -----------------------------------------------------------------------
    //                              Raise
    // -----------------------------------------------------------------------

    /// @dev Struct containing main information about the raise.
    /// @param raiseId UUID of raise
    /// @param raiseType Type of raise
    /// @param owner Address of startup
    struct Raise {
        string raiseId;
        EnumTypes.RaiseType raiseType;
        address owner;
    }

    /// @dev Struct containing detailed info about raise.
    /// @param tokensPerBaseAsset Ratio of how much tokens is worth 1 unit of base asset (erc20 * precision / hardcap)
    /// @param hardcap Max amount of base asset to collect during a raise
    /// @param softcap Min amount of base asset to collect during a raise
    /// @param start Start date of raise
    /// @param end End date of raise
    struct RaiseDetails {
        uint256 tokensPerBaseAsset;
        uint256 hardcap;
        uint256 softcap;
        uint256 start;
        uint256 end;
    }

    /// @dev Struct containing information about the raise shared across chains.
    /// @param raised Amount of raised base asset for fundraising
    /// @param merkleRoot Merkle root compressing all information about investors and their investments
    struct RaiseDataCC {
        uint256 raised;
        bytes32 merkleRoot;
    }

    // -----------------------------------------------------------------------
    //                              ERC-20 Asset
    // -----------------------------------------------------------------------

    /// @dev Struct defining ERC20 offered by startup for investments.
    /// @param erc20 Address of ERC20 token
    /// @param chainId ID of network that asset exists
    /// @param amount Total amount of ERC20 used in vesting
    struct ERC20Asset {
        address erc20;
        uint256 chainId;
        uint256 amount;
    }

    // -----------------------------------------------------------------------
    //                              Base Asset
    // -----------------------------------------------------------------------

    /// @dev Struct defining base asset used for investment on particular chain.
    /// @param base Address of base asset
    /// @param chainId ID of network that asset exists
    struct BaseAsset {
        address base;
        uint256 chainId;
    }

    // -----------------------------------------------------------------------
    //                              Investor Funds Info
    // -----------------------------------------------------------------------

    /// @dev Struct containing info about state of investor funds.
    /// @param invested Mapping that stores how much given address invested
    /// @param investmentRefunded Mapping that tracks if user was refunded
    struct InvestorFundsInfo {
        mapping(address => uint256) invested;
        mapping(address => bool) investmentRefunded;
    }

    // -----------------------------------------------------------------------
    //                              Startup Funds Info
    // -----------------------------------------------------------------------

    /// @dev Struct containing info about state of startup funds.
    /// @param collateralRefunded Boolean describing if startup was refunded
    /// @param reclaimed Boolean that shows if startup reclaimed unsold tokens
    struct StartupFundsInfo {
        bool collateralRefunded;
        bool reclaimed;
    }

    // -----------------------------------------------------------------------
    //                              Milestone
    // -----------------------------------------------------------------------

    /// @dev Struct containing info about milestone and shares it's unlocking.
    /// @param milestoneId UUID of milestone
    /// @param milestoneNo Index of milestone (counted from 1)
    /// @param share % of unlocked tokens (12.5% = 12.5 * 1_000_000)
    struct Milestone {
        string milestoneId;
        uint256 milestoneNo;
        uint256 share;
    }

    /// @dev Struct containing milestones and share data.
    /// @param milestones Ordered list of unlocked milestones containing all their details
    /// @param unlockedShares Sum of shares from all submitted milestones
    /// @param rejectedShares Amount of shares reverted back due to failed repair plan
    /// @param totalShares Sum of all unlocked and rejected shares (should not exceed 100%)
    struct ShareInfo {
        Milestone[] milestones;
        uint256 unlockedShares;
        uint256 rejectedShares;
        uint256 totalShares;
    }

    // -----------------------------------------------------------------------
    //                              Claiming
    // -----------------------------------------------------------------------

    /// @dev Struct containing frequently used storage for claiming purposes.
    /// @param investorClaimed Mapping that stores amount claimed of each investor
    /// @param startupClaimed Amount of claimed assets by startup owner
    struct ClaimingInfo {
        mapping(address => uint256) investorClaimed;
        uint256 startupClaimed;
    }
}
