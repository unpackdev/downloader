// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IFeeManager
 * @author StakeEase
 * @notice Interface for FeeManager contract for StakeEase.
 */

interface IFeeManager {
    /**
     * @notice Function to fetch the amount of fee.
     * @param txVolume Volume of transaction in ETH.
     * @return fee to be deducted in ETH.
     */
    function getFee(uint256 txVolume) external view returns (uint256);
}
