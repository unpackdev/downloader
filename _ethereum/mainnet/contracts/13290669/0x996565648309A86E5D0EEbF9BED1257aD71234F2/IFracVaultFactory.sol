// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface IFracVaultFactory {
	function vaults(uint256) external returns (address);

	function mint(
		string memory name,
		string memory symbol,
		address token,
		uint256 id,
		uint256 supply,
		uint256 listPrice,
		uint256 fee
	) external returns (uint256);
}
