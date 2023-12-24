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

// Local imports
import "./LibEscrow.sol";
import "./IEscrowFacet.sol";

/**************************************

    Escrow facet

**************************************/

/// @notice Escrow facet implementing retrieving escrow created for raise.
contract EscrowFacet is IEscrowFacet {
    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev Retrieve created escrow for raise.
    /// @param _raiseId ID of raise
    /// @return Address of escrow
    function getEscrow(string memory _raiseId) external view returns (address) {
        // return
        return LibEscrow.getEscrow(_raiseId);
    }
}
