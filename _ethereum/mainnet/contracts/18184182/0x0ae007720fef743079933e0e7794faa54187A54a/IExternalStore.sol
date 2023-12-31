pragma solidity 0.8.19;

// SPDX-License-Identifier: MIT

interface IExternalStore {
    function store(
        address user,
        bytes32 namespace,
        uint slot,
        bytes memory data
    ) external;

    function getStore(
        address user,
        bytes32 namespace,
        uint slot
    ) external view returns (bytes memory);

    function store(bytes32 namespace, uint slot, bytes memory data) external;

    function getStore(
        bytes32 namespace,
        uint slot
    ) external view returns (bytes memory);

    function owner() external view returns(address);
    function getOwner() external view returns(address);
}