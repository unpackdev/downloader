// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


import "./IERC20Ext.sol";

/**
* Use different logics to compute price oracle
* If token is not supported, it should return 0 as conversion rate
*/
interface ILiquidationPriceOracleBase {

  /**
   * @dev Return list of min amounts that expected to get in return
   *  when liquidating corresponding list of src tokens
   * @param liquidator address of the liquidator
   * @param tokenIns list of src tokens
   * @param amountIns list of src amounts
   * @param tokenOut dest token
   * @param hint hint for getting conversion rates
   * @return minAmountOut min expected amount for the token out
   */
  function getExpectedReturn(
    address liquidator,
    IERC20Ext[] calldata tokenIns,
    uint256[] calldata amountIns,
    IERC20Ext tokenOut,
    bytes calldata hint
  ) external view returns (uint256 minAmountOut);
}
