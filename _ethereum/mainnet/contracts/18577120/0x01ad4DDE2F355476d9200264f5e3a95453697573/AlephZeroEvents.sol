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

// Local imports
import "./BridgeTypes.sol";

/**************************************

    AlephZero specific events

**************************************/

/// @dev All events used in the A0 communication
library AlephZeroEvents {
    /// @dev Emitted when message is correctly sent.
    /// @param target Struct containing information about cross-chain target receiver
    /// @param source Struct containing information about sender
    /// @param tx Struct containing all necessary information for cross-chain transaction processing
    event AlephZeroSenderEvent(BridgeTypes.Target target, BridgeTypes.Source source, BridgeTypes.Transaction tx);
}
