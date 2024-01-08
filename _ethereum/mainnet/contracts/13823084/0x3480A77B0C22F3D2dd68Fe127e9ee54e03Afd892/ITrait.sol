// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrait {
	function name() external view returns (string memory);

	function itemCount() external view returns (uint256);

	function totalItems() external view returns (uint256);

	function getTraitName(uint16 traitId) external view returns (string memory);

	function getTraitContent(uint16 traitId) external view returns (string memory);

	function getTraitByAge(uint16 age) external view returns (uint16);

	function isOverEye(uint16 traitId) external view returns (bool);
}
