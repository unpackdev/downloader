// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./Counters.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Kn0wbot is
    ContextMixin,
    NativeMetaTransaction,
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Pausable,
    Ownable
{
    using Counters for Counters.Counter;

    address public proxyRegistryAddress;
    string public baseURI =
        "ipfs://QmYyiYyvA5k7RCWPny6LE2zaFNLa9dYMh1hse3CQT6pS7Y/";

    // This is a SHA 256 hash of the URI (ipfs_dir_uri) of the IPFS directory that contains metadata files for all 10k tokens.
    // Each token's metadata will reside in the file named the same as that token's tokenId.
    // Once all tokens have been minted, setBaseURI(ipfs_dir_uri) will be executed.
    // As a result, tokenURI() will return the correct and pre-determined metadata for any token, proven using this hash.
    string public hashedRevealedBaseURI =
        "4189ebbe70ae8278307e2e6fd3c1a1a272018c3b9dc6f003d2849c33461f598a";

    Counters.Counter private _tokenIdCounter;

    constructor(address _proxyRegistryAddress) ERC721("Kn0wbot", "UUM") {
        proxyRegistryAddress = _proxyRegistryAddress;
        _initializeEIP712("Kn0wbot");
    }

    function contractURI() public view returns (string memory) {
        return "ipfs://QmZfrNGe9yiggGymNMCsGtEuUFMyYaQNsFEHvr1wasXmKV/0";
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory revealedBaseURI) public onlyOwner {
        baseURI = revealedBaseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to) public payable {
        _safeMint(to, _tokenIdCounter.current());
        _tokenIdCounter.increment();
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
    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

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
}
