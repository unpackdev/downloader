//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IW3lockEAPOwnersClub {
	function mintTo(
		uint256 _tokenId,
		uint256 _batchNumber,
		address _beneficiary
	) external;
}
