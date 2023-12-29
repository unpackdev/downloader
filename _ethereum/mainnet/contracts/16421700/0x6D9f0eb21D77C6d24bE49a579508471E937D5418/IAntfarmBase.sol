// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./IAntfarmPairState.sol";
import "./IAntfarmPairEvents.sol";
import "./IAntfarmPairActions.sol";
import "./IAntfarmPairDerivedState.sol";

interface IAntfarmBase is
    IAntfarmPairState,
    IAntfarmPairEvents,
    IAntfarmPairActions,
    IAntfarmPairDerivedState
{}
