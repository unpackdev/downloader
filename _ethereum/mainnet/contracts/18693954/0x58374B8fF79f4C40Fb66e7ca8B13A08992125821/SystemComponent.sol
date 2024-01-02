// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2023 Tokemak Foundation. All rights reserved.
pragma solidity 0.8.17;

import "./ISystemComponent.sol";
import "./ISystemRegistry.sol";
import "./Errors.sol";

contract SystemComponent is ISystemComponent {
    ISystemRegistry internal immutable systemRegistry;

    constructor(ISystemRegistry _systemRegistry) {
        Errors.verifyNotZero(address(_systemRegistry), "_systemRegistry");
        systemRegistry = _systemRegistry;
    }

    function getSystemRegistry() external view returns (address) {
        return address(systemRegistry);
    }
}
