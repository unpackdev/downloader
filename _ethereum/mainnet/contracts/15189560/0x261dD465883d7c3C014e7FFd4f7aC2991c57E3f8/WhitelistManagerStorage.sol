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

/// @author Kam Amini <kam@arteq.io>
///
/// @notice Use at your own risk. Just got the basic
///         idea from: https://github.com/solidstate-network/solidstate-solidity
library WhitelistManagerStorage {

    struct Layout {
        bool whitelistingAllowed;
        uint256 whitelistingFeeWei;
        uint256 whitelistingPriceWeiPerToken;
        uint256 maxNrOfWhitelistedTokensPerAccount;
        mapping(address => uint256) whitelistEntries;
    }

    // Storage Slot: 71e0208316fc901686daf4f3337ab9e0c066ba9c3c2727e9209867af42765c4e
    bytes32 internal constant STORAGE_SLOT =
        keccak256("arteq-io.collections.v2.whitelist-manager.storage");

    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        /* solhint-disable no-inline-assembly */
        assembly {
            s.slot := slot
        }
        /* solhint-enable no-inline-assembly */
    }
}
