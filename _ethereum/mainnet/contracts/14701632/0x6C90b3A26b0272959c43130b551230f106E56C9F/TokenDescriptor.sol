// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./base64.sol";

import "./ISVG721.sol";
import "./ITokenDescriptor.sol";
import "./AccessControlUpgradeable.sol";

import "./Strings.sol";

/// @title TokenDescriptor
/// @author CulturalSurround64<CulturalSurround64@gmail.com>(https://github.com/SurroundingArt64/)
/// @notice Describes common functions for TokenDescriptor
/// @dev Query the json token data from the SVG721 contract.
contract TokenDescriptor is ITokenDescriptor, AccessControlUpgradeable {
	using Strings for uint256;

	ISVG721 public SVG721;
	event SVG721Set(address indexed _SVG721);

	mapping(uint256 => string) public svgSprites;
	uint256 public numberOfSprites;

	function initialize() public initializer {
		__Ownable_init();
	}

	/// @param _SVG721 address of Svg721 contract
	function setSVG721(address _SVG721) external onlyOwner {
		SVG721 = ISVG721(_SVG721);
		emit SVG721Set(_SVG721);
	}

	/// @param _numberOfSprites number of sprites
	function setSVGSprites(uint256 _numberOfSprites) external onlyAdmin {
		numberOfSprites = _numberOfSprites;
	}

	/// @param _index index of sprite
	/// @param _sprite svg sprite part
	function setSVGSprite(uint256 _index, string memory _sprite)
		external
		onlyAdmin
	{
		svgSprites[_index] = _sprite;
	}

	// VIEW FUNCTIONS
	/// @param tokenId id of the token to query for
	/// @param indices indices to query for
	function tokenURI(uint256 tokenId, uint256[2] memory indices)
		external
		view
		override
		returns (string memory)
	{
		IBaseNFT.Metadata memory m = SVG721.metadata(tokenId);
		string memory baseURL = 'data:application/json;base64,';
		return
			string(
				abi.encodePacked(
					baseURL,
					Base64.encode(
						bytes(
							abi.encodePacked(
								'{"name": "',
								m.name,
								' #',
								tokenId.toString(),
								'",',
								'"description": "',
								m.description,
								'",',
								'"attributes": ',
								attributes(tokenId),
								',',
								'"image": "',
								imageURI(tokenId, indices),
								'"}'
							)
						)
					)
				)
			);
	}

	/// @param indices indices to query for
	/// @dev independent of tokenId but kept in as first arg for consistency
	function imageURI(uint256, uint256[2] memory indices)
		public
		view
		virtual
		returns (string memory image)
	{
		bytes memory b;
		for (uint256 i = indices[0]; i < indices[1]; i++) {
			// concatenate to return string with abi encode
			b = abi.encodePacked(b, svgSprites[i]);
		}
		if (b.length > 0) b = abi.encodePacked(b, '</svg>');
		return
			string(
				abi.encodePacked('data:image/svg+xml;base64,', Base64.encode(b))
			);
	}

	/// @param tokenId id of the token to query for
	/// @dev returns a string of attributes in Opensea Standard format
	function attributes(uint256 tokenId)
		public
		view
		returns (string memory returnAttributes)
	{
		bytes memory b = abi.encodePacked('[');
		(string[] memory featureNames, uint256[] memory values) = SVG721
			.getAttributes(tokenId);
		for (uint256 index = 0; index < featureNames.length; index++) {
			b = abi.encodePacked(
				b,
				'{"trait_type": "',
				featureNames[index],
				'",',
				'"value": "',
				values[index].toString(),
				'","display_type": "number"}'
			);
			if (index != featureNames.length - 1) {
				b = abi.encodePacked(b, ',');
			}
		}
		b = abi.encodePacked(b, ']');
		returnAttributes = string(b);
	}
}
