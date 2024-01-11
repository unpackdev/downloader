// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title ITokenDescriptor - Interface
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common for L1, L2 and Equipment descriptors.
interface ITokenDescriptor {
	/// @notice tokenURI
	/// @param tokenId id of token
	/// @param indices => indices of svg storage for that token. [0(inclusive), 3(exclusive)]
	function tokenURI(uint256 tokenId, uint256[2] memory indices)
		external
		view
		returns (string memory);
}
