// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./JamInteraction.sol";

/// @title JamHooks
/// @notice JamHooks is a library for managing pre and post interactions
library JamHooks {

    /// @dev Data structure for pre and post interactions
    struct Def {
        JamInteraction.Data[] beforeSettle;
        JamInteraction.Data[] afterSettle;
    }
}
