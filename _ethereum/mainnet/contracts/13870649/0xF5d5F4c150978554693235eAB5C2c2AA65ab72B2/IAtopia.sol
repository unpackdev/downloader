// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBucks.sol";

interface IAtopia {
	function owner() external view returns (address);

	function bucks() external view returns (IBucks);

	function getAge(uint256 tokenId) external view returns (uint256);

	function ownerOf(uint256 tokenId) external view returns (address);

	function update(uint256 tokenId) external;

	function exitCenter(
		uint256 tokenId,
		uint256 grown,
		uint256 enjoyFee
	) external returns (uint256);

	function addReward(uint256 tokenId, uint256 reward) external;

	function claimGrowth(
		uint256 tokenId,
		uint256 grown,
		uint256 enjoyFee
	) external returns (uint256);

	function claimBucks(address user, uint256 amount) external;

	function buyAndUseItem(
		uint256 tokenId,
		uint256 itemInfo
	) external;
}
