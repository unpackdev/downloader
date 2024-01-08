//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

interface IERC20WithPermit {
	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function approve(address spender, uint256 value) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}
