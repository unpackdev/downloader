// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IOwnable.sol";
import "./IERC20Metadata.sol";
import "./IERC20AltApprove.sol";

interface IPlanet is IOwnable, IERC20AltApprove, IERC20Metadata
{
	event Enter(address indexed sender, uint256 amount, address indexed to);
	event Leave(address indexed sender, uint256 amount, address indexed to);

	function enter(uint256 amount, address to) external;
	function leave(uint256 amount, address to) external;
	function token() external view returns (IERC20Metadata);
}