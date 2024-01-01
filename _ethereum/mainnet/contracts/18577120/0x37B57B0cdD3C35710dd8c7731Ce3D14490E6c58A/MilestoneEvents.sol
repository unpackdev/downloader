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

import "./StorageTypes.sol";

/**************************************

    Milestone events

**************************************/

/// @notice All events connected with milestones.
library MilestoneEvents {
    // -----------------------------------------------------------------------
    //                              Unlock of milestone
    // -----------------------------------------------------------------------

    event MilestoneUnlocked(string raiseId, StorageTypes.Milestone milestone);
    event MilestoneUnlocked__StartupClaimed(string raiseId, address startup, uint256 claimed);
    event MilestoneUnlocked__InvestorClaimed(string raiseId, address erc20, address investor, uint256 claimed);

    // -----------------------------------------------------------------------
    //                              Failed repair plan
    // -----------------------------------------------------------------------

    event RaiseRejected(string raiseId, uint256 rejectedShares);
    event RaiseRejected__StartupClaimed(string raiseId, address erc20, address startup, uint256 claimed);
    event RaiseRejected__InvestorClaimed(string raiseId, address investor, uint256 claimed);
}
