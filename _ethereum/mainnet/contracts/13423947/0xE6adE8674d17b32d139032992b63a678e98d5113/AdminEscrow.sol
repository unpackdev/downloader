// SPDX-License-Identifier: AGPL-3.0-only

/*
    AdminEscrow.sol - SKALE Allocator
    Copyright (C) 2020-Present SKALE Labs
    @author Artem Payvin

    SKALE Allocator is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    SKALE Allocator is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with SKALE Allocator.  If not, see <https://www.gnu.org/licenses/>.
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import "./Escrow.sol";


contract AdminEscrow is Escrow {

    address public constant ADMIN = address(0);

    modifier onlyBeneficiary() override {
        require(_msgSender() == _beneficiary || _msgSender() == ADMIN, "Message sender is not a plan beneficiary");
        _;
    }

    modifier onlyActiveBeneficiaryOrVestingManager() override {
        Allocator allocator = Allocator(contractManager.getContract("Allocator"));
        if (allocator.isVestingActive(_beneficiary)) {
            require(_msgSender() == _beneficiary || _msgSender() == ADMIN, "Message sender is not beneficiary");
        } else {
            require(
                allocator.hasRole(allocator.VESTING_MANAGER_ROLE(), _msgSender()),
                "Message sender is not authorized"
            );
        }
        _;
    }
}
