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

import "./ERC721Internal.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
library ERC721Lib {

    function _setName(string memory name) internal {
        ERC721Internal._setName(name);
    }

    function _setSymbol(string memory symbol) internal {
        ERC721Internal._setSymbol(symbol);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return ERC721Internal._exists(tokenId);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        return ERC721Internal._ownerOf(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        ERC721Internal._burn(tokenId);
    }

    function _safeMint(address account, uint256 tokenId) internal {
        // TODO(kam): We don't have any safe mint in ERC721Internal
        ERC721Internal._mint(account, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        ERC721Internal._transfer(from, to, tokenId);
    }
}
