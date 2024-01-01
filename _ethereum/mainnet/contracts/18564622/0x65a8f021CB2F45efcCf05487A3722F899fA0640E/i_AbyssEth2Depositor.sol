// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface i_AbyssEth2Depositor {
	function deposit(
		bytes[] calldata pubkeys,
		bytes[] calldata withdrawal_credentials,
		bytes[] calldata signatures,
		bytes32[] calldata deposit_data_roots
	) external payable;
}
