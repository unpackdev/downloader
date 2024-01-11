// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ISToken {
	function rebase(uint256 epoch, uint256 delta) external returns (uint256);
	function circulatingSupply() external view returns (uint256);
}
