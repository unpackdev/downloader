// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./CountersUpgradeable.sol";
import "./AccessControlWithUpdater.sol";
import "./IBaseNFT.sol";

/// @title BaseNFT
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common functions.
/// @dev Base ERC721 contract for l1 and l2 SVG721
abstract contract BaseNFT is AccessControlWithUpdater, IBaseNFT {
	using CountersUpgradeable for CountersUpgradeable.Counter;

	CountersUpgradeable.Counter public tokenIds;

	/// @notice total features(attributes in Opensea) of the NFT.
	uint256 public numFeatures;

	/// @dev when querying the token descriptor(for tokenURI) if indices are not set default ones are used. defaults to [0,3]
	uint256[2] public defaultIndices;

	/// @notice names of features(attributes in Opensea) for an index
	mapping(uint256 => string) public featureNames;
	/// @notice values of features(attributes in Opensea) for an index
	mapping(uint256 => mapping(string => uint256)) public values;

	/// @notice default value of all features. defaults to 1. check initialize.
	uint256 public defaultValue;

	/// @notice saved metadata for a tokenId. Returns default name and description if not set.
	mapping(uint256 => Metadata) internal _metadata;

	/// @notice query indices for image. Used to generate parts of SVG. defaults to defaultIndices
	mapping(uint256 => uint256[2]) internal _tokenIndices;

	/// @notice address of tokenDescriptor which generates and stores the SVG and tokenURI for Protonaut.
	address public tokenDescriptor;

	/// @notice default name in metadata
	string public defaultName;

	/// @notice default description in metadata
	string public defaultDescription;

	event SetNumFeatures(uint256 numFeatures);
	event UpdateFeatures(
		uint256 indexed tokenId,
		string featureName,
		uint256 oldValue,
		uint256 newValue
	);
	event SetTokenDescriptor(address tokenDescriptor);
	event SetFeatureName(uint256 index, bytes32 name);
	event SetTokenIndices(uint256 indexed tokenId, uint256 start, uint256 end);

	/// @param __tokenDescriptor address
	function setTokenDescriptor(address __tokenDescriptor)
		public
		override
		onlyAdmin
	{
		tokenDescriptor = __tokenDescriptor;
		emit SetTokenDescriptor(tokenDescriptor);
	}

	/// @param _defaultName string
	/// @param _defaultDescription string
	function setDefaults(
		string memory _defaultName,
		string memory _defaultDescription
	) public override onlyAdmin {
		defaultName = _defaultName;
		defaultDescription = _defaultDescription;
	}

	/// @param _numFeatures number
	function setNumFeatures(uint256 _numFeatures) external override onlyAdmin {
		numFeatures = _numFeatures;
		emit SetNumFeatures(numFeatures);
	}

	/// @param indices number[]
	/// @param _featureNames string[]
	/// @notice update name of attribute
	function setFeatureNameBatch(
		uint256[] memory indices,
		string[] memory _featureNames
	) external override onlyAdmin {
		require(indices.length == _featureNames.length, 'Length mismatch');
		for (uint256 index = 0; index < _featureNames.length; index++) {
			require(
				indices[index] < numFeatures,
				'Index should be less than numFeatures'
			);
			featureNames[indices[index]] = _featureNames[index];
			emit SetFeatureName(
				indices[index],
				keccak256(bytes(_featureNames[index]))
			);
		}
	}

	/// @param tokenId id of the token
	/// @param indices query indices for TokenDescriptor
	function setTokenIndices(uint256 tokenId, uint256[2] memory indices)
		public
		override
		onlyUpdateAdmin
	{
		require(exists(tokenId), 'Query for non-existent token');
		_tokenIndices[tokenId] = indices;
		emit SetTokenIndices(tokenId, indices[0], indices[1]);
	}

	/// @param tokenId number
	/// @notice returns base metadata, name, desc. Returns default if none exist.
	function metadata(uint256 tokenId)
		public
		view
		virtual
		override
		returns (Metadata memory m)
	{
		require(exists(tokenId), 'Query for non-existent token');
		m = _metadata[tokenId];
		if (bytes(m.name).length > 0) {
			return m;
		} else {
			return Metadata(defaultName, defaultDescription);
		}
	}

	// VIEW
	/// @notice total minted tokens.
	/// @dev warning doesn't take in account of burnt tokens as burn is disabled. Also, doesn't check locked in L1Tunnel.
	function totalSupply() public view returns (uint256) {
		return tokenIds.current();
	}

	/// @notice get attributes(features)
	/// @param tokenId id of the token
	function getAttributes(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string[] memory featureNamesArr, uint256[] memory valuesArr)
	{
		require(exists(tokenId), 'Query for non-existent token');
		featureNamesArr = new string[](numFeatures);
		valuesArr = new uint256[](numFeatures);

		for (uint256 i = 0; i < numFeatures; i++) {
			featureNamesArr[i] = featureNames[i];
			valuesArr[i] = values[tokenId][featureNamesArr[i]];
			if (valuesArr[i] == 0) {
				valuesArr[i] = defaultValue;
			}
		}
	}

	/// @param m Metadata
	/// @param tokenId id of the token
	function setMetadata(Metadata memory m, uint256 tokenId)
		public
		virtual
		override
		onlyAdmin
	{
		require(exists(tokenId), 'Query for non-existent token');
		_metadata[tokenId] = m;
	}

	///	@param _tokenIds tokenIds to update for
	///	@param _featureNames name of feature to update for
	///	@param _newValues new value for update
	function updateFeatureValueBatch(
		uint256[] memory _tokenIds,
		string[] memory _featureNames,
		uint256[] memory _newValues
	) public virtual override onlyUpdateAdmin {
		for (uint256 index = 0; index < _tokenIds.length; index++) {
			require(exists(_tokenIds[index]), 'Query for non-existent token');
			uint256 oldValue = values[_tokenIds[index]][_featureNames[index]];

			values[_tokenIds[index]][_featureNames[index]] = _newValues[index];

			emit UpdateFeatures(
				_tokenIds[index],
				_featureNames[index],
				oldValue,
				_newValues[index]
			);
		}
	}

	/// @notice get feature value for a feature name like feature(1,"Health")
	/// @param tokenId id of the token
	/// @param featureName name of feature
	function feature(uint256 tokenId, string memory featureName)
		external
		view
		returns (uint256)
	{
		require(exists(tokenId), 'Query for non-existent token');
		if (values[tokenId][featureName] == 0) {
			return defaultValue;
		}
		return values[tokenId][featureName];
	}

	/// @param _indices number[]
	function setDefaultIndices(uint256[2] memory _indices) external onlyAdmin {
		defaultIndices[0] = _indices[0];
		defaultIndices[1] = _indices[1];
	}

	/// @param _value number. default to 1 in initializer.
	function setDefaultValuesForFeatures(uint256 _value) public onlyAdmin {
		defaultValue = _value;
	}

	/// @param tokenId id of token
	/// @notice need to override in 721. Requires `ERC721._exists`
	function exists(uint256 tokenId)
		public
		view
		virtual
		override
		returns (bool);

	/**
		@dev space reserved for inheritance
	 */
	uint256[49] private __gap;
}
