// SPDX-License-Identifier: MIT

pragma solidity >0.6.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract ERC721Tradable is ERC721, Ownable {
    using HelperStrings for string;

    address proxyRegistryAddress;
    uint256 private _currentTokenCount = 0;

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) public ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /**
     * @dev calculates the next token count based on value of _currentTokenCount
     * @return uint256 for the next token count
     */
    function _getNextTokenCount() internal view returns (uint256) {
        return _currentTokenCount.add(1);
    }

    /**
     * @dev increments the value of _currentTokenCount
     */
    function _incrementTokenCount() internal {
        _currentTokenCount++;
    }

    function getLastMintedTokenCount() public view returns (uint256) {
        return _currentTokenCount;
    }

    function baseTokenURI() public virtual pure returns (string memory) {
        return "";
    }

    function tokenURI(uint256 _tokenId) override public virtual view returns (string memory) {
        return HelperStrings.strConcat(baseTokenURI(), HelperStrings.uint2str(_tokenId));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}