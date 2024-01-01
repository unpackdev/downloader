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

/**************************************

    Request errors

**************************************/

/// @dev All errors connected with secure communication.
library RequestErrors {
    // -----------------------------------------------------------------------
    //                              Request
    // -----------------------------------------------------------------------

    error RequestExpired(address sender, uint256 expiry); // 0x8a288b92
    error NonceExpired(address sender, uint256 nonce); // 0x2b6069a9
    error IncorrectSender(address sender); // 0x7da9057e
}
