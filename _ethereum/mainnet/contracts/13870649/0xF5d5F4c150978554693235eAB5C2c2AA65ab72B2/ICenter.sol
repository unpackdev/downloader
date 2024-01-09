// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICenter {
	function setId(uint256 _id) external;

	function addFeeAmount(uint256 feeAmount) external;

	function enter(uint256 tokenId) external returns (uint256);

	function exit(uint256 tokenId) external returns (uint256);

	function work(
		uint256 tokenId,
		uint16 task,
		uint256 working
	) external returns (uint256 info, uint256 reward);

	function enjoyFee() external view returns (uint16);

	function grown(uint256 tokenId) external view returns (uint256);

	function rewards(uint256 tokenId) external view returns (uint256);

	function metadata() external view returns (string memory);

	function grow(uint256 tokenId) external returns (uint256 _growing);
}
