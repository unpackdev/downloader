// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.7.6;

import "./EnumerableSet.sol";

import "./IFactory.sol";
import "./InstanceRegistry.sol";
import "./PowerSwitch.sol";

/// @title Power Switch Factory
/// @dev Security contact: dev-support@ampleforth.org
contract PowerSwitchFactory is IFactory, InstanceRegistry {
    function create(bytes calldata args) external override returns (address) {
        address owner = abi.decode(args, (address));
        PowerSwitch powerSwitch = new PowerSwitch(owner);
        InstanceRegistry._register(address(powerSwitch));
        return address(powerSwitch);
    }

    function create2(bytes calldata, bytes32) external pure override returns (address) {
        revert("PowerSwitchFactory: unused function");
    }
}
