// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721Burnable.sol";
import "ERC721Royalty.sol";
import "AccessControl.sol";
import "Counters.sol";
import "ERC721URIStoragePB.sol";
import "Pausable.sol";
import "TokenFingeprint.sol";


contract ERC721PB
    is  ERC721,
        ERC721Enumerable,
        ERC721URIStoragePB,
        ERC721Royalty,
        Pausable,
        TokenFingerprint,
        AccessControl,
        ERC721Burnable
{
    using Counters for Counters.Counter;

    struct URIFlags
    {
        bool frozen;
        bool absolute;
    }

    bytes32 public constant URIADMIN_ROLE = keccak256("URIADMIN_ROLE");
    bytes32 public constant ROYALTY_ROLE = keccak256("ROYALTY_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");


    Counters.Counter private _tokenIdCounter;


    modifier canPause() {
        require(hasRole(PAUSER_ROLE, msg.sender), "Only Pauser role");
        _;
    }

    modifier canMint() {
        require(hasRole(MINTER_ROLE, msg.sender), "Only Minter role");
        _;
    }

    modifier canUpdateURI() {
        require(hasRole(URIADMIN_ROLE, msg.sender), "Only URI admin role");
        _;
    }

    modifier canUpdateRoyalty() {
        require(hasRole(ROYALTY_ROLE, msg.sender), "Only Royalty admin role");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address admin,
        uint256 pauseSinceBlock
        )
        ERC721(name, symbol)
        Pausable(pauseSinceBlock)
    {
        // NOTE(pb): Unnecessary
        //require(admin != address(0), "admin cannot be zero address");

        if (bytes(baseTokenURI).length > 0) {
            _setBaseURIm(baseTokenURI);
        }

        if (msg.sender != admin) {
            _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        }
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(URIADMIN_ROLE, admin);
        _grantRole(ROYALTY_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        requireNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStoragePB, ERC721Royalty) {
        super._burn(tokenId);
    }

    // Necessary override of ERC165 API

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty, AccessControl, TokenFingerprint)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Exposing Pause-able API

    function pause(uint256 sinceBlock)
        public
        canPause
    {
        _pause(sinceBlock);
    }

    function unpause()
        public
        canPause
    {
        _unpause();
    }

    // Exposing Minting API

    function safeMint(address to, string calldata uri, bool absolute, bytes32 tokenDataFingerprintSha256)
        public
        canMint
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri, absolute);
        _setFingerprint(tokenId, tokenDataFingerprintSha256);
    }

    function safeMint(address to, string calldata uri, bool absolute)
        public
        canMint
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri, absolute);
    }

    function safeMint(address to, bytes32 tokenDataFingerprintSha256)
        public
        canMint
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setFingerprint(tokenId, tokenDataFingerprintSha256);
    }

    function safeMint(address to)
        public
        canMint
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // Exposing base URI & ERC721URIStoragePB API

    function _baseURI()
        internal
        view
        virtual
        override(ERC721, ERC721URIStoragePB)
        returns (string memory)
    {
        return super._baseURI();
    }

    function baseURI()
        public
        view
        returns (string memory)
    {
        return _baseURI();
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override (ERC721, ERC721URIStoragePB)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getTokenURIFlags(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _getTokenURIFlags(tokenId);
    }

    function getTokenURIFlagsAsStruct(uint256 tokenId)
        public
        view
        returns (URIFlags memory)
    {
        uint256 flags = _getTokenURIFlags(tokenId);
        return URIFlags({
            frozen:   _isFlagSet(flags, FROZEN_BIT_INDEX),
            absolute: _isFlagSet(flags, ABSOLUTE_BIT_INDEX)
            });
    }

    function setBaseURI(string calldata baseURI_)
        public
        canUpdateURI
    {
        _setBaseURI(baseURI_);
    }

    function setTokenURI(uint256 tokenId, string calldata _tokenURI, bool absolute)
        public
        canUpdateURI
    {
        _setTokenURI(tokenId, _tokenURI, absolute);
    }

    function freezeTokenURI(uint256 tokenId)
        public
        canUpdateURI
    {
        _freezeTokenURI(tokenId);
    }

    function deleteTokenURI(uint256 tokenId)
        public
        canUpdateURI
    {
        _deleteTokenURI(tokenId, true);
    }

    // Exposing ERC721Royalty API

    function feeDenominator() public pure returns (uint96) {
        return _feeDenominator();
    }

    function setTokenRoyalty(uint256 tokenId, address recipient, uint96 fraction)
        public
        canUpdateRoyalty
    {
        _setTokenRoyalty(tokenId, recipient, fraction);
    }

    function setDefaultRoyalty(address recipient, uint96 fraction)
        public
        canUpdateRoyalty
    {
        _setDefaultRoyalty(recipient, fraction);
    }

    function deleteDefaultRoyalty()
        public
        canUpdateRoyalty
    {
        _deleteDefaultRoyalty();
    }
}
