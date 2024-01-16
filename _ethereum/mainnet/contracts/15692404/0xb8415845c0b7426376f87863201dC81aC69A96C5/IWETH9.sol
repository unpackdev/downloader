// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20Metadata.sol";

interface IWETH9 is IERC20Metadata
{
	event Deposit(address indexed from, uint256 value);
	event Withdraw(address indexed to, uint256 value);
	
	function deposit() external payable;
	function withdraw(uint256 value) external;
}