// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ERC721Tradable is ERC721Enumerable, Ownable {
    address openSeaProxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        address _openSeaProxyRegistryAddress
    ) ERC721(_name, _symbol) {
        openSeaProxyRegistryAddress = _openSeaProxyRegistryAddress;
    }

    function isApprovedForAll(address owner, address operator) override public view returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(openSeaProxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
