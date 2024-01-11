// SPDX-License-Identifier: MIT

/// @title Interface for JBProjectHandles

pragma solidity ^0.8.0;

interface IJBProjectHandles {
    event SetEnsName(uint256 indexed projectId, string indexed ensName);

    function setEnsNameFor(uint256 projectId, string calldata ensName) external;

    function ensNameOf(uint256 projectId)
        external
        view
        returns (string memory ensName);

    function handleOf(uint256 projectId) external view returns (string memory);
}
