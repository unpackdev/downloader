// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * Ser, you want to woodify your NFTs?
 * This extension allows you to mint WNFTs (wood NFTs) from your NFTs.
 */
abstract contract ERC721Woodable {
	// Wood tokens list, pointing to their tokens
	mapping (uint256 => uint256) private _woodTokens;
	// Current number of wood tokens having been minted
	uint256 private _woodTokensCount = 0;

	/**
	 * A WNFT (wood NFT) is created from a NFT.
	 */
	event WoodMint(uint256 woodTokenId, uint256 tokenId);

	/**
	 * Mint a WNFT (wood NFT) from an NFT.
	 * Ser, for safe mint, plz follow safety regulations of your wood machinery.
	 * Requirement : You need to check tokenId exists.
	 */
	function _safeWoodMint(uint256 tokenId) internal virtual {
		// Starting at id 1
		_woodTokensCount++;
		_woodTokens[_woodTokensCount] = tokenId;

		emit WoodMint(_woodTokensCount, tokenId);
	}

	/** 
	 * Get the token which was used to mint the wood token.
	 */
	function tokenOfWoodToken(uint256 woodTokenId) public view returns (uint256) {
		return _woodTokens[woodTokenId];
	}

	/**
	 * Get the total amount of WNFTs in the wild.
	 */
	function totalWoodTokenSupply() public view returns (uint256) {
		return _woodTokensCount;
	}
}