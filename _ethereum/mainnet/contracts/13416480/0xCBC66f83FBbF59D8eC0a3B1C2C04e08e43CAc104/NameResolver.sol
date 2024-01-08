// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Resolver.sol";
import "./INameResolver.sol";

abstract contract NameResolver is INameResolver, Resolver {
    bytes4 private constant _interfaceId = 0x691f3431;

    mapping(bytes32 => string) internal _names;

    constructor() {
        registerSupportedInterface(_interfaceId);
    }

    function name(bytes32 node)
        external
        view
        returns (string memory)
    {
        return _names[node];
    }

    function _setName(
        bytes32 node,
        string calldata _name
    )
        internal
    {
        require(
            node.length != 0,
            "node cannot be empty"
        );

        require(
            bytes(_name).length != 0,
            "name cannot be empty"
        );

        _names[node] = _name;

        emit NameChanged(node, _name);
    }
}
