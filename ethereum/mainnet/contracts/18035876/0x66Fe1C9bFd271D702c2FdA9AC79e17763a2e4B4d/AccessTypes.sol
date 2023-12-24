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

/// @notice Library containing role definition for access management.
library AccessTypes {
    // -----------------------------------------------------------------------
    //                              Constants
    // -----------------------------------------------------------------------

    /// @dev AngelBlock validator role
    bytes32 constant SIGNER_ROLE = keccak256("IS SIGNER");
}
