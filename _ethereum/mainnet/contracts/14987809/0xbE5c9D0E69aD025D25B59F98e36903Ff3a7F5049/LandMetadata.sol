// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./ERC1155Metadata.sol";

import "./UintUtils.sol";
import "./Base64.sol";

import "./ERC2981Base.sol";

import "./ERC1155MetadataStorage.sol";

import "./OpenSeaCompatible.sol";
import "./LandStorage.sol";

// encode the data on-chain and return using the offchain token standard, but also retunre using standard interfaces?

contract LandMetadata is ERC2981Base, OpenSeaCompatible, IERC1155Metadata, IERC721Metadata {
	using UintUtils for uint256;

	function getClaimedAvatar(uint256 tokenId) external view returns (address claimedBy) {
		return LandStorage._getClaimedAvatar(tokenId);
	}

	function getIndex() external view returns (uint16 index) {
		return LandStorage._getIndex();
	}

	function getMintState() external view returns (MintState state) {
		return MintState(LandStorage.layout().mintState);
	}

	function getPrice() external view returns (uint256 price) {
		return LandStorage.layout().price;
	}

	function getZone(uint16 index) external view returns (Zone memory zone) {
		return LandStorage._getZone(index);
	}

	// IERC721

	function totalSupply() external view returns (uint256 supply) {
		supply += LandStorage._getZone(0).count;
		for (uint16 i = 1; i < LandStorage._getIndex() + 1; i++) {
			Zone memory zone = LandStorage._getZone(i);
			supply += zone.count;
		}
		return supply;
	}

	// IERC721Metadata

	function name() external pure returns (string memory) {
		return "Frogland Computational Toadex";
	}

	function symbol() external pure returns (string memory) {
		return "LSD-420";
	}

	function tokenURI(uint256 tokenId) external view override returns (string memory) {
		return uri(tokenId);
	}

	// IERC1155Metadata

	function uri(uint256 tokenId) public view override returns (string memory) {
		ERC1155MetadataStorage.Layout storage l = ERC1155MetadataStorage.layout();

		string memory tokenIdURI = l.tokenURIs[tokenId];
		string memory baseURI = l.baseURI;

		if (bytes(baseURI).length == 0) {
			return tokenIdURI;
		} else if (bytes(tokenIdURI).length > 0) {
			return string(abi.encodePacked(tokenIdURI));
		} else {
			return string(abi.encodePacked(baseURI, tokenId.toString()));
		}
	}
}
