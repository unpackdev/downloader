// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IERC20Pair {
	function token0() external pure returns (address);

	function token1() external pure returns (address);

	function balanceOf(address user) external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function getReserves()
		external
		view
		returns (
			uint112 _reserve0,
			uint112 _reserve1,
			uint32 _blockTimestampLast
		);

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
