// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

/**************************************

    Milestone errors

**************************************/

/// All errors connected with milestone.
library MilestoneErrors {
    // -----------------------------------------------------------------------
    //                              Unlock
    // -----------------------------------------------------------------------

    error InvalidMilestoneNumber(uint256 milestoneNo, uint256 milestoneCount); // 0x14dc2b26
    error ZeroShare(uint256 milestoneNo); // 0xef647f82
    error ShareExceedLimit(uint256 share, uint256 existing); // 0x17e013d5

    // -----------------------------------------------------------------------
    //                              Claim
    // -----------------------------------------------------------------------

    error TokenNotOnEscrow(string raiseId); // 0x35880bf8
    error NothingToClaim(string raiseId, address account); // 0xf5709e8a

    // -----------------------------------------------------------------------
    //                              Failed repair plan
    // -----------------------------------------------------------------------

    error RaiseAlreadyRejected(string raiseId, uint256 rejected); // 0xcb1dc2af
    error AllMilestonesUnlocked(string raiseId, uint256 unlocked); // 0x731a1b87

    // -----------------------------------------------------------------------
    //                              Claim (repair plan)
    // -----------------------------------------------------------------------

    error RaiseNotRejected(string raiseId); // 0x4e9e01f8
}
