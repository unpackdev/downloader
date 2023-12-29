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
import "./AccessTypes.sol";
import "./LibAccessControl.sol";
import "./LibSignature.sol";

/**************************************

    Verify signature mixin

**************************************/

/// @notice Mixin that injects signature verification into facets.
library VerifySignatureMixin {
    // -----------------------------------------------------------------------
    //                              Errors
    // -----------------------------------------------------------------------

    error IncorrectSigner(address signer); // 0x33ffff9b

    // -----------------------------------------------------------------------
    //                              Functions
    // -----------------------------------------------------------------------

    /// @dev Verify signature.
    /// @dev Validation: Fails if message is signed by account without signer role.
    /// @param _message Hash of message
    /// @param _v Part of signature
    /// @param _r Part of signature
    /// @param _s Part of signature
    function verifySignature(bytes32 _message, uint8 _v, bytes32 _r, bytes32 _s) internal view {
        // signer of message
        address signer_ = LibSignature.recoverSigner(_message, _v, _r, _s);

        // validate signer
        if (!LibAccessControl.hasRole(AccessTypes.SIGNER_ROLE, signer_)) {
            revert IncorrectSigner(signer_);
        }
    }
}
