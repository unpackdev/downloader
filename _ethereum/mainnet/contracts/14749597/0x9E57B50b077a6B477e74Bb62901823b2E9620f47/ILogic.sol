// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface ILogic {
	function safeMint(address sender, uint tokenId) external;
	function safeClaim(address sender, uint tokenId, bool stake) external;
	
	function safeMintBatch(address sender, uint[] calldata tokenIds) external;
	function safeClaimBatch(address sender, uint[] calldata tokenIds, bool stake) external;
	
	function dailyRewards() external view returns (uint);
}

