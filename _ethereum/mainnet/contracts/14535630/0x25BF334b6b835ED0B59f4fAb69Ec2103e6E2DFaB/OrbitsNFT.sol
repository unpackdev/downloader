// SPDX-License-Identifier: GPL-3.0

/// @title The Orbits ERC-721 token

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./IProxyRegistry.sol";
import "./IOrbitsNFT.sol";

contract OrbitsNFT is IOrbitsNFT, Ownable, ERC721 {
    // An address who has permissions to mint Orbits
    address public minter;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // The internal orbit ID tracker
    uint256 private _currentOrbitId;

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    // token URIs
    mapping(uint256 => string) public tokenURIs;

    // is token URI locked
    mapping(uint256 => bool) public isTokenURILocked;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    constructor(
        address _minter,
        IProxyRegistry _proxyRegistry
    ) ERC721('Orbits', 'ORBITS') {
        minter = _minter;
        proxyRegistry = _proxyRegistry;
    }


    function setTokenURI(uint256 orbitId, string calldata _tokenURI) public onlyOwner {
        require(!isTokenURILocked[orbitId], "tokenURI is locked");
        tokenURIs[orbitId] = _tokenURI;
    }

    function lockTokenURI(uint256 orbitId) external {
        require(msg.sender == ownerOf(orbitId), "non-owner cannot lock");
        isTokenURILocked[orbitId] = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenURIs[tokenId];
    }
    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Mint an Orbit to the minter
     * @dev Call _mintTo with the to address(es).
     */
    function mint(string calldata _tokenURI) public override onlyMinter returns (uint256) {
        return _mintTo(minter, _currentOrbitId++, _tokenURI);
    }
    /**
     * @notice Burn an Orbit.
     */
    function burn(uint256 nounId) public override onlyMinter {
        _burn(nounId);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;
    }
    /**
     * @notice Mint an Orbit with `orbitId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 orbitId, string calldata _tokenURI) internal returns (uint256) {
        tokenURIs[orbitId] = _tokenURI;
        _mint(to, orbitId);
        return orbitId;
    }
}