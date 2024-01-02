// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IChainlinkAggregator.sol";
import "./ICLSynchronicityPriceAdapter.sol";
import "./IrETH.sol";

/**
 * @title CLrETHSynchronicityPriceAdapter
 * @author BGD Labs
 * @notice Price adapter to calculate price of (rETH / USD) pair by using
 * @notice Chainlink Data Feed for (ETH / USD) pair and (rETH / ETH) ratio.
 */
contract CLrETHSynchronicityPriceAdapter is ICLSynchronicityPriceAdapter {
  /**
   * @notice Price feed for (ETH / USD) pair
   */
  IChainlinkAggregator public immutable ETH_TO_USD;

  /**
   * @notice rETH token contract
   */
  IrETH public immutable RETH;

  /**
   * @notice Number of decimals for the rETH / ETH ratio
   */
  uint8 public constant RATIO_DECIMALS = 18;

  string private _description;

  /**
   * @param ethToUSDAggregatorAddress the address of ETH / USD feed
   * @param rETHAddress the address of rETH token
   * @param pairDescription description
   */
  constructor(
    address ethToUSDAggregatorAddress,
    address rETHAddress,
    string memory pairDescription
  ) {
    ETH_TO_USD = IChainlinkAggregator(ethToUSDAggregatorAddress);
    RETH = IrETH(rETHAddress);

    _description = pairDescription;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function description() external view returns (string memory) {
    return _description;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function decimals() external pure returns (uint8) {
    return 8;
  }

  /// @inheritdoc ICLSynchronicityPriceAdapter
  function latestAnswer() public view virtual override returns (int256) {
    int256 ethToUsdPrice = ETH_TO_USD.latestAnswer();
    int256 ethToREthRatio = int256(RETH.getExchangeRate());

    if (ethToUsdPrice <= 0) {
      return 0;
    }

    return ((ethToUsdPrice * ethToREthRatio) / int256(10 ** RATIO_DECIMALS));
  }
}
