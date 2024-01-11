//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IETHRegistrarController {
    function commit(bytes32 commitment) external;

    function register(string calldata name, address owner, uint256 duration, bytes32 secret) external payable;

    function renew(string calldata name, uint256 duration) external payable;

    function rentPrice(string memory name, uint256 duration) external view returns (uint256);
}
