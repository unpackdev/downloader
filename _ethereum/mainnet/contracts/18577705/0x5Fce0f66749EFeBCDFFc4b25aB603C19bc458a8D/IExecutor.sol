// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IExecutorEvents.sol";

interface IExecutor is IExecutorEvents {
    function requiresCPIT() external returns (bool);
}
