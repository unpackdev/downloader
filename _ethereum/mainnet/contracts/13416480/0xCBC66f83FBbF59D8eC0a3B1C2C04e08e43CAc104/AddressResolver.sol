// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Resolver.sol";
import "./IAddressResolver.sol";

abstract contract AddressResolver is IAddressResolver, Resolver {
    bytes4 private constant _interfaceId = 0x3b3b57de;

    mapping(bytes32 => address) internal _addresses;

    constructor() {
        registerSupportedInterface(_interfaceId);
    }

    function addr(bytes32 node)
        external
        view
        returns (address)
    {
        return _addresses[node];
    }

    function _setAddr(
        bytes32 node,
        address _addr
    )
        internal
    {
        require(
            node.length != 0,
            "node cannot be empty"
        );

        require(
            _addr != address(0),
            "address cannot be zero address"
        );

        _addresses[node] = _addr;

        emit AddrChanged(node, _addr);
    }
}
