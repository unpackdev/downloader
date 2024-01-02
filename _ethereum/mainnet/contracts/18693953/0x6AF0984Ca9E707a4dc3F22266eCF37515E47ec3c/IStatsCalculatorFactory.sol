// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./ISystemComponent.sol";

/// @title Create and register stat calculators
interface IStatsCalculatorFactory is ISystemComponent {
    /// @notice Create an instance of a calculator pointed to a pool or destination
    /// @param aprTemplateId id of the template registered with the factory
    /// @param dependentAprIds apr ids that cover the dependencies of this calculator
    /// @param initData setup data specific to the type of calculator
    /// @return calculatorAddress the id that was generated based on the init data
    function create(
        bytes32 aprTemplateId,
        bytes32[] calldata dependentAprIds,
        bytes calldata initData
    ) external returns (address calculatorAddress);
}
