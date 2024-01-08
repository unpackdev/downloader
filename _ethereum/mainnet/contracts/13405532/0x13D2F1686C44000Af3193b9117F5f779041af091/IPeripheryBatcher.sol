// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.5;
pragma abicoder v2;

/**
 * @title IPeripheryBatcher
 * @notice A batcher to resolve vault deposits/withdrawals in batches 
 * @dev Provides an interface for PeripheryBatcher
 */
interface IPeripheryBatcher {
  /**
    * @notice Stores the deposits for future batching via periphery
    * @param amountIn Value of token to be deposited 
    * @param vaultAddress address of vault to deposit into
    */
  function depositFunds(uint amountIn, address vaultAddress) external;

  /**
    * @notice Stores the deposits for future batching via periphery
    * @param amountOut Value of token to be deposited 
    * @param vaultAddress address of vault to deposit into
    */
  function withdrawFunds(uint amountOut, address vaultAddress) external;

  /**
    * @notice Performs deposits on the periphery for the supplied users in batch
    * @param vaultAddress address of vault to deposit inton
    * @param users array of users whose deposits must be resolved
    * @param slippage percentage of slippage to be applied to the batch deposit's swap
    */
  function batchDepositPeriphery(address vaultAddress, address[] memory users, uint slippage) external;
  /**
    * @notice To set a token address as the deposit token for a vault
    * @param vaultAddress address of vault to deposit inton
    * @param token address of token which is to be deposited into vault
    */
  function setVaultTokenAddress(address vaultAddress, address token) external;
}