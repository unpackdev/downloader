// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
    event AddrChanged(bytes32 indexed node, address a);

    function addr(bytes32) external view returns (address);

    function setAddr(bytes32, address) external;
}
