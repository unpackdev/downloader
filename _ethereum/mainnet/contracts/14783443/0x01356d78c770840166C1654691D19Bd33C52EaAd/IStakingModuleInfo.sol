/*
IStakingModuleInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Staking module info interface
 *
 * @notice this contract defines the common interface that any staking module info
 * must implement to be compatible with the modular Pool architecture.
 */
interface IStakingModuleInfo {
    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of staking module
     * @return address
     * @return name
     * @return symbol
     * @return decimals
     */
    function token(address module)
        external
        view
        returns (
            address,
            string memory,
            string memory,
            uint8
        );

    /**
     * @notice quote the share value for an amount of tokens
     * @param module address of staking module
     * @param addr account address of interest
     * @param amount number of tokens. if zero, return entire share balance
     * @return number of shares
     */
    function shares(
        address module,
        address addr,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @return current shares per token
     */
    function sharesPerToken(address module) external view returns (uint256);
}
