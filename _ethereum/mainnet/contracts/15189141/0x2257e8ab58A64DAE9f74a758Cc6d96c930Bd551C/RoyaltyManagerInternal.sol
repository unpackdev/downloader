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
import "./RoyaltyManagerStorage.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
library RoyaltyManagerInternal {

    event TokenRoyaltyInfoChanged(uint256 tokenId, address royaltyWallet, uint256 royaltyPercentage);
    event TokenRoyaltyExempt(uint256 tokenId, bool exempt);

    function _getDefaultRoyaltySettings() internal view returns (address, uint256) {
        return (__s().defaultRoyaltyWallet, __s().defaultRoyaltyPercentage);
    }

    // Either set address to zero or set percentage to zero to disable
    // default royalties. Still, royalties set per token work.
    function _setDefaultRoyaltySettings(
        address newDefaultRoyaltyWallet,
        uint256 newDefaultRoyaltyPercentage
    ) internal {
        __s().defaultRoyaltyWallet = newDefaultRoyaltyWallet;
        require(
            newDefaultRoyaltyPercentage >= 0 &&
            newDefaultRoyaltyPercentage <= 100,
            "ROMI:WP"
        );
        __s().defaultRoyaltyPercentage = newDefaultRoyaltyPercentage;
    }

    function _getTokenRoyaltyInfo(uint256 tokenId)
      internal view returns (address, uint256, bool) {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        return (
            __s().tokenRoyalties[tokenId].royaltyWallet,
            __s().tokenRoyalties[tokenId].royaltyPercentage,
            __s().tokenRoyalties[tokenId].exempt
        );
    }

    function _setTokenRoyaltyInfo(
        uint256 tokenId,
        address royaltyWallet,
        uint256 royaltyPercentage
    ) internal {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        require(royaltyPercentage >= 0 && royaltyPercentage <= 100, "ROMI:WP");
        __s().tokenRoyalties[tokenId].royaltyWallet = royaltyWallet;
        __s().tokenRoyalties[tokenId].royaltyPercentage = royaltyPercentage;
        __s().tokenRoyalties[tokenId].exempt = false;
        emit TokenRoyaltyInfoChanged(tokenId, royaltyWallet, royaltyPercentage);
    }

    function _exemptTokenRoyalty(uint256 tokenId, bool exempt) internal {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        __s().tokenRoyalties[tokenId].exempt = exempt;
        emit TokenRoyaltyExempt(tokenId, exempt);
    }

    function _getRoyaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) internal view returns (address, uint256) {
        require(ERC721Lib._exists(tokenId), "ROMI:NET");
        RoyaltyManagerStorage.TokenRoyaltyInfo memory tokenRoyaltyInfo = __s().tokenRoyalties[tokenId];
        if (tokenRoyaltyInfo.exempt) {
            return (address(0), 0);
        }
        address royaltyWallet = tokenRoyaltyInfo.royaltyWallet;
        uint256 royaltyPercentage = tokenRoyaltyInfo.royaltyPercentage;
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            royaltyWallet = __s().defaultRoyaltyWallet;
            royaltyPercentage = __s().defaultRoyaltyPercentage;
        }
        if (royaltyWallet == address(0) || royaltyPercentage == 0) {
            return (address(0), 0);
        }
        uint256 royalty = (salePrice * royaltyPercentage) / 100;
        return (royaltyWallet, royalty);
    }

    function __s() private pure returns (RoyaltyManagerStorage.Layout storage) {
        return RoyaltyManagerStorage.layout();
    }
}
