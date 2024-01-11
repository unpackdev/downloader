// SPDX-License-Identifier: agpl-3.0
pragma solidity >=0.8.0;

import "./IPoolActions.sol";
import "./IPoolEvents.sol";
import "./IPoolStorage.sol";

interface IPool is IPoolActions, IPoolEvents, IPoolStorage {}
