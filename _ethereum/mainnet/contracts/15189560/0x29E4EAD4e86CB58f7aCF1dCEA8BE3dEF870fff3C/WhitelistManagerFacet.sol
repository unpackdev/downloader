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
import "./WhitelistManagerInternal.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
contract WhitelistManagerFacet is IDiamondFacet {

    modifier onlyAdmin() {
        RoleManagerLib._checkRole(arteQCollectionV2Config.ROLE_ADMIN);
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

    function getWhitelistingSettings()
      external view returns (bool, uint256, uint256, uint256) {
        return WhitelistManagerInternal._getWhitelistingSettings();
    }

    function setWhitelistingSettings(
        bool whitelistingAllowed,
        uint256 whitelistingFeeWei,
        uint256 whitelistingPriceWeiPerToken,
        uint256 maxNrOfWhitelistedTokensPerAccount
    ) external onlyAdmin {
        WhitelistManagerInternal._setWhitelistingSettings(
            whitelistingAllowed,
            whitelistingFeeWei,
            whitelistingPriceWeiPerToken,
            maxNrOfWhitelistedTokensPerAccount
        );
    }

    // Send 0 for nrOfTokens to de-list the address
    function whitelistMe(
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) external payable {
        WhitelistManagerInternal._whitelistMe(
            nrOfTokens,
            paymentMethodName
        );
    }

    // Send 0 for nrOfTokens to de-list an address
    function whitelistAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) external onlyAdmin {
        WhitelistManagerInternal._whitelistAccounts(
            accounts,
            nrOfTokensArray
        );
    }

    function getWhitelistEntry(address account) external view returns (uint256) {
        return WhitelistManagerInternal._getWhitelistEntry(account);
    }
}
