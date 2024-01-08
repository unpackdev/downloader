// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ITrait.sol";

interface IDrawer {
	function traitCount() external view returns (uint16);

	function itemCount(uint256 traitId) external view returns (uint256);

	function totalItems(uint256 traitId) external view returns (uint256);

	function tokenURI(
		uint256 tokenId,
		string memory name,
		uint256 tokenTrait,
		uint16 age
	) external view returns (string memory);
}
