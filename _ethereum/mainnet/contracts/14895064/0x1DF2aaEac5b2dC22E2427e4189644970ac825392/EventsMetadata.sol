// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./ERC1155Metadata.sol";

import "./UintUtils.sol";

import "./OwnableInternal.sol";
import "./ERC2981Base.sol";

import "./ERC1155MetadataStorage.sol";

import "./OpenSeaCompatible.sol";

import "./EventsStorage.sol";

contract EventsMetadata is
	OwnableInternal,
	ERC2981Base,
	OpenSeaCompatible,
	IERC1155Metadata,
	IERC721Metadata
{
	using UintUtils for uint256;

	function getIndex() internal view returns (uint256 index) {
		return EventsStorage._getIndex();
	}

	function getMintState(uint256 tokenId) public view returns (MintState state) {
		return EventsStorage._getState(tokenId);
	}

	function getPrice(uint256 tokenId) public view returns (uint256 price) {
		return EventsStorage._getPrice(tokenId);
	}

	function getEdition(uint256 tokenId) internal view returns (Edition storage edition) {
		return EventsStorage._getEdition(tokenId);
	}

	// IERC721Metadata

	function name() external pure returns (string memory) {
		return "PASS Events";
	}

	function symbol() external pure returns (string memory) {
		return "PASSPARTY";
	}

	function tokenURI(uint256 tokenId) external view override returns (string memory) {
		return uri(tokenId);
	}

	// IERC1155Metadata

	function uri(uint256 tokenId) public view virtual returns (string memory) {
		ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage.layout();

		string memory tokenIdURI = l.tokenURIs[tokenId];
		string memory baseURI = l.baseURI;

		if (bytes(tokenIdURI).length > 0) {
			return tokenIdURI;
		} else {
			return baseURI;
		}
	}
}
