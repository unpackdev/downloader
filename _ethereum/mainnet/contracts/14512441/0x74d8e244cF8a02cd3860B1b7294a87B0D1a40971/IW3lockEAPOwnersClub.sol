//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IW3lockEAPOwnersClub {
	function mintTo(
		uint256 tokenId,
		uint256 batchNumber,
		address beneficiary
	) external;
}
