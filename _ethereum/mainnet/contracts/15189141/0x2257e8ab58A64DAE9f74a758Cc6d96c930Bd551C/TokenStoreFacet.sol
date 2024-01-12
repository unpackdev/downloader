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

import "./IERC721Metadata.sol";
import "./IDiamondFacet.sol";
import "./RoleManagerLib.sol";
import "./arteQCollectionV2Config.sol";
import "./TokenStoreInternal.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
contract TokenStoreFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
        _;
    }

    modifier onlyTokenManager() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_TOKEN_MANAGER);
        _;
    }

    // CAUTION: Don't forget to update the version when adding new functionality
    function getVersion()
      external pure override returns (string memory) {
        return "0.0.1";
    }

    function supportsInterface(bytes4 interfaceId)
      external pure override returns (bool) {
        return interfaceId == type(IDiamondFacet).interfaceId ||
               interfaceId == type(IERC721Metadata).interfaceId;
    }

    function getTokenStoreSettings()
      external view returns (string memory, string memory) {
        return TokenStoreInternal._getTokenStoreSettings();
    }

    function setTokenStoreSettings(
        string memory baseTokenURI,
        string memory defaultTokenURI
    ) external onlyAdmin {
        TokenStoreInternal._setTokenStoreSettings(
            baseTokenURI,
            defaultTokenURI
        );
    }

    function getTokenData(uint256 tokenId)
      external view returns (string memory) {
        return TokenStoreInternal._getTokenData(tokenId);
    }

    function setTokenData(
        uint256 tokenId,
        string memory data
    ) external onlyTokenManager {
        TokenStoreInternal._setTokenData(tokenId, data);
    }

    // TODO(kam): allow transfer of token id #0

    function getTokenURI(uint256 tokenId)
      public view returns (string memory) {
        return TokenStoreInternal._getTokenURI(tokenId);
    }

    function setTokenURI(
        uint256 tokenId,
        string memory tokenURI
    ) external onlyTokenManager {
        return TokenStoreInternal._setTokenURI(tokenId, tokenURI);
    }

    function ownedTokens(address account)
      external view returns (uint256[] memory tokens) {
        return TokenStoreInternal._ownedTokens(account);
    }
}
