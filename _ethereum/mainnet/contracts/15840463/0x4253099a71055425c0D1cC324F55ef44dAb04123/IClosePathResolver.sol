// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import "./IRouterComponent.sol";

import "./PathOption.sol";
import "./StrategyPathTask.sol";
import "./IRouter.sol";

interface IClosePathResolver is IRouterComponent {
    function findBestClosePath(
        StrategyPathTask memory task,
        PathOption[] memory pathOptions,
        uint256 cycles
    ) external returns (StrategyPathTask memory result);
}
