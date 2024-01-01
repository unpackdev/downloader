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

/// @notice Constants used in milestone facet and milestone encoder.
library MilestoneConstants {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev EIP712 name
    bytes32 internal constant EIP712_NAME = keccak256(bytes("Fundraising:Milestone"));
    /// @dev EIP712 versioning: "release:major:minor"
    bytes32 internal constant EIP712_VERSION = keccak256(bytes("2:0:0"));

    // typehashes
    bytes32 internal constant VOTING_UNLOCK_MILESTONE_TYPEHASH = keccak256("UnlockMilestoneRequest(string raiseId,bytes milestone,bytes base)");
    bytes32 internal constant VOTING_REJECT_RAISE_TYPEHASH = keccak256("RejectRaiseRequest(string raiseId,bytes base)");
    bytes32 internal constant USER_CLAIM_TYPEHASH = keccak256("ClaimRequest(string raiseId,address recipient,bytes base)");
}
