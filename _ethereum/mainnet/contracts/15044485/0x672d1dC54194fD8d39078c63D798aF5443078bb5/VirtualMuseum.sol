// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC721Upgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ERC2981Upgradeable.sol";
import "./ERC721URIStorageUpgradeable.sol";
import "./CountersUpgradeable.sol";

contract VirtualMuseum is Initializable, ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable, ERC2981Upgradeable, ERC721URIStorageUpgradeable {
    CountersUpgradeable.Counter private _tokenIdCounter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC721_init("VirtualMuseum", "VM");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _setDefaultRoyalty(owner(), 1000);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function safeMint(address to, string memory uri)
        public
        onlyOwner
    {
        uint256 tokenId = CountersUpgradeable.current(_tokenIdCounter);
        CountersUpgradeable.increment(_tokenIdCounter);
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        external
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}