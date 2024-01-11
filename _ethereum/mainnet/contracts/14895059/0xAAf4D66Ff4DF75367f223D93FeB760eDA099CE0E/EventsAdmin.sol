// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableInternal.sol";
import "./ERC1155MetadataInternal.sol";
import "./ERC1155MetadataStorage.sol";

import "./ERC2981Admin.sol";

import "./OpenSeaCompatible.sol";
import "./OpenSeaProxyStorage.sol";

import "./EventsStorage.sol";

contract EventsAdmin is
	OwnableInternal,
	ERC1155MetadataInternal,
	OpenSeaCompatibleInternal,
	ERC2981Admin
{
	function setAuthorized(address target, bool allowed) external onlyOwner {
		EventsStorage._setAuthorized(target, allowed);
	}

	function setBaseURI(string memory baseURI) external onlyOwner {
		_setBaseURI(baseURI);
	}

	function setContractURI(string memory contractURI) external onlyOwner {
		_setContractURI(contractURI);
	}

	function setIndex(uint256 index) external onlyOwner {
		EventsStorage._setIndex(index);
	}

	function setLimit(uint256 tokenId, uint8 limit) external onlyOwner {
		EventsStorage._setLimit(tokenId, limit);
	}

	function setMaxCount(uint256 tokenId, uint16 maxCount) external onlyOwner {
		EventsStorage._setMaxCount(tokenId, maxCount);
	}

	function setPrice(uint256 tokenId, uint64 price) external onlyOwner {
		EventsStorage._setPrice(tokenId, price);
	}

	function setState(uint256 tokenId, MintState state) external onlyOwner {
		EventsStorage._setState(tokenId, state);
	}

	function setTokenURI(uint256 tokenId, string memory tokenURI) external onlyOwner {
		_setTokenURI(tokenId, tokenURI);
	}

	function setProxy(address proxy, bool allowed) external onlyOwner {
		EventsStorage._setProxy(proxy, allowed);
	}

	function setProxies(address os721Proxy, address os1155Proxy) external onlyOwner {
		OpenSeaProxyStorage._setProxies(os721Proxy, os1155Proxy);
	}

	function withdraw() external onlyOwner {
		payable(OwnableStorage.layout().owner).transfer(address(this).balance);
	}
}
