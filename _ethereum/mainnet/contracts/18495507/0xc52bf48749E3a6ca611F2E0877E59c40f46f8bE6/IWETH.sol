// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";

/**
 * @title Wrapped Ether (WETH) Interface
 * @dev This interface defines the functions and events for interacting with the Wrapped Ether (WETH) contract.
 */
interface IWETH is IERC20 {
    /**
     * @dev Emitted when Ether is deposited and WETH is minted.
     * @param dst The address that received the WETH tokens.
     * @param wad The amount of Ether deposited, represented in wei.
     */
    event Deposit(address indexed dst, uint wad);

    /**
     * @dev Emitted when WETH is burned and Ether is withdrawn.
     * @param src The address that initiated the withdrawal.
     * @param wad The amount of WETH burned, represented in wei.
     */
    event Withdrawal(address indexed src, uint wad);

    /**
     * @dev Deposits Ether to mint WETH tokens.
     * @notice This function is payable, and the amount of Ether sent will be converted to WETH.
     */
    function deposit() external payable;

    /**
     * @dev Withdraws WETH and receives Ether.
     * @param wad The amount of WETH to burn, represented in wei.
     */
    function withdraw(uint wad) external;
}
