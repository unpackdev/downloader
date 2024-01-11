// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILabGame {
	function getToken(uint256 _tokenId) external view returns (uint256);
	function balanceOf(address _account) external view returns (uint256);
	function tokenOfOwnerByIndex(address _account, uint256 _index) external view returns (uint256);
	function ownerOf(uint256 _tokenId) external view returns (address);
}