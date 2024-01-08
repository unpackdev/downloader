// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";

import "./ContentMixin.sol";
import "./NativeMetaTransaction.sol";

import "./console.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract PopFungi is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bool _frozen = false;

    string _baseTokenURI;
    uint256 _collectionSize;
    uint256 _costToGerminate;

    address _proxyRegistryAddress;
    address _vaultAddress;

    constructor(
        string memory name,
        string memory symbol,
        string memory initBaseTokenURI,
        address initProxyRegistryAddress,
        address initVaultAddress,
        uint256 initCostToGerminate,
        uint256 initCollectionSize
    ) ERC721(name, symbol) {
        _baseTokenURI = initBaseTokenURI;
        _collectionSize = initCollectionSize;
        _costToGerminate = initCostToGerminate;

        _proxyRegistryAddress = initProxyRegistryAddress;
        _vaultAddress = initVaultAddress;
    }

    /**
     * PUBLIC VIEWS
     */

    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    function collectionSize() public view returns (uint) {
        return _collectionSize;
    }

    function costToGerminate() public view returns (uint) {
        return _costToGerminate;
    }

    function vaultAddress() public view returns (address) {
        return _vaultAddress;
    }

    /**
     * PUBLIC
     */

    function germinate(uint256 fungiId) public payable {
        require(okToMint(fungiId));
        _safeMint(msg.sender, fungiId);
        payable(_vaultAddress).transfer(msg.value);
    }

    /**
     * ONLY OWNER
     */

    function freeze() public onlyOwner {
        _frozen = true;
    }

    function mintTo(
        address to,
        uint256 tokenId
    ) public onlyOwner {
        require(!_frozen, "contract is frozen");
        _safeMint(to, tokenId);
    }

    function setBaseTokenURI(
        string memory newBaseTokenURI
    ) public onlyOwner {
        require(!_frozen, "contract is frozen");
        _baseTokenURI = newBaseTokenURI;
    }

    function setCollectionSize(
        uint256 newCollectionSize
    ) public onlyOwner {
        require(!_frozen, "contract is frozen");
        _collectionSize = newCollectionSize;
    }

    function setTokenPrice(
        uint256 newTokenPrice
    ) public onlyOwner {
        _costToGerminate = newTokenPrice;
    }

    function setVaultAddress(
        address newVaultAddress
    ) public onlyOwner {
        require(!_frozen, "contract is frozen");
        _vaultAddress = newVaultAddress;
    }

    function withdraw() public onlyOwner {
        payable(_vaultAddress).transfer(address(this).balance);
    }

    /**
     * PRIVATE
     */

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function okToMint(uint256 tokenId) private view returns (bool) {
        require(msg.value >= _costToGerminate, "you didn't send enough to germinate a fungi");
        require(tokenId > 0, "fungiId less than 1 is invalid");
        require(tokenId <= _collectionSize, "there aren't that many fungi available to germinate right now");
        return true;
    }

    function requiredValue(uint256 count) private view returns (uint256) {
        return count * _costToGerminate;
    }

    /**
     * OPENSEA Stuff
     */

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(_proxyRegistryAddress);
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
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}
