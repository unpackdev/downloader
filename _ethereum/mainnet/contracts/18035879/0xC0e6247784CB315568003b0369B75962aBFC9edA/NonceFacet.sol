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
import "./LibNonce.sol";
import "./INonceFacet.sol";

/**************************************

    Nonce facet

**************************************/

/// @notice Nonce facet implementing retrieving last used nonce.
contract NonceFacet is INonceFacet {
    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev Retrieve last used nonce for given account.
    /// @param _account Address of account
    /// @return Number of last used nonce
    function getLastNonce(address _account) external view returns (uint256) {
        // return
        return LibNonce.getLastNonce(_account);
    }
}
