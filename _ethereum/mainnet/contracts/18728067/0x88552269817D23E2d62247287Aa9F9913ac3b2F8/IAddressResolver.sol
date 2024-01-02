// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAddressResolver {
	function getAddress(bytes32 name) external view returns (address);
	function getRequiredAddress(bytes32 name, string calldata reason) external view returns (address);
}