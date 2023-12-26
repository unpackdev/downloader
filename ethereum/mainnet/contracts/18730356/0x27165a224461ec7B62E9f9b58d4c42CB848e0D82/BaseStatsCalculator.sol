// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./Stats.sol";
import "./Roles.sol";
import "./Errors.sol";
import "./SecurityBase.sol";
import "./ISystemRegistry.sol";
import "./IStatsCalculator.sol";
import "./ICurveRegistry.sol";
import "./IStatsCalculatorRegistry.sol";

/// @title Base Stats Calculator
/// @notice Captures common behavior across all calculators
/// @dev Performs security checks and general roll-up behavior
abstract contract BaseStatsCalculator is IStatsCalculator, SecurityBase {
    ISystemRegistry public immutable systemRegistry;

    modifier onlyStatsSnapshot() {
        if (!_hasRole(Roles.STATS_SNAPSHOT_ROLE, msg.sender)) {
            revert Errors.MissingRole(Roles.STATS_SNAPSHOT_ROLE, msg.sender);
        }
        _;
    }

    constructor(ISystemRegistry _systemRegistry) SecurityBase(address(_systemRegistry.accessController())) {
        systemRegistry = _systemRegistry;
    }

    /// @inheritdoc IStatsCalculator
    function snapshot() external override onlyStatsSnapshot {
        if (!shouldSnapshot()) {
            revert NoSnapshotTaken();
        }
        _snapshot();
    }

    /// @notice Capture stat data about this setup
    /// @dev This is protected by the STATS_SNAPSHOT_ROLE
    function _snapshot() internal virtual;

    /// @inheritdoc IStatsCalculator
    function shouldSnapshot() public view virtual returns (bool takeSnapshot);
}
