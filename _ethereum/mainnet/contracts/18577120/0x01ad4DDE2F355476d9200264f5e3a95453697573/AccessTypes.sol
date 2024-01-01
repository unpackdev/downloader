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

/// @notice Library containing role definition for access management.
library AccessTypes {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev AngelBlock validator role
    bytes32 internal constant SIGNER_ROLE = keccak256("IS SIGNER");
    /// @dev LayerZero receiver's admin role
    bytes32 internal constant LZ_RECEIVER_ADMIN_ROLE = keccak256("LZ RECEIVER ADMIN");
}
