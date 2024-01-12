// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableInternal.sol";
import "./ERC1155MetadataInternal.sol";
import "./ERC1155MetadataStorage.sol";

import "./ERC2981Admin.sol";

import "./OpenSeaCompatible.sol";
import "./OpenSeaProxyStorage.sol";

import "./LandStorage.sol";
import "./LandPriceStorage.sol";
import "./LandTypes.sol";

/**
 * Administrative functions
 */
contract LandAdmin is
	OwnableInternal,
	ERC1155MetadataInternal,
	OpenSeaCompatibleInternal,
	ERC2981Admin
{
	event SetMintState(MintState mintState);

	// event fired when a proxy is updated
	event SetProxy(address proxy, bool enabled);

	// event fired when a signer is updated
	event SetSigner(address old, address newAddress);

	function addInventory(
		uint8 zoneId,
		uint8 segmentId,
		uint16 count
	) external onlyOwner {
		Zone storage zone = LandStorage._getZone(zoneId);
		Segment memory segment = LandStorage._getSegment(zone, segmentId);

		require(
			count <= segment.endIndex - segment.startIndex - segment.max - segment.count,
			"_addInventory: too much"
		);
		LandStorage._addInventory(zone, segmentId, count);
	}

	function removeInventory(
		uint8 zoneId,
		uint8 segmentId,
		uint16 count
	) external onlyOwner {
		Zone storage zone = LandStorage._getZone(zoneId);
		Segment memory segment = LandStorage._getSegment(zone, segmentId);
		require(count <= segment.max - segment.count, "_removeInventory: too much");
		LandStorage._removeInventory(zone, segmentId, count);
	}

	/**
	 * Add a zone
	 */
	function addZone(Zone memory zone) external onlyOwner {
		uint8 index = LandStorage._getZoneIndex();
		Zone memory last = LandStorage._getZone(index);

		require(LandStorage._isValidSegment(last.four, zone.one), "addZone: wrong one");
		require(LandStorage._isValidSegment(zone.one, zone.two), "addZone: wrong two");
		require(LandStorage._isValidSegment(zone.two, zone.three), "addZone: wrong three");
		require(LandStorage._isValidSegment(zone.three, zone.four), "addZone: wrong four");

		LandStorage._addZone(zone);
	}

	/**
	 * Set the metadata root for tokens
	 */
	function setBaseURI(string memory baseURI) external onlyOwner {
		_setBaseURI(baseURI);
	}

	/**
	 * set the contract metadata root
	 */
	function setContractURI(string memory contractURI) external onlyOwner {
		_setContractURI(contractURI);
	}

	/**
	 * set a discounted price for a zone
	 */
	function setDiscountPrice(uint8 zoneId, SegmentPrice memory price) external onlyOwner {
		LandPriceStorage._setDiscountPrice(zoneId, price);
	}

	function setZoneIndex(uint8 index) external onlyOwner {
		LandStorage._setZoneIndex(index);
	}

	/**
	 * set the $icons contract
	 */
	function setIcons(address icons) external onlyOwner {
		LandStorage.layout().icons = icons;
	}

	/**
	 * set the lions contract
	 */
	function setLions(address lions) external onlyOwner {
		LandStorage.layout().lions = lions;
	}

	/**
	 * add inventory to the zone by setting the maximum
	 */
	function setInventory(uint8 zoneId, SegmentCount memory newMaximums) external onlyOwner {
		Zone storage zone = LandStorage._getZone(zoneId);

		require(
			LandStorage._isValidInventory(zone.one, newMaximums.countOne),
			"setInventory: invalid one"
		);

		require(
			LandStorage._isValidInventory(zone.two, newMaximums.countTwo),
			"setInventory: invalid two"
		);

		require(
			LandStorage._isValidInventory(zone.three, newMaximums.countThree),
			"setInventory: invalid three"
		);

		require(
			LandStorage._isValidInventory(zone.four, newMaximums.countFour),
			"setInventory: invalid four"
		);

		LandStorage._setInventory(
			zone,
			newMaximums.countOne,
			newMaximums.countTwo,
			newMaximums.countThree,
			newMaximums.countFour
		);
	}

	/**
	 * set the mint state
	 */
	function setMintState(MintState mintState) external onlyOwner {
		LandStorage.layout().mintState = uint8(mintState);
		emit SetMintState(mintState);
	}

	/**
	 * set the price
	 */
	function setPrice(SegmentPrice memory price) external onlyOwner {
		LandPriceStorage._setPrice(price);
	}

	/**
	 * set an approved proxy
	 */
	function setProxy(address proxy, bool enabled) external onlyOwner {
		LandStorage._setProxy(proxy, enabled);
		emit SetProxy(proxy, enabled);
	}

	/**
	 * ability to set the opensea proxies
	 */
	function setOSProxies(address os721Proxy, address os1155Proxy) external onlyOwner {
		OpenSeaProxyStorage._setProxies(os721Proxy, os1155Proxy);
	}

	/**
	 * set the authorized signer
	 */
	function setSigner(address signer) external onlyOwner {
		address old = LandStorage._getSigner();
		LandStorage._setSigner(signer);
		emit SetSigner(old, signer);
	}

	function setTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
		_setTokenURI(tokenId, tokenURI);
	}

	/**
	 * Withdraw function
	 */
	function withdraw() external onlyOwner {
		payable(OwnableStorage.layout().owner).transfer(address(this).balance);
	}
}
