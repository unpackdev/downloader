// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";


/// @title MealDrops tokens
/// @author Valerio Leo @valeriohq
contract MealDrops is ERC721, Ownable {

	string private _baseTokenURI;

	constructor(
		string memory name,
		string memory symbol,
    string memory baseTokenURI
	)
	  ERC721(name, symbol)
	{
		_baseTokenURI = baseTokenURI;
	}

	function _baseURI() internal view virtual override returns (string memory) {
			return _baseTokenURI;
	}

	/**
		* @dev See {IERC721Metadata-tokenURI}.
		*/
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
		string memory resource = super.tokenURI(tokenId);

		return bytes(resource).length > 0 ? string(abi.encodePacked(resource, ".json")) : "";
	}

	/**
	 * @dev Function to mint tokens.
	 * @param to The address that will receive the minted tokens.
	 * @param tokenId The token id to mint.
	 * @return A boolean that indicates if the operation was successful.
	 */
	function mint(address to, uint256 tokenId) onlyOwner public returns (bool) {
		super._safeMint(to, tokenId);
		return true;
	}

	/**
	 * @dev Function to batch-mint tokens.
	 * @param to The address that will receive the minted tokens.
	 * @param from The token id where to start from.
	 * @param to The token id where to finish minting.
	 * @return A boolean that indicates if the operation was successful.
	 */
	function batchMint(uint256 from, uint256 to, address receiver) onlyOwner public returns (bool) {
		for (uint256 index = from; index <= to; index++) {
			mint(receiver, index);
		}
		return true;
	}
}