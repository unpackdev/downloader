// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import "./IPoolBase.sol";
import "./IPoolEvents.sol";
import "./IPoolExercise.sol";
import "./IPoolIO.sol";
import "./IPoolSettings.sol";
import "./IPoolView.sol";
import "./IPoolWrite.sol";

interface IPool is
    IPoolBase,
    IPoolEvents,
    IPoolExercise,
    IPoolIO,
    IPoolSettings,
    IPoolView,
    IPoolWrite
{}
