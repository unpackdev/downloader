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

import "./ERC721Lib.sol";
import "./TokenStoreStorage.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
library TokenStoreInternal {

    event TokenURIChange(uint256 tokenId, string tokenURI);
    event TokenDataChange(uint256 tokenId, string data);

    // TODO(kam): allow transfer of token id #0

    function _getTokenStoreSettings() internal view returns (string memory, string memory) {
        return (__s().baseTokenURI, __s().defaultTokenURI);
    }

    function _setTokenStoreSettings(
        string memory baseTokenURI,
        string memory defaultTokenURI
    ) internal {
        __s().baseTokenURI = baseTokenURI;
        __s().defaultTokenURI = defaultTokenURI;
    }

    function _getTokenURI(uint256 tokenId)
      internal view returns (string memory) {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        string memory vTokenURI = __s().tokenInfos[tokenId].uri;
        if (bytes(vTokenURI).length == 0) {
            return __s().defaultTokenURI;
        }
        if (bytes(__s().baseTokenURI).length == 0) {
            return vTokenURI;
        }
        return string(abi.encodePacked(__s().baseTokenURI, vTokenURI));
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI_
    ) internal {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        __s().tokenInfos[tokenId].uri = tokenURI_;
        emit TokenURIChange(tokenId, tokenURI_);
    }

    function _getTokenData(uint256 tokenId)
      internal view returns (string memory) {
        require(ERC721Lib._exists(tokenId), "TSI:NET");
        return __s().tokenInfos[tokenId].data;
    }

    function _setTokenData(
        uint256 tokenId,
        string memory data
    ) internal {
        require(ERC721Lib._exists(tokenId), "TSF:NET");
        __s().tokenInfos[tokenId].data = data;
        emit TokenDataChange(tokenId, data);
    }

    function _getRelatedTokens(address account) internal view returns (uint256[] memory) {
        return __s().relatedTokens[account];
    }

    function _addToRelatedTokens(address account, uint256 tokenId) internal {
        __s().relatedTokens[account].push(tokenId);
    }

    function _ownedTokens(address account)
      internal view returns (uint256[] memory) {
        uint256 length = 0;
        if (account != address(0)) {
            for (uint256 i = 0; i < _getRelatedTokens(account).length; i++) {
                uint256 tokenId = _getRelatedTokens(account)[i];
                if (ERC721Lib._exists(tokenId) && ERC721Lib._ownerOf(tokenId) == account) {
                    length += 1;
                }
            }
        }
        uint256[] memory tokens = new uint256[](length);
        if (account != address(0)) {
            uint256 index = 0;
            for (uint256 i = 0; i < _getRelatedTokens(account).length; i++) {
                uint256 tokenId = _getRelatedTokens(account)[i];
                if (ERC721Lib._exists(tokenId) && ERC721Lib._ownerOf(tokenId) == account) {
                    tokens[index] = tokenId;
                    index += 1;
                }
            }
        }
        return tokens;
    }

    function _deleteTokenInfo(
        uint256 tokenId
    ) internal {
        if (bytes(__s().tokenInfos[tokenId].uri).length != 0) {
            delete __s().tokenInfos[tokenId];
        }
    }

    function __s() private pure returns (TokenStoreStorage.Layout storage) {
        return TokenStoreStorage.layout();
    }
}
