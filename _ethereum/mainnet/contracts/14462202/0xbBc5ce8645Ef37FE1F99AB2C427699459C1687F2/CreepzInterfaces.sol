// SPDX-License-Identifier: MIT
pragma solidity >=0.8;

interface ILoomi {
	function approve(address spender, uint256 amount) external;

	function transfer(address to, uint256 amount) external;

	function balanceOf(address user) external view returns (uint256);

	function withdrawLoomi(uint256 amount) external;

	function withdrawTaxAmount() external view returns (uint256);
}

interface ICreepz {
	function setApprovalForAll(address to, bool approved) external;

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;
}

interface IShapeshifter {
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;
}

interface IMegaShapeshifter {
	function setApprovalForAll(address to, bool approved) external;

	function claimTax(
		uint256 amount,
		uint256 nonce,
		uint256 creepzId,
		bytes calldata signature
	) external;

	function mutate(
		uint256[] memory shapeIds,
		uint256 shapeType,
		bytes calldata signature
	) external;

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function balanceOf(address account) external view returns (uint256);
}
