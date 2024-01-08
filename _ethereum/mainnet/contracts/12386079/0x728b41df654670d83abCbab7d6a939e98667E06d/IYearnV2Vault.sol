// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Interface for Yearn v2 vault.
 */
interface IYearnV2Vault {

    /**
     * @dev Gives the price for a single Vault share.
     */
    function pricePerShare() external view returns (uint256);

}