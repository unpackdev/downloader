// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

/**
 * @title Asymetrix Protocol V2 Wrapped ETH (WETH) Interface
 * @author Asymetrix Protocol Inc Team
 * @notice An interface defines the functions for interacting with the Wrapped ETH (WETH) contract.
 */
interface IWETH {
    /**
     * @notice Withdraws WETH and receives ETH.
     * @param wethAmount The amount of WETH to burn, represented in wei.
     */
    function withdraw(uint wethAmount) external;
}
