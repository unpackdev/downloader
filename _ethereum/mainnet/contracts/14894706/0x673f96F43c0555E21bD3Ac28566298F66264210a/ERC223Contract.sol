// SPDX-License-Identifier: MPL-2.0
pragma solidity =0.8.9;

interface ERC223Contract {
	function tokenFallback(
		address from_,
		uint256 value_,
		bytes memory data_
	) external;
}
