// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IWyvernProxyRegistry.sol";


abstract contract ERC721Tradable is ERC721, Ownable {
    address internal proxyRegistry;

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address _owner, address _operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        if (address(IWyvernProxyRegistry(proxyRegistry).proxies(_owner)) == _operator) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }
}