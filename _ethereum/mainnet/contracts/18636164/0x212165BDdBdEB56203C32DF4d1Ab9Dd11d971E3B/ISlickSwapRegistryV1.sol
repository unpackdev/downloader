// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;
pragma abicoder v2;

/**
 * This interface defines accessors to be present on the Registry contract.
 */
interface ISlickSwapRegistryV1 {
  /**
   * Returns the address that should receive fees from trading operations.
   */
  function getTradingFeeRecipient() external view returns (address);

  /**
   * Returns the address that should receive fees from withdrawal operations.
   */
  function getWithdrawalFeeRecipient() external view returns (address);

  /**
   * Returns the address of the most up-to-date SlickSwap implementation contract.
   */
  function getNextImplementation() external view returns (address);

  /**
   * Reverts unless the provided address is allowed to trade.
   */
  function verifyTrader(address sender) external;
}
