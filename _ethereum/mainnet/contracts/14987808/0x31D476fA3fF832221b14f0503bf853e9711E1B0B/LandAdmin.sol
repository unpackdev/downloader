// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableInternal.sol";
import "./ERC1155MetadataInternal.sol";
import "./ERC1155MetadataStorage.sol";

import "./ERC2981Admin.sol";

import "./OpenSeaCompatible.sol";
import "./OpenSeaProxyStorage.sol";

import "./LandStorage.sol";

contract LandAdmin is
	OwnableInternal,
	ERC1155MetadataInternal,
	OpenSeaCompatibleInternal,
	ERC2981Admin
{
	// event fired when a proxy is updated
	event SetProxy(address proxy, bool enabled);

	// event fired when a signer is updated
	event SetSigner(address old, address newAddress);

	function addInventory(uint16 zoneId, uint16 count) external onlyOwner {
		Zone storage zone = LandStorage._getZone(zoneId);
		require(
			count <= zone.endIndex - zone.startIndex - zone.max - zone.count,
			"_addInventory: too much"
		);
		LandStorage._addInventory(zone, count);
	}

	function removeInventory(uint16 zoneId, uint16 count) external onlyOwner {
		Zone storage zone = LandStorage._getZone(zoneId);
		require(count <= zone.max - zone.count, "_removeInventory: too much");
		LandStorage._removeInventory(zone, count);
	}

	/**
	 * ability to add a zone.
	 * can be disabled by adding a zone with zero available inventory.
	 */
	function addZone(Zone memory zone) external onlyOwner {
		uint16 index = LandStorage._getIndex();
		Zone memory last = LandStorage._getZone(index);

		require(zone.count == 0, "_addZone: wrong count");
		require(zone.startIndex == last.endIndex, "_addZone: wrong start");
		require(zone.startIndex <= zone.endIndex, "_addZone: wrong end");
		require(zone.max <= zone.endIndex - zone.startIndex, "_addZone: wrong max");
		require(
			zone.endIndex - zone.startIndex <= last.endIndex - last.startIndex,
			"_addZone: too much"
		);

		LandStorage._addZone(zone);
	}

	function setAvatars(address avatars) external onlyOwner {
		LandStorage._setAvatars(avatars);
	}

	function setBaseURI(string memory baseURI) external onlyOwner {
		_setBaseURI(baseURI);
	}

	// can be used to effectively deny claims by setting them to already claimed
	function setClaimedAvatar(uint256 tokenId, address claimedBy) external onlyOwner {
		LandStorage._setClaimedAvatar(tokenId, claimedBy);
	}

	function setContractURI(string memory contractURI) external onlyOwner {
		_setContractURI(contractURI);
	}

	function setIndex(uint16 index) external onlyOwner {
		LandStorage._setIndex(index);
	}

	function setInventory(uint16 zoneId, uint16 maxCount) external onlyOwner {
		Zone storage zone = LandStorage._getZone(zoneId);
		require(maxCount >= zone.count, "_setInventory: invalid");
		require(maxCount <= zone.endIndex - zone.startIndex - zone.count, "_setInventory: too much");
		LandStorage._setInventory(zone, maxCount);
	}

	function setMintState(MintState mintState) external onlyOwner {
		LandStorage.layout().mintState = uint8(mintState);
	}

	function setPrice(uint64 price) external onlyOwner {
		LandStorage._setPrice(price);
	}

	function setProxy(address proxy, bool enabled) external onlyOwner {
		LandStorage._setProxy(proxy, enabled);
		emit SetProxy(proxy, enabled);
	}

	function setOSProxies(address os721Proxy, address os1155Proxy) external onlyOwner {
		OpenSeaProxyStorage._setProxies(os721Proxy, os1155Proxy);
	}

	function setSigner(address signer) external onlyOwner {
		address old = LandStorage._getSigner();
		LandStorage._setSigner(signer);
		emit SetSigner(old, signer);
	}

	function setTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
		_setTokenURI(tokenId, tokenURI);
	}

	function withdraw() external onlyOwner {
		payable(OwnableStorage.layout().owner).transfer(address(this).balance);
	}
}
