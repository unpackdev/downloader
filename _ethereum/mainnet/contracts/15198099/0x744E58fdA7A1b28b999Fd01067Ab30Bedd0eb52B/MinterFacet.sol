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

import "./IDiamondFacet.sol";
import "./RoleManagerLib.sol";
import "./arteQCollectionV2Config.sol";
import "./MinterInternal.sol";

contract MinterFacet is IDiamondFacet {

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
        return interfaceId == type(IDiamondFacet).interfaceId;
    }

    function getMintSettings() external view returns (bool, bool, uint256, uint256, uint256) {
        return MinterInternal._getMintSettings();
    }

    function setMintSettings(
        bool publicMinting,
        bool directMintingAllowed,
        uint256 mintFeeWei,
        uint256 mintPriceWeiPerToken,
        uint256 maxTokenId
    ) external onlyAdmin {
        MinterInternal._setMintSettings(
            publicMinting,
            directMintingAllowed,
            mintFeeWei,
            mintPriceWeiPerToken,
            maxTokenId
        );
    }

    function preMint(uint256 nrOfTokens) external onlyTokenManager {
        MinterInternal._preMint(nrOfTokens);
    }

    function mint(
        string[] memory uris,
        string[] memory datas,
        address[] memory royaltyWallets,
        uint256[] memory royaltyPercentages,
        string memory paymentMethodName
    ) external payable {
        (bool publicMinting,,,,)  = MinterInternal._getMintSettings();
        require(publicMinting, "M:NPM");
        MinterInternal._mint(
            msg.sender,
            uris,
            datas,
            royaltyWallets,
            royaltyPercentages,
            true,
            paymentMethodName
        );
    }

    function mintTo(
        address owner,
        string[] memory uris,
        string[] memory datas,
        address[] memory royaltyWallets,
        uint256[] memory royaltyPercentages
    ) external onlyTokenManager {
        MinterInternal._mint(
            owner,
            uris,
            datas,
            royaltyWallets,
            royaltyPercentages,
            false,
            ""
        );
    }

    function updateTokens(
        uint256[] memory tokenIds,
        string[] memory uris,
        string[] memory datas
    ) external onlyTokenManager {
        MinterInternal._updateTokens(
            tokenIds,
            uris,
            datas
        );
    }

    function burn(uint256 tokenId) external payable onlyTokenManager {
        MinterInternal._burn(tokenId);
    }
}
