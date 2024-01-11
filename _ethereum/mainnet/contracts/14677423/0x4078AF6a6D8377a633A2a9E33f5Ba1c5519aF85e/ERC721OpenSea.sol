// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ERC721OpenSea is Ownable, ERC721Enumerable {
	string private _contractURI;
	string private _tokenBaseURI;
	address proxyRegistryAddress;

	constructor() {}

	function setProxyRegistryAddress(address proxyAddress) external onlyOwner {
		proxyRegistryAddress = proxyAddress;
	}

	function isApprovedForAll(address owner, address operator)
		public
		view
		override
		returns (bool)
	{
		ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
		if (address(proxyRegistry.proxies(owner)) == operator) {
			return true;
		}

		return super.isApprovedForAll(owner, operator);
	}

	function setBaseURI(string calldata URI) external onlyOwner {
		_tokenBaseURI = URI;
	}

	function _baseURI() internal view override(ERC721) returns (string memory) {
		return _tokenBaseURI;
	}
}
