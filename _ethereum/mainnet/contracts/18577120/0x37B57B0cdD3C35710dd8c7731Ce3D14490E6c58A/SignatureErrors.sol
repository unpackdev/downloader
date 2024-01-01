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

    Signature errors
    
**************************************/

/// @dev All errors used in the signature verification
library SignatureErrors {
    error IncorrectSigner(address signer); // 0x33ffff9b
    error InvalidMessage(bytes32 verify, bytes32 message); // 0xeeba4d9c
}
