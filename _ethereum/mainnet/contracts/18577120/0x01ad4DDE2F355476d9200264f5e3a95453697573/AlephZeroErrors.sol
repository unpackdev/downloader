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

    AlephZero errors
    
**************************************/

/// @dev All errors used in AlephZero cross chain communication
library AlephZeroErrors {
    // -----------------------------------------------------------------------
    //                              Payload
    // -----------------------------------------------------------------------

    error UnsupportedFunction(bytes4 functionName); // 0x1a366124
}
