// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IENSController {

    function getRentPrice(
        string memory name,
        address owner,
        uint256 duration,
        bytes[] calldata data
    ) view external returns (uint);

    function isAvailable(
        string memory name,
        address owner,
        uint256 duration,
        bytes[] calldata data
    ) external view returns (bool);

    function makeCommitment(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        bytes[] calldata data
    ) external view returns (bytes32);

    function commit(bytes32 commitment) external returns (uint256, uint256);

    function register(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        bytes[] calldata data
    ) external payable;

    function getBase(bytes[] calldata data) external returns (address);
}
