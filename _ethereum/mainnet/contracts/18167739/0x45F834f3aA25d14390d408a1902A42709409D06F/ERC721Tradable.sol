// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
abstract contract ERC721Tradable is ERC721, NativeMetaTransaction, Ownable {
    string public baseTokenURI; /// @dev Base token URI used as a prefix by tokenURI() for NFT metadata_updatable = true.
    string private baseContractURI;
    
    address proxyRegistryAddress;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721(_name, _symbol) {
        proxyRegistryAddress = address(0xff7Ca10aF37178BdD056628eF42fD7F799fAc77c);
        baseTokenURI = _baseTokenURI;
        _initializeEIP712(_name);
    }

    function setBaseContractURI(
        string memory _baseContractURI
    ) public onlyOwner {
        baseContractURI = _baseContractURI;
    }

    function contractURI() public view returns (string memory) {
        return baseContractURI;
    }

    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId));
        return string(abi.encodePacked(_baseURI(), "/", Strings.toString(_tokenId), ".json"));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override(ERC721)
        public
        view
        virtual
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        // if(getChainId()==80001 || getChainId()==137) {
        //     ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        //     if (address(proxyRegistry.proxies(owner)) == operator) {
        //         return true;
        //     }
        // }
        return super.isApprovedForAll(owner, operator);
    }
}
