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

import "./TokenStoreInternal.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
library TokenStoreLib {

    function _getTokenURI(uint256 tokenId)
      internal view returns (string memory) {
        return TokenStoreInternal._getTokenURI(tokenId);
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) internal {
        TokenStoreInternal._setTokenURI(tokenId, tokenURI_);
    }

    function _setTokenData(uint256 tokenId, string memory data) internal {
        TokenStoreInternal._setTokenData(tokenId, data);
    }

    function _addToRelatedTokens(address account, uint256 tokenId) internal {
        TokenStoreInternal._addToRelatedTokens(account, tokenId);
    }

    function _deleteTokenInfo(
        uint256 tokenId
    ) internal {
        TokenStoreInternal._deleteTokenInfo(tokenId);
    }
}
