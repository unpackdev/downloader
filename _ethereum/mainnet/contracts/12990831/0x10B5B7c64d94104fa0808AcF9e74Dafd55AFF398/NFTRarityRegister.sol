// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./INFTRarityRegister.sol";
import "./Ownable.sol";

/// @title Registry holding the rarity value of a given NFT.
/// @author Nemitari Ajienka @najienka
contract NFTRarityRegister is INFTRarityRegister, Ownable {
	mapping(address => mapping(uint256 => uint8)) private rarityRegister;

	/**
	 * @dev Store the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @param rarityValue The rarity of a given NFT address and id unique combination
	 * using percentage i.e., 100% = 1000 to correct for precision and
	 * to save gas required when converting from category, e.g.,
	 * high, medium, low to percentage in staking contract
	 * can apply rarityValue on interests directly after fetching
	 */
	function storeNftRarity(address tokenAddress, uint tokenId, uint8 rarityValue) external override onlyOwner {
		// check tokenAddress, tokenId and rarityValue are valid
		// _exists ERC721 function is internal
		require(tokenAddress != address(0), "NFTRarityRegister: Token address is invalid");
		require(getNftRarity(tokenAddress, tokenId) == 0, "NFTRarityRegister: Rarity already set for token");
		require(rarityValue >= 100, "NFTRarityRegister: Value must be at least 100");

		rarityRegister[tokenAddress][tokenId] = rarityValue;

		emit NftRarityStored(tokenAddress, tokenId, rarityValue);
	}

	/**
	 * @dev Get the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @return The the rarity of a given NFT address and id unique combination and timestamp
	 */
	function getNftRarity(address tokenAddress, uint256 tokenId) public override view returns (uint8) {
		return rarityRegister[tokenAddress][tokenId];
	}
}