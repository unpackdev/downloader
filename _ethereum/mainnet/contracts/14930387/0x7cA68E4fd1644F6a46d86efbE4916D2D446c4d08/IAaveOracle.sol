// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import "./IPriceOracleGetter.sol";

/**
 * @title IAaveOracle interface
 * @notice Interface for the Aave oracle.
 **/

interface IAaveOracle is IPriceOracleGetter {
  function BASE_CURRENCY() external view returns (address); // if usd returns 0x0, if eth returns weth address
  function BASE_CURRENCY_UNIT() external view returns (uint256);

}