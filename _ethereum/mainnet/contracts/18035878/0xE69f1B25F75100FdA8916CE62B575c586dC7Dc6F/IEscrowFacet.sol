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

/// @notice Interface for escrow facet.
interface IEscrowFacet {
    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev Retrieve created escrow for raise.
    /// @param _raiseId ID of raise
    /// @return Address of escrow
    function getEscrow(string memory _raiseId) external view returns (address);
}
