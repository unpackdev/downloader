// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Metadata.sol";
import "./ERC1155Metadata.sol";

import "./UintUtils.sol";

import "./ERC2981Base.sol";

import "./ERC1155MetadataStorage.sol";

import "./OpenSeaCompatible.sol";
import "./LandStorage.sol";
import "./LandPriceStorage.sol";
import "./LandTypes.sol";

contract LandMetadata is ERC2981Base, OpenSeaCompatible, IERC1155Metadata, IERC721Metadata {
	using UintUtils for uint256;

	// Domain Property Getters

	function getDiscountPrice(uint8 zoneId) external view returns (SegmentPrice memory price) {
		return LandPriceStorage._getDiscountPrice(zoneId);
	}

	function getDiscountPriceBySegment(uint8 zoneId, uint8 segmentId)
		external
		view
		returns (uint64 price)
	{
		return LandPriceStorage._getDiscountPrice(zoneId, segmentId);
	}

	function getMintState() external view returns (MintState state) {
		return MintState(LandStorage.layout().mintState);
	}

	function getPrice() external view returns (SegmentPrice memory price) {
		return LandPriceStorage._getPrice();
	}

	function getPriceBySegment(uint8 segmentId) external view returns (uint64 price) {
		return LandPriceStorage._getPrice(segmentId);
	}

	function getSegment(uint8 zoneId, uint8 segmentId) external view returns (Segment memory zone) {
		return LandStorage._getSegment(zoneId, segmentId);
	}

	function getZone(uint8 zoneId) public view returns (Zone memory zone) {
		return LandStorage._getZone(zoneId);
	}

	function getZoneIndex() external view returns (uint8 count) {
		return LandStorage._getZoneIndex();
	}

	// IERC721

	function totalSupply() external view returns (uint256 supply) {
		uint8 zoneCount = LandStorage._getZoneIndex();
		// Currently 3 zones
		for (uint8 i = 1; i <= zoneCount; i++) {
			Zone memory zone = getZone(i);
			supply += zone.one.count;
			supply += zone.two.count;
			supply += zone.three.count;
			supply += zone.four.count;
		}

		return supply;
	}

	// IERC721Metadata

	function name() external pure returns (string memory) {
		return "Sports Metaverse Land";
	}

	function symbol() external pure returns (string memory) {
		return "SPORTSLAND";
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
			return tokenIdURI; //3
		} else if (bytes(tokenIdURI).length > 0) {
			return string(abi.encodePacked(tokenIdURI));
		} else {
			return string(abi.encodePacked(baseURI, tokenId.toString()));
		}
	}
}
