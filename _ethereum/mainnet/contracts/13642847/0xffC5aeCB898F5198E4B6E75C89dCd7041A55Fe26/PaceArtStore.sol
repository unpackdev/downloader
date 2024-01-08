// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;
pragma abicoder v2;

import "./ERC721Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC721.sol";
import "./SafeMath.sol";
import "./Strings.sol";

import "./LibPart.sol";
import "./RoyaltiesV2Impl.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
    mapping(address => bool) public contracts;
}

/**
 * @title ERC721Tradable
 * ERC721Tradable - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract PaceArtStore is RoyaltiesV2Impl, ERC721Upgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    address exchangeAddress;
    address proxyRegistryAddress;
    uint256 private _currentTokenId = 0;
    string private _extendedTokenURI;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        address _proxyRegistryAddress,
        address _exchangeAddress
    ) external initializer {
        __Ownable_init();
        __ERC721_init(_name, _symbol);
        proxyRegistryAddress = _proxyRegistryAddress;
        _extendedTokenURI = _tokenURI;
        exchangeAddress = _exchangeAddress;

        transferOwnership(tx.origin);
    }
 
    function mintTo(address _to, LibPart.Part memory _royalty) public returns(uint) {
        require(
            ProxyRegistry(proxyRegistryAddress).contracts(_msgSender()) || 
            _msgSender() == owner(), 
            "ERC721Tradable::sender is not owner or approved!"
        );
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _saveRoyalties(newTokenId, _royalty);
        _incrementTokenId();
        return newTokenId;
    }

    function singleTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) external returns(uint) {
        if (_exists(_tokenId)) {
            address owner = ownerOf(_tokenId);
            require(owner == _from, "ERC721Tradable::Token ID not belong to user!");
            require(isApprovedForAll(owner, _msgSender()), "ERC721Tradable::sender is not approved!");
            _transfer(_from, _to, _tokenId);
        }

        return _tokenId;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() private view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() private {
        _currentTokenId++;
    }

    function baseTokenURI() virtual public view returns (string memory) {
        return _extendedTokenURI;
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }


    function modifyExtendedURI(string memory extendedTokenURI_) external onlyOwner {
        _extendedTokenURI = extendedTokenURI_;
    }

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
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
}
