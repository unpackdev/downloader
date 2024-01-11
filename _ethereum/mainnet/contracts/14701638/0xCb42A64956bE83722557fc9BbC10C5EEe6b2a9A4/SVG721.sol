// give the contract some SVG Code
// output an NFT URI with this SVG code
// Storing all the NFT metadata on-chain

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721URIStorageUpgradeable.sol";
import "./base64.sol";
import "./BaseNFT.sol";
import "./ISVG721.sol";
import "./ITokenDescriptor.sol";

/// @title SVG721
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common functions.
/// @dev Protonaut ERC721 contract. Inherits abstract BaseNFT
contract SVG721 is ISVG721, ERC721URIStorageUpgradeable, BaseNFT {
	using CountersUpgradeable for CountersUpgradeable.Counter;

	/// @dev initialize upgradeable contract
	function initialize(
		address __tokenDescriptor,
		string memory _defaultName,
		string memory _defaultDescription
	) public virtual initializer {
		__ERC721_init('Protonaut', 'PRN');
		__Ownable_init();
		setTokenDescriptor(__tokenDescriptor);

		defaultName = _defaultName;
		defaultDescription = _defaultDescription;

		// default values => hardcoded. fixed for mainnet.
		defaultIndices = [0, 3];

		// total available feature
		numFeatures = 4;

		// do not change order.
		featureNames[0] = 'Attack';
		featureNames[1] = 'Defense';
		featureNames[2] = 'Health';
		featureNames[3] = 'Magic';

		// feature(tokenId,"Health") of a newly minted = defaultValue. see attributes.
		defaultValue = 1;
	}

	// STATE METHODS

	/// @notice see ISVG721.mint
	function mint(address to)
		public
		override
		onlyAdmin
		returns (uint256 tokenId)
	{
		tokenIds.increment();
		tokenId = tokenIds.current();
		_safeMint(to, tokenId);
		return tokenId;
	}

	/// @notice override. see BaseNFT.metadata
	function metadata(uint256 tokenId)
		public
		view
		override(BaseNFT, ISVG721)
		returns (Metadata memory m)
	{
		return super.metadata(tokenId);
	}

	/// @notice see BaseNFT.getAttributes
	function getAttributes(uint256 tokenId)
		public
		view
		virtual
		override(BaseNFT, ISVG721)
		returns (string[] memory featureNamesArr, uint256[] memory valuesArr)
	{
		return super.getAttributes(tokenId);
	}

	/// @notice if tokenDescriptor, generate SVG + metadata + attributes.
	/// returns defaultIndices, defaultMetadata if not set externally
	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(
			_exists(tokenId),
			'ERC721URIStorage: URI query for nonexistent token'
		);
		if (tokenDescriptor == address(0)) return super.tokenURI(tokenId);
		else {
			if (
				_tokenIndices[tokenId][0] == 0 && _tokenIndices[tokenId][1] == 0
			)
				return
					ITokenDescriptor(tokenDescriptor).tokenURI(
						tokenId,
						defaultIndices
					);
			return
				ITokenDescriptor(tokenDescriptor).tokenURI(
					tokenId,
					_tokenIndices[tokenId]
				);
		}
	}

	/// @notice publicly available exists.
	/// @dev warning, use this instead of ownerOf.
	function exists(uint256 tokenId)
		public
		view
		override(BaseNFT, ISVG721)
		returns (bool)
	{
		return _exists(tokenId);
	}

	/// @notice view IBaseNFT.setMetadata
	function setMetadata(Metadata memory m, uint256 tokenId)
		public
		override(BaseNFT, ISVG721)
		onlyAdmin
	{
		return super.setMetadata(m, tokenId);
	}

	/// @notice view IBaseNFT.updateFeatureValueBatch
	function updateFeatureValueBatch(
		uint256[] memory _tokenIds,
		string[] memory _featureNames,
		uint256[] memory _newValues
	) public virtual override(BaseNFT, ISVG721) onlyUpdateAdmin {
		super.updateFeatureValueBatch(_tokenIds, _featureNames, _newValues);
	}

	/**
		@dev space reserved
	 */
	uint256[49] private __gap;
}
