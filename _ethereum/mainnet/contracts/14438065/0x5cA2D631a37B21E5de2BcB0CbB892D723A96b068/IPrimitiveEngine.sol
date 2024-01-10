// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.4;

import "./IPrimitiveEngineActions.sol";
import "./IPrimitiveEngineEvents.sol";
import "./IPrimitiveEngineView.sol";
import "./IPrimitiveEngineErrors.sol";

/// @title Primitive Engine Interface
interface IPrimitiveEngine is
    IPrimitiveEngineActions,
    IPrimitiveEngineEvents,
    IPrimitiveEngineView,
    IPrimitiveEngineErrors
{

}
