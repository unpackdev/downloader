// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is
    ContextMixin,
    ERC721Enumerable,
    NativeMetaTransaction,
    ERC721URIStorage,
    ERC721Burnable,
    Ownable
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    address proxyRegistryAddress;

    event TokenURIUpdated(uint256 indexed _id, string _value);

    constructor(
        string memory _name,
        string memory _symbol,
        address _proxyRegistryAddress
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712(_name);
    }  

    /**
     * @dev Safely mints a token to an address with a tokenURI.
     * @param to address of the future owner of the token
     * @param metadataURI full URI to token metadata
     */
    function safeMint(address to, string memory metadataURI)
        public onlyOwner
    {
        uint256 newTokenId = _tokenIdCounter.current();
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, metadataURI);
        _tokenIdCounter.increment();
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI)
        public
        onlyOwner
    {
        _setTokenURI(tokenId, _tokenURI);
    }

    function updateTokenURI(uint256 tokenId, string memory newTokenURI) 
        public 
    {
        address holder = ERC721.ownerOf(tokenId);
        require(
                _msgSender() == holder,
                "ERC721Tradable: caller is not the owner of this token"
            );
        _setTokenURI(tokenId, newTokenURI);
        emit TokenURIUpdated(tokenId, newTokenURI);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        view
        override
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
