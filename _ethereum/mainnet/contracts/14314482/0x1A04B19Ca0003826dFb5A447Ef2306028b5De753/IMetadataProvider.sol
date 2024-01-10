// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC165.sol";
import "./ITicTacToe.sol";

/// @title Provides the on-chain metadata (including svg image) to the contract
/// @dev Supports the ERC-721 contract
interface IMetadataProvider is IERC165 {

	/// Represents the utf-8 string of the contract's player in the output image
	function contractSymbol() external returns (string memory);

	/// @dev Returns the on-chain ERC-721 metadata for a TicTacToe game given its GameUtils.GameInfo structure and tokenId
	/// @param game The game's state structure
	/// @param tokenId The game's Token Id
	/// @return The raw json uri as a string
	function metadata(ITicTacToe.Game memory game, uint256 tokenId) external view returns (string memory);

	/// Represents the utf-8 string of the owner's player in the output image
	function ownerSymbol() external returns (string memory);
}
