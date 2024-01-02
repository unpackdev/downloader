// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Ops Ltd. All rights reserved.
pragma solidity 0.8.17;

import "./Roles.sol";
import "./Errors.sol";
import "./SecurityBase.sol";
import "./Clones.sol";
import "./ISystemRegistry.sol";
import "./IStatsCalculator.sol";
import "./IStatsCalculatorFactory.sol";
import "./IStatsCalculatorRegistry.sol";
import "./SystemComponent.sol";

contract StatsCalculatorRegistry is SystemComponent, IStatsCalculatorRegistry, SecurityBase {
    using Clones for address;

    /// @notice Currently registered factory. Only thing can register new calculators
    IStatsCalculatorFactory public factory;

    /// slither-disable-start uninitialized-state
    /// @notice Calculators registered in this system by id
    mapping(bytes32 => address) public calculators;
    /// slither-disable-end uninitialized-state

    modifier onlyFactory() {
        if (msg.sender != address(factory)) {
            revert OnlyFactory();
        }
        _;
    }

    event FactorySet(address newFactory);
    event StatCalculatorRegistered(bytes32 aprId, address calculatorAddress, address caller);

    error OnlyFactory();
    error SystemMismatch(address ours, address theirs);
    error AlreadyRegistered(bytes32 aprId, address calculator);

    constructor(ISystemRegistry _systemRegistry)
        SystemComponent(_systemRegistry)
        SecurityBase(address(_systemRegistry.accessController()))
    { }

    function getCalculator(bytes32 aprId) external view returns (IStatsCalculator calculator) {
        address calcAddress = calculators[aprId];
        Errors.verifyNotZero(calcAddress, "calcAddress");

        calculator = IStatsCalculator(calcAddress);
    }

    function register(address calculator) external onlyFactory {
        Errors.verifyNotZero(calculator, "calculator");

        bytes32 aprId = IStatsCalculator(calculator).getAprId();
        Errors.verifyNotZero(aprId, "aprId");

        // Calculators cannot be replaced.
        // New calculators, or versions of calculators, should generate unique ids
        if (calculators[aprId] != address(0)) {
            revert AlreadyRegistered(aprId, calculator);
        }

        calculators[aprId] = calculator;

        emit StatCalculatorRegistered(aprId, calculator, msg.sender);
    }

    function setCalculatorFactory(address calculatorFactory) external onlyOwner {
        // TODO: Switch to specific access role

        Errors.verifyNotZero(address(calculatorFactory), "factory");

        factory = IStatsCalculatorFactory(calculatorFactory);

        emit FactorySet(calculatorFactory);

        ISystemRegistry factorySystem = ISystemRegistry(factory.getSystemRegistry());

        if (factorySystem != systemRegistry) {
            revert SystemMismatch(address(systemRegistry), address(factorySystem));
        }
    }
}
