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

    Escrow events
    
**************************************/

// ToDo : NatSpec

/// @dev All events used in the Escrow functionalities
library EscrowEvents {
    event EscrowCreated(string raiseId, address instance, address source);
}
