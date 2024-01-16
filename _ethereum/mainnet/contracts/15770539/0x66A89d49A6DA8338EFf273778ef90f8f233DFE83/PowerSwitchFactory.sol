// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "./EnumerableSet.sol";

import "./IFactory.sol";
import "./InstanceRegistry.sol";
import "./PowerSwitch.sol";

/// @title Power Switch Factory
contract PowerSwitchFactory is IFactory, InstanceRegistry {
    function create(bytes calldata args)
        external
        override
        returns (address)
    {
        (address owner, uint64 startTimestamp) =
            abi.decode(args, (address, uint64));
        PowerSwitch powerSwitch = new PowerSwitch(owner, startTimestamp);
        InstanceRegistry._register(address(powerSwitch));
        return address(powerSwitch);
    }

    function create2(bytes calldata, bytes32)
        external
        pure
        override
        returns (address)
    {
        revert("PowerSwitchFactory: unused function");
    }
}