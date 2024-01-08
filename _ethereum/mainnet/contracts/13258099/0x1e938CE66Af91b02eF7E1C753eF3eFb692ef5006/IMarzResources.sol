// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IMarzResources {
    /**
     * Starts mining a given plot
     * Outputs one of each resource found on that plot per period
     * with maximum of CLAIMS_PER_PLOT
     */
    function mine(uint256 plotId) external;
}
