// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

import "./Resolver.sol";
import "./AddressResolver.sol";
import "./NameResolver.sol";

contract ENSResolver is
    Ownable,
    AddressResolver,
    NameResolver
{
    constructor() {}

    function setAddr(
        bytes32 node,
        address _addr
    )
        external
        onlyOwner
    {
        _setAddr(node, _addr);
    }

    function setName(
        bytes32 node,
        string calldata _name
    )
        external
        onlyOwner
    {
        _setName(node, _name);
    }
}
