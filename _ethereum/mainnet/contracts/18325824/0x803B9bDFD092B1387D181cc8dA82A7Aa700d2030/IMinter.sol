// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IMinter {
	function mint(
		address token,
		uint depositAmount,
		uint minProposedAmount,
		bytes32 salt,
		bytes calldata extraData
	) external;

	function redeem(uint amount, address token, bytes32 salt, bytes calldata extraData) external;
}
