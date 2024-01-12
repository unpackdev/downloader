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
import "./ReserveManagerInternal.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
contract ReserveManagerFacet is IDiamondFacet {

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

    // TODO(kam): remove this function.
    function initReserveManager() external onlyAdmin {
        ReserveManagerInternal._initReserveManager();
    }

    function getReservationSettings()
      external view returns (bool, bool, uint256, uint256) {
        return ReserveManagerInternal._getReservationSettings();
    }

    // TODO(kam): correct the function name.
    function setReservationAllowed(
        bool reservationAllowed,
        bool reservationAllowedWithoutWhitelisting,
        uint256 reservationFeeWei,
        uint256 reservePriceWeiPerToken
    ) external onlyAdmin {
        ReserveManagerInternal._setReservationAllowed(
            reservationAllowed,
            reservationAllowedWithoutWhitelisting,
            reservationFeeWei,
            reservePriceWeiPerToken
        );
    }

    function reserveForMe(
        uint256 nrOfTokens,
        string memory paymentMethodName
    ) external payable {
        ReserveManagerInternal._reserveForAccount(
            msg.sender,
            nrOfTokens,
            paymentMethodName
        );
    }

    // This is always allowed
    function reserveForAccounts(
        address[] memory accounts,
        uint256[] memory nrOfTokensArray
    ) external onlyTokenManager {
        ReserveManagerInternal._reserveForAccounts(
            accounts,
            nrOfTokensArray
        );
    }
}
