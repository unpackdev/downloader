// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnableDelegateProxy {}

contract OpenSeaProxyRegistry {
	mapping(address => OwnableDelegateProxy) public proxies;
}

library LibOpenSeaProxy {
	function _isApprovedForAll(
		address registry,
		address _owner,
		address operator
	) internal view returns (bool) {
		OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(registry);
		return
			address(proxyRegistry) != address(0) && address(proxyRegistry.proxies(_owner)) == operator;
	}
}
