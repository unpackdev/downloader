// SPDX-License-Identifier: AGPL-3.0-only

/*
    IEscrow.sol - SKALE Allocator
    Copyright (C) 2020-Present SKALE Labs
    @author Artem Payvin
    @author Dmytro Stebaiev

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

pragma solidity >=0.8.11 <0.9.0;

interface IEscrow {
    function reinitialize(address beneficiary) external;
    function initialize(address contractManagerAddress, address beneficiary) external;
    function changeBeneficiaryAddress(address beneficiary) external;
    function retrieve() external;
    function retrieveAfterTermination(address destination) external;
    function delegate(
        uint256 validatorId,
        uint256 amount,
        uint256 delegationPeriod,
        string calldata info
    ) external;
    function requestUndelegation(uint256 delegationId) external;
    function cancelPendingDelegation(uint delegationId) external;
    function withdrawBounty(uint256 validatorId, address to) external;
    function cancelVesting(uint256 vestedAmount) external;
}
