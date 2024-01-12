// SPDX-License-Identifier: AGPL-3.0-only

/*
    IAllocator.sol - SKALE Allocator
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
pragma experimental ABIEncoderV2;

interface IAllocator {

    enum TimeUnit {
        DAY,
        MONTH,
        YEAR
    }

    enum BeneficiaryStatus {
        UNKNOWN,
        CONFIRMED,
        ACTIVE,
        TERMINATED
    }

    struct Plan {
        uint256 totalVestingDuration; // months
        uint256 vestingCliff; // months
        TimeUnit vestingIntervalTimeUnit;
        uint256 vestingInterval; // amount of days/months/years
        bool isDelegationAllowed;
        bool isTerminatable;
    }

    struct Beneficiary {
        BeneficiaryStatus status;
        uint256 planId;
        uint256 startMonth;
        uint256 fullAmount;
        uint256 amountAfterLockup;
        address requestedAddress;
    }

    event PlanCreated(
        uint256 id
    );

    event VersionUpdated(
        string oldVersion,
        string newVersion
    );

    function startVesting(address beneficiary) external;
    function addPlan(
        uint256 vestingCliff, // months
        uint256 totalVestingDuration, // months
        TimeUnit vestingIntervalTimeUnit, // 0 - day 1 - month 2 - year
        uint256 vestingInterval, // months or days or years
        bool canDelegate, // can beneficiary delegate all un-vested tokens
        bool isTerminatable
    ) external;
    function connectBeneficiaryToPlan(
        address beneficiary,
        uint256 planId,
        uint256 startMonth,
        uint256 fullAmount,
        uint256 lockupAmount
    ) external;
    function stopVesting(address beneficiary) external;
    function setVersion(string calldata newVersion) external;
    function changeBeneficiaryAddress(address newBeneficiaryAddress) external;
    function confirmBeneficiaryAddress(address oldBeneficiaryAddress) external;
    function getStartMonth(address beneficiary) external view returns (uint);
    function getFinishVestingTime(address beneficiary) external view returns (uint);
    function getVestingCliffInMonth(address beneficiary) external view returns (uint);
    function isVestingActive(address beneficiary) external view returns (bool);
    function isBeneficiaryRegistered(address beneficiary) external view returns (bool);
    function isDelegationAllowed(address beneficiary) external view returns (bool);
    function getFullAmount(address beneficiary) external view returns (uint);
    function getEscrowAddress(address beneficiary) external view returns (address);
    function getLockupPeriodEndTimestamp(address beneficiary) external view returns (uint);
    function getTimeOfNextVest(address beneficiary) external view returns (uint);
    function getPlan(uint256 planId) external view returns (Plan memory);
    function getBeneficiaryPlanParams(address beneficiary) external view returns (Beneficiary memory);
    function calculateVestedAmount(address wallet) external view returns (uint256 vestedAmount);
}
