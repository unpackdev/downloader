// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface i_governance {
	function transfer_stake(address from, address to, uint256 amount) external;
}
