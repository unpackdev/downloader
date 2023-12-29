// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IMinter {
	function redeem(uint amount, address token, bytes32 salt, bytes calldata extraData) external;
}
