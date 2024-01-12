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
import "./PaymentHandlerInternal.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
contract PaymentHandlerFacet is IDiamondFacet {

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

    function getPaymentSettings() external view returns (address, address) {
        return PaymentHandlerInternal._getPaymentSettings();
    }

    function setPaymentSettings(
        address wethAddress,
        address payoutAddress
    ) external onlyAdmin {
        PaymentHandlerInternal._setPaymentSettings(
            wethAddress,
            payoutAddress
        );
    }

    function getERC20PaymentMethods() external view returns (string[] memory) {
        return PaymentHandlerInternal._getERC20PaymentMethods();
    }

    function getERC20PaymentMethodInfo(
        string memory paymentMethodName
    ) external view returns (address, address, bool) {
        return PaymentHandlerInternal._getERC20PaymentMethodInfo(paymentMethodName);
    }

    function addOrUpdateERC20PaymentMethod(
        string memory paymentMethodName,
        address addr,
        address wethPair
    ) external onlyAdmin {
        PaymentHandlerInternal._addOrUpdateERC20PaymentMethod(
            paymentMethodName,
            addr,
            wethPair
        );
    }

    function enableERC20TokenPayment(
        string memory paymentMethodName,
        bool enabled
    ) external onlyAdmin {
        PaymentHandlerInternal._enableERC20TokenPayment(
            paymentMethodName,
            enabled
        );
    }

    function transferTo(
        string memory paymentMethodName,
        address to,
        uint256 amount,
        string memory data
    ) external onlyAdmin {
        PaymentHandlerInternal._transferTo(
            paymentMethodName,
            to,
            amount,
            data
        );
    }
}
