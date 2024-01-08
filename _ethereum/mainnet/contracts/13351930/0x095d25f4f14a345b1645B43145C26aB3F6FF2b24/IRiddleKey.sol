// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./IERC1155.sol";

interface IRiddleKey is IERC1155 {
	function initialize() external;
	function transfer(address to, uint256 _tokenId, bytes memory data) external;
	function safeTransferFrom(address from, address to, uint256 _tokenId, uint256 amount, bytes memory data) external override;
	function maxSupplyOf(uint _level) external view returns (uint);
	function currentSupplyOf(uint _level) external view returns (uint);
	function tokenOf(uint32 _tokenId) external view returns (uint32);
	function levelOf(uint _tokenId) external view returns (uint);
}
