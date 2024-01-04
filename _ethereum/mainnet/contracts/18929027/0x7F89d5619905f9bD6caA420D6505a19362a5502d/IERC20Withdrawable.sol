// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IERC20Withdrawable
 * @author Amir M. Shirif
 * @notice A Telcoin Contract
 * @notice withdraw from wrapped token
 */
interface IERC20Withdrawable {
    /**
     * @dev the exit function
     * @param amount uint256 balance to be returned
     */
    function withdraw(uint256 amount) external;
}
