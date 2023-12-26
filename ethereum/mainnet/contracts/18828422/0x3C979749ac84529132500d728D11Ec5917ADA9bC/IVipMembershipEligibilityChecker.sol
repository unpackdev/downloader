// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IVipMembershipEligibilityChecker {
    /**
     * @dev Function to check, whether the user is eligible for VIP Membership.
     */
    function getUserVipEligibility(address user) external view returns (bool);
}
