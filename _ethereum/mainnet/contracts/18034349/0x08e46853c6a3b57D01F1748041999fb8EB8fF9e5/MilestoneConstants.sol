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

/// @notice Constants used in milestone facet and milestone encoder.
library MilestoneConstants {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    // versioning: "release:major:minor"
    bytes32 constant EIP712_NAME = keccak256(bytes("Fundraising:Milestone"));
    bytes32 constant EIP712_VERSION = keccak256(bytes("1:1:0"));

    // typehashes
    bytes32 constant VOTING_UNLOCK_MILESTONE_TYPEHASH = keccak256("UnlockMilestoneRequest(string raiseId,bytes milestone,bytes base)");
    bytes32 constant VOTING_REJECT_RAISE_TYPEHASH = keccak256("RejectRaiseRequest(string raiseId,bytes base)");
    bytes32 constant USER_CLAIM_TYPEHASH = keccak256("ClaimRequest(string raiseId,address recipient,bytes base)");
}
