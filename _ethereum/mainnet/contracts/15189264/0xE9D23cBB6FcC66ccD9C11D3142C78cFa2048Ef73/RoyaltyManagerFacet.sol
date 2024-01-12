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

import "./IERC2981.sol";
import "./IDiamondFacet.sol";
import "./RoleManagerLib.sol";
import "./arteQCollectionV2Config.sol";
import "./RoyaltyManagerInternal.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
contract RoyaltyManagerFacet is IDiamondFacet {

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
               interfaceId == type(IERC2981).interfaceId;
    }

    function getDefaultRoyaltySettings() external view returns (address, uint256) {
        return RoyaltyManagerInternal._getDefaultRoyaltySettings();
    }

    // Either set address to zero or set percentage to zero to disable
    // default royalties. Still, royalties set per token work.
    function setDefaultRoyaltySettings(
        address newDefaultRoyaltyWallet,
        uint256 newDefaultRoyaltyPercentage
    ) external onlyAdmin {
        RoyaltyManagerInternal._setDefaultRoyaltySettings(
            newDefaultRoyaltyWallet,
            newDefaultRoyaltyPercentage
        );
    }

    function getTokenRoyaltyInfo(uint256 tokenId)
      external view returns (address, uint256, bool) {
        return RoyaltyManagerInternal._getTokenRoyaltyInfo(tokenId);
    }

    function setTokenRoyaltyInfo(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    ) external onlyTokenManager {
        RoyaltyManagerInternal._setTokenRoyaltyInfo(
            tokenId,
            royaltyWallet,
            royaltyPercentage
        );
    }

    function exemptTokenRoyalty(uint256 tokenId, bool exempt) external onlyTokenManager {
        RoyaltyManagerInternal._exemptTokenRoyalty(tokenId, exempt);
    }

    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address, uint256) {
        return RoyaltyManagerInternal._getRoyaltyInfo(tokenId, salePrice);
    }
}
