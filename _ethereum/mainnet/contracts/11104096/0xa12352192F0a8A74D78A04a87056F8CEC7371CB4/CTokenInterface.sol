// //SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of Compound cToken
 */
interface CTokenInterface {
  /**
   * @notice Calculates the exchange rate from the underlying to the CToken
   * @return Calculated exchange rate scaled by 1e18
   */
  function exchangeRateStored() external view returns (uint256);

  function decimals() external view returns (uint256);

  function underlying() external view returns (address);
}
