// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

error NoClaimAvailable(address _account);

interface IClaimable {
	function claim() external;
	function pendingClaim(address _account) external view returns (uint256);
	function initializeClaim(uint256 _tokenId) external;
	function updateClaim(address _account, uint256 _tokenId) external;

	event Claimed(address indexed _account, uint256 _amount);
	event Updated(address indexed _account, uint256 indexed _tokenId);
}