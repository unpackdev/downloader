// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ICategories {
    event Added(bytes32 name);
    event Removed(bytes32 name);

    function contains(bytes32 value) external view returns (bool);
    function length() external view returns (uint256);
    function at(uint256 index) external view returns (bytes32);
    function values() external view returns (bytes32[] memory);

    function add(bytes32 value) external;
    function remove(bytes32 value) external;
}
