// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Registry holding the rarity value of a given NFT.
/// @author Nemitari Ajienka @najienka
interface INFTRarityRegister {
	/**
	 * The Staking SC allows to stake Prizes won via lottery which can be used to increase the APY of
	 * staked tokens according to the rarity of NFT staked. For this reason,
	 * we need to hold a table that the Staking SC can query and get back the rarity value of a given
	 * NFT price (even the ones in the past).
	 */
	event NftRarityStored(
		address indexed tokenAddress,
		uint256 tokenId,
		uint256 rarityValue
	);

	/**
	 * @dev Store the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @param rarityValue The rarity of a given NFT address and id unique combination
	 */
	function storeNftRarity(address tokenAddress, uint256 tokenId, uint8 rarityValue) external;

	/**
	 * @dev Get the rarity of a given NFT
	 * @param tokenAddress The NFT smart contract address e.g., ERC-721 standard contract
	 * @param tokenId The NFT's unique token id
	 * @return The the rarity of a given NFT address and id unique combination and timestamp
	 */
	function getNftRarity(address tokenAddress, uint256 tokenId) external view returns (uint8);
}
