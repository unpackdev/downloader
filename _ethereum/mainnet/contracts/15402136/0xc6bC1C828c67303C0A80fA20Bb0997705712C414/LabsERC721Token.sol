// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: Labs

import "./ERC721Creator.sol";

/**
 * ERC721Creator with additional functions for ecosystem support
 */

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract LabsERC721Token is ERC721Creator  {
    address private _proxyRegistryAddress;

    constructor(string memory name, string memory symbol, address proxyRegistryAddress) ERC721Creator(name, symbol) {
        _proxyRegistryAddress = proxyRegistryAddress;
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _tokenCount;
    }

    /**
     * @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (_proxyRegistryAddress != address(0)) {
	        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
	        if (address(proxyRegistry.proxies(owner)) == operator) {
	            return true;
	        }
		}

        return super.isApprovedForAll(owner, operator);
    }    
}
