// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IVestingPool {
    /**
     * @notice Returns the amount of tokens that are currently allowed for transfer.
     */
    function getCurrentAllowance() external view returns (uint256);

    /**
     * @notice Returns the amount of tokens that are currently locked.
     */
    function getTotalTokensLocked() external view returns (uint256);

    /**
     * @notice Returns the address of vesting pool.
     */
    function getVestingPoolAddress() external view returns (address);

    /**
     * @notice Returns the address of token.
     */
    function getTokenAddress() external view returns (address);
}