// SPDX-License-Identifier: MIT
// Copyright 2021 Arran Schlosberg
pragma solidity >=0.8.0 <0.9.0;

import "./BaseOpenSea.sol";
import "./OwnerPausable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";

/// @notice An ERC721 contract with common functionality:
/// - OpenSea gas-free listings
/// - OpenZeppelin Enumerable and Pausable
/// - OpenZeppelin Pausable with functions exposed to Owner only.
contract ERC721Common is BaseOpenSea, ERC721Enumerable, ERC721Pausable, OwnerPausable {
    constructor(
        string memory name,
        string memory symbol,
        address openSeaProxyRegistry
    ) ERC721(name, symbol) {
        if (openSeaProxyRegistry != address(0)) {
            BaseOpenSea._setOpenSeaRegistry(openSeaProxyRegistry);
        }
    }

    /// @notice Overrides _beforeTokenTransfer as required by inheritance.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override (ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Overrides supportsInterface as required by inheritance.
    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /// @notice Returns true if either standard isApprovedForAll() returns true
    /// or the operator is the OpenSea proxy for the owner.
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return super.isApprovedForAll(owner, operator) || BaseOpenSea.isOwnersOpenSeaProxy(owner, operator);
    }
}