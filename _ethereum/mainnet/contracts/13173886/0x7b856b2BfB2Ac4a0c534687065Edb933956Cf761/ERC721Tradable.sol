// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.6;

import "./ERC721Enumerable.sol";

import "./IWyvernProxyRegistry.sol";
import "./Ownable.sol";


abstract contract ERC721Tradable is ERC721Enumerable, Ownable {
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

    function getTokensOfOwner(address _owner)
        external
        view
        returns (uint16[] memory _tokensIDs)
    {
        uint16 _tokenCount = uint16(balanceOf(_owner));
        if (_tokenCount == 0) {
            return new uint16[](0);
        }

        _tokensIDs = new uint16[](_tokenCount);
        for (uint16 _index; _index < _tokenCount; _index++) {
            _tokensIDs[_index] = uint16(tokenOfOwnerByIndex(_owner, _index));
        }
    }

    // to protect
    function renounceOwnership() public override onlyOwner {}

}