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

/// @notice Library with core types definition.
library EnumTypes {
    // -----------------------------------------------------------------------
    //                              Raise
    // -----------------------------------------------------------------------

    /// @dev Definition of supported types of raises.
    enum RaiseType {
        Standard,
        EarlyStage
    }

    // -----------------------------------------------------------------------
    //                              Cross chain
    // -----------------------------------------------------------------------

    /// @dev Definition of supported cross chain providers.
    enum CrossChainProvider {
        None,
        LayerZero,
        AlephZero
    }
}
