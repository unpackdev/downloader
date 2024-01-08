// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    function name(bytes32) external view returns (string memory);

    function setName(bytes32, string calldata) external;
}
