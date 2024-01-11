// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title IBaseNFT - Interface
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common functions.
/// @dev Used in BaseNFT, SVG721 and L2_SVG721
abstract contract IBaseNFT {
	/** 
		@notice Stores Metadata for the NFT
		@dev Stored in mapping of tokenId => Metadata. Defaults to defaultMetadata.
	 */
	struct Metadata {
		string name;
		string description;
	}

	/** 
		@notice tokenURI is fetched from token descriptor contract
		@dev This is used to generate tokenURI on the fly
	 	@param __tokenDescriptor address of token descriptor contract
	*/
	function setTokenDescriptor(address __tokenDescriptor) public virtual;

	/** 
		@notice Sets default metadata name and description.
		@param _defaultName default name field
		@param _defaultDescription default description field
	*/
	function setDefaults(
		string memory _defaultName,
		string memory _defaultDescription
	) public virtual;

	/**
		@notice Set number of features
		@param _numFeatures total features available
	*/
	function setNumFeatures(uint256 _numFeatures) external virtual;

	/**
		@notice set feature names for idx
		@dev this should set after deployment and shouldn't be changes unless required or more are added.
		@param indices index
		@param _featureNames name of feature
	 */
	function setFeatureNameBatch(
		uint256[] memory indices,
		string[] memory _featureNames
	) external virtual;

	/**
		@notice values provided to tokenURI to get image data by SVG contract
		@dev token index to query. If Image is at index 0 to 3, indices will be [0,3]
		@dev Image data is too big to be stored in single transaction. So, multiple are required.

		@param tokenId token id for which to set
		@param indices Values to query.
	 */
	function setTokenIndices(uint256 tokenId, uint256[2] memory indices)
		public
		virtual;

	/**
		@notice query the metadata for a tokenId. Returns name and symbol

		@param tokenId token id to query for
		@return m Metadata {name and description}
	*/
	function metadata(uint256 tokenId)
		public
		view
		virtual
		returns (Metadata memory m);

	/**
		@notice query the metadata for a tokenId. Returns name and symbol

		@param tokenId token id to query for
		@return featureNamesArr list of features
		@return valuesArr list of values for a given feature
	*/
	function getAttributes(uint256 tokenId)
		public
		view
		virtual
		returns (string[] memory featureNamesArr, uint256[] memory valuesArr);

	function setMetadata(Metadata memory m, uint256 tokenId) public virtual;

	/**
		@notice update feature value

		@param _tokenIds tokenIds to update for
		@param _featureNames name of feature to update for
		@param _newValues new value for update 
	 */
	function updateFeatureValueBatch(
		uint256[] memory _tokenIds,
		string[] memory _featureNames,
		uint256[] memory _newValues
	) public virtual;

	/**
		@notice query the existence for a tokenId
		
		@param tokenId token id to query for
		@return bool true if exists
	*/
	function exists(uint256 tokenId) public view virtual returns (bool);

	/**
		@dev space reserved
	 */
	uint256[49] private __gap;
}
