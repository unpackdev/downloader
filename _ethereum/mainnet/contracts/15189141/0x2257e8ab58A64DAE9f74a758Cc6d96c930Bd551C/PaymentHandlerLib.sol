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

import "./PaymentHandlerInternal.sol";

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk
library PaymentHandlerLib {

    function _handlePayment(
        uint256 nrOfItems1, uint256 priceWeiPerItem1,
        uint256 nrOfItems2, uint256 priceWeiPerItem2,
        string memory paymentMethodName
    ) internal {
        PaymentHandlerInternal._handlePayment(
            nrOfItems1, priceWeiPerItem1,
            nrOfItems2, priceWeiPerItem2,
            paymentMethodName
        );
    }
}
