// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.5;
pragma abicoder v2;

import "./IERC20Metadata.sol";

/**
 * @title IPeriphery
 * @notice A middle layer between user and Aastra Vault to process transactions
 * @dev Provides an interface for Periphery
 */
interface IPeriphery {
  /**
    * @notice Calls IVault's deposit method and sends all money back to 
    * user after transactions
    * @param amount Value of tokem to be deposited 
    * @param token address of token to be deposited 
    * @param slippage Value in percentage of allowed slippage (2 digit precision)
    * @param strategy address of strategy to get vault from
    */
  function vaultDeposit(uint256 amount, address token, uint256 slippage, address strategy) external;
  /**
    * @notice Calls vault's withdraw function in exchange for shares
    * and transfers processed token0 value to msg.sender
    * @param shares Value of shares in exhange for which tokens are withdrawn
    * @param strategy address of strategy to get vault from
    * @param direction direction to perform swap in
    */
  function vaultWithdraw(uint256 shares, address strategy, bool direction) external;
}