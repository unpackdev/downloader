// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./BaseNFT.sol";

/// @title ISVG721 - Interface
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common functions.
/// @dev Used in Tunnels, SVG721 and L2_SVG721
interface ISVG721 {
	/// @notice updates feature values in batches
	/// @param tokenId array of ids of tokens to update
	/// @param featureName names of features
	/// @param newValue updated value in uint256
	function updateFeatureValueBatch(
		uint256[] memory tokenId,
		string[] memory featureName,
		uint256[] memory newValue
	) external;

	/// @notice get name, desc, etc
	/// @param tokenId id of token to query for
	function metadata(uint256 tokenId)
		external
		view
		returns (IBaseNFT.Metadata memory m);

	/// @notice get attributes for token. Sent in attributes array.
	/// @param tokenId query for token id
	function getAttributes(uint256 tokenId)
		external
		view
		returns (string[] memory featureNames, uint256[] memory values);

	/// @notice publicly available notice
	function exists(uint256 tokenId) external view returns (bool);

	/// @notice set base metadata
	/// @param m see IBaseNFT.Metadata
	/// @param tokenId id of token to set for
	/// @dev should not be available to all. only Admin or Owner.
	function setMetadata(IBaseNFT.Metadata memory m, uint256 tokenId) external;

	/// @notice mint in incremental order
	/// @param to address to send to.
	/// @dev only admin
	function mint(address to) external returns (uint256);
}
