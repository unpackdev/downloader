// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";
import "./PBTSimple.sol";

/**
 * @title VerseLuxe v1.0
 * @author DeployLabs.io
 *
 * @notice VerseLuxe is a contract for Physical Backed Tokens (PBTs) that are backed by a physical asset, through a chip embedded in jewelry.
 */
contract VerseLuxe is PBTSimple, Ownable {
	string private s_baseTokenUri;

	constructor() PBTSimple("VerseLuxe", "VL") {}

	/**
	 * @notice Mints a new token or transfers an existing token to the message sender's wallet, based on the chip's signature.
	 *
	 * @param signatureFromChip An EIP-191 signature of (msgSender, blockhash), where blockhash is the block hash for blockNumberUsedInSig.
	 * @param blockNumberUsedInSig The block number linked to the blockhash signed in signatureFromChip. Should be a recent block number.
	 */
	function mintOrTransferTokenWithChip(
		bytes calldata signatureFromChip,
		uint256 blockNumberUsedInSig
	) external {
		TokenData memory tokenData = _getTokenDataForChipSignature(
			signatureFromChip,
			blockNumberUsedInSig
		);
		uint256 tokenId = tokenData.tokenId;

		if (!_exists(tokenId)) _mintPBT(_msgSender(), tokenId);
		else _safeTransfer(ownerOf(tokenId), _msgSender(), tokenId, "");
	}

	/**
	 * @notice Links a list of chip to token IDs.
	 *
	 * @param chipAddresses The addresses for the chips embedded in the physical items (computed from the chip's public key).
	 * @param tokenIds The token ids to link to the chips.
	 */
	function seedChipToTokenMapping(
		address[] memory chipAddresses,
		uint256[] memory tokenIds
	) external onlyOwner {
		_seedChipToTokenMapping(chipAddresses, tokenIds);
	}

	/**
	 * @notice Updates the chip to token mapping.
	 *
	 * @param chipAddressesOld The old addresses for the chips embedded in the physical items (computed from the chip's public key).
	 * @param chipAddressesNew The new addresses for the chips embedded in the physical items (computed from the chip's public key).
	 */
	function updateChips(
		address[] calldata chipAddressesOld,
		address[] calldata chipAddressesNew
	) external onlyOwner {
		_updateChips(chipAddressesOld, chipAddressesNew);
	}

	/**
	 * @notice Updates the base token URI.
	 *
	 * @param baseTokenUri The new base token URI.
	 */
	function setBaseTokenUri(string memory baseTokenUri) external onlyOwner {
		s_baseTokenUri = baseTokenUri;
	}

	/**
	 * @notice Returns the token data for a given chip address.
	 *
	 * @param chipAddress The chip address for the token.
	 *
	 * @return The token data for the passed in address.
	 */
	function getTokenData(address chipAddress) public view returns (TokenData memory) {
		return _tokenDatas[chipAddress];
	}

	/**
	 * @notice Returns the token data for a signature from a chip.
	 *
	 * @param signatureFromChip An EIP-191 signature of (msgSender, blockhash), where blockhash is the block hash for blockNumberUsedInSig.
	 * @param blockNumberUsedInSig The block number linked to the blockhash signed in signatureFromChip. Should be a recent block number.
	 *
	 * @return The token data for the passed in signature.
	 */
	function getTokenDataForChipSignature(
		bytes calldata signatureFromChip,
		uint256 blockNumberUsedInSig
	) public view returns (TokenData memory) {
		return _getTokenDataForChipSignature(signatureFromChip, blockNumberUsedInSig);
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return s_baseTokenUri;
	}
}
