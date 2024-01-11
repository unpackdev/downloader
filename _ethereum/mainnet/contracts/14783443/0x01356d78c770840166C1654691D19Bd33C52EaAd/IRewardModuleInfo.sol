/*
IRewardModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Reward module info interface
 *
 * @notice this contract defines the common interface that any reward module info
 * must implement to be compatible with the modular Pool architecture.
 */

interface IRewardModuleInfo {
    /**
     * @notice get all token metadata
     * @param module address of reward module
     * @return addresses
     * @return names
     * @return symbols
     * @return decimals
     */
    function tokens(address module)
        external
        view
        returns (
            address[] memory,
            string[] memory,
            string[] memory,
            uint8[] memory
        );

    /**
     * @notice generic function to get pending reward balances
     * @param module address of reward module
     * @param addr account address of interest for preview
     * @param shares number of shares that would be used
     * @return estimated reward balances
     */
    function rewards(
        address module,
        address addr,
        uint256 shares
    ) external view returns (uint256[] memory);
}
