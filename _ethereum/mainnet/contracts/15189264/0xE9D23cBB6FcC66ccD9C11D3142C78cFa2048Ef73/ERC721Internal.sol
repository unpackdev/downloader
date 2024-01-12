/*
 * This file is part of the contracts written for artèQ Investment Fund (https://github.com/arteq-io/contracts).
 * Copyright (c) 2022 artèQ (https://arteq.io)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
// SPDX-License-Identifier: GNU General Public License v3.0

pragma solidity 0.8.1;

import "./TokenStoreLib.sol";
import "./MinterLib.sol";
import "./ReserveManagerLib.sol";
import "./ERC721Storage.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
library ERC721Internal {

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function _setERC721Settings(
        string memory name_,
        string memory symbol_
    ) internal {
        _setName(name_);
        _setSymbol(symbol_);
        if (!_exists(0)) {
            MinterLib._justMintTo(address(this));
            ReserveManagerLib._initReserveManager();
        }
    }

    function _getName() internal view returns (string memory) {
        return __s().name;
    }

    function _setName(string memory name) internal {
        __s().name = name;
    }

    function _getSymbol() internal view returns (string memory) {
        return __s().symbol;
    }

    function _setSymbol(string memory symbol) internal {
        __s().symbol = symbol;
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        require(owner != address(0), "ERC721I:ZA");
        return __s().balances[owner];
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        address owner = __s().owners[tokenId];
        require(owner != address(0), "ERC721I:NET");
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return __s().owners[tokenId] != address(0);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721I:MZA");
        require(!_exists(tokenId), "ERC721I:TAM");
        __s().balances[to] += 1;
        __s().owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
        TokenStoreLib._addToRelatedTokens(to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = _ownerOf(tokenId);
        // Clear approvals
        delete __s().tokenApprovals[tokenId];
        __s().balances[owner] -= 1;
        delete __s().owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        require(_ownerOf(tokenId) == from, "ERC721I:IO");
        require(to != address(0), "ERC721I:ZA");
        _unsafeTransfer(from, to, tokenId);
    }

    function _transferFromMe(
        address to,
        uint256 tokenId
    ) internal {
        require(_ownerOf(tokenId) == address(this), "ERC721I:IO");
        require(to != address(0), "ERC721I:ZA");
        _unsafeTransfer(address(this), to, tokenId);
    }

    function _unsafeTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        // Clear approvals from the previous owner
        delete __s().tokenApprovals[tokenId];
        __s().balances[from] -= 1;
        __s().balances[to] += 1;
        __s().owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
        TokenStoreLib._addToRelatedTokens(to, tokenId);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        require(_ownerOf(tokenId) != address(0), "ERC721I:NET");
        return __s().tokenApprovals[tokenId];
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return __s().operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        address owner = _ownerOf(tokenId);
        return (
            spender == owner ||
            __s().operatorApprovals[owner][spender] ||
            __s().tokenApprovals[tokenId] == spender
        );
    }

    function _approve(address to, uint256 tokenId) internal {
        __s().tokenApprovals[tokenId] = to;
        emit Approval(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal {
        require(owner != operator, "ERC721I:ATC");
        __s().operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function __s() private pure returns (ERC721Storage.Layout storage) {
        return ERC721Storage.layout();
    }
}
