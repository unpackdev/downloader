// SPDX-License-Identifier: Unlicense
// Developed by EasyChain (easychain.tech)
//
pragma solidity ^0.8.4;

import "./ERC721Burnable.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

abstract contract ERC721Whitelisted is ERC721Burnable {
    address private proxyRegistryAddress;

    constructor(
        string memory name,
        string memory symbol,
        address proxyAddress
    ) ERC721(name, symbol) {
        proxyRegistryAddress = proxyAddress;
    }

    //
    // Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
    // https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/ERC721Tradable.sol
    //
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC721.isApprovedForAll(_owner, _operator);
    }
}