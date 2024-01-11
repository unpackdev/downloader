// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./OwnableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./Base64Upgradeable.sol";

import "./ILabGame.sol";

contract Metadata is OwnableUpgradeable {
	using StringsUpgradeable for uint256;
	using Base64Upgradeable for bytes;

	uint256 constant MAX_TRAITS = 16;
	uint256 constant TYPE_OFFSET = 9;

	string constant TYPE0_NAME = "Scientist";
	string constant TYPE1_NAME = "Mutant";
	string constant DESCRIPTION = "5,000 Scientists and Mutants walking around The Laboratory, producing and stealing the ultimate prize, $SERUM.";
	string constant IMAGE_WIDTH = "50";
	string constant IMAGE_HEIGHT = "50";

	struct Trait {
		string name;
		string image;
	}
	mapping(uint256 => mapping(uint256 => Trait)) traits;

	ILabGame labGame;

	function initialize() public initializer {
		__Ownable_init();
	}

	// -- EXTERNAL --

	/**
	 * Get the metadata uri for a token
	 * @param _tokenId token id
	 * @return Token metadata data URI
	 */
	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		uint256 token = labGame.getToken(_tokenId);
		return string(abi.encodePacked(
			'data:application/json;base64,',
			abi.encodePacked(
				'{"name":"', (token & 128 != 0) ? TYPE1_NAME : TYPE0_NAME, ' #', _tokenId.toString(),
				'","description":"', DESCRIPTION,
				'","image":"data:image/svg+xml;base64,', _image(token).encode(),
				'","attributes":', _attributes(token),
				'}'
			).encode()
		));
	}

	// -- INTERNAL --

	/**
	 * Create SVG from token data
	 * @param _token token data
	 * @return SVG image string for the token
	 */
	function _image(uint256 _token) internal view returns (bytes memory) {
		(uint256 start, uint256 count) = (_token & 128 != 0) ? (TYPE_OFFSET, MAX_TRAITS - TYPE_OFFSET) : (0, TYPE_OFFSET);
		bytes memory images;
		for (uint256 i; i < count; i++) {
			images = abi.encodePacked(
				images,
				'<image x="0" y="0" width="', IMAGE_WIDTH, '" height="', IMAGE_HEIGHT, '" image-rendering="pixelated" preserveAspectRatio="xMidYMid" href="data:image/png;base64,',
				traits[start + i][(_token >> (8 * i + 8)) & 0xFF].image,
				'"/>'
			);
		}
		return abi.encodePacked(
			'<svg id="LabGame-', _token.toString(), '" width="100%" height="100%" viewBox="0 0 ', IMAGE_WIDTH, ' ', IMAGE_HEIGHT, '" xmlns="http://www.w3.org/2000/svg">',
			images,
			'</svg>'
		);
	}

	/**
	 * Create attributes dictionary for token
	 * @param _token token data
	 * @return JSON string of token attributes
	 */
	function _attributes(uint256 _token) internal view returns (bytes memory) {
		string[MAX_TRAITS] memory TRAIT_NAMES = [
			"Background",
			"Skin",
			"Pants",
			"Shirt",
			"Lab Coat",
			"Shoes",
			"Hair",
			"Eyes",
			"Mouth",
			"Background",
			"Body",
			"Pants",
			"Mutated Body",
			"Eyes",
			"Mouth",
			"Shoes"
		];

		(uint256 start, uint256 count) = (_token & 128 != 0) ? (TYPE_OFFSET, MAX_TRAITS - TYPE_OFFSET) : (0, TYPE_OFFSET);
		bytes memory attributes;
		for (uint256 i; i < count; i++) {
			attributes = abi.encodePacked(
				attributes,
				'{"trait_type":"',
				TRAIT_NAMES[start + i],
				'","value":"',
				traits[start + i][(_token >> (8 * i + 8)) & 0xFF].name,
				'"},'
			);
		}
		return abi.encodePacked(
			'[', attributes,
			'{"trait_type":"Generation", "value":"', (_token & 3).toString(), '"},',
			'{"trait_type":"Type","value":"', (_token & 128 != 0) ? TYPE1_NAME : TYPE0_NAME, '"}]'
		);
	}

	// -- OWNER --
	
	/**
	 * Set trait data for layer
	 * @param _layer layer index
	 * @param _traits trait data
	 */
	function setTraits(uint256 _layer, Trait[] calldata _traits) external onlyOwner {
		for (uint256 i; i < _traits.length; i++)
			traits[_layer][i] = _traits[i];
	}
	
	/**
	 * Set trait data for layer
	 * @param _layer layer index
	 * @param _trait trait index
	 * @param _data trait data
	 */
	function setTrait(uint256 _layer, uint256 _trait, Trait calldata _data) external onlyOwner {
		traits[_layer][_trait] = _data;
	}

	/**
	 * Set the address of the game contract
	 * @param _labGame new address
	 */
	function setLabGame(address _labGame) external onlyOwner {
		labGame = ILabGame(_labGame);
	}
}