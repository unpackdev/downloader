// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "./AggregatorV3Interface.sol";

import "./IEthUsdOracle.sol";

import "./SafeDecimalMath.sol";

contract ChainlinkEthUsdConsumer is IEthUsdOracle {
  using SafeDecimalMath for uint256;

  AggregatorV3Interface public immutable priceFeed;

  /**
   * @notice Construct a new price consumer
   * @dev Mainnet ETH/USD: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
      Source: https://docs.chain.link/docs/ethereum-addresses#config
   */
  constructor(address aggregatorAddress) {
    priceFeed = AggregatorV3Interface(aggregatorAddress);
  }

  /// @inheritdoc IEthUsdOracle
  function consult()
    external
    view
    override(IEthUsdOracle)
    returns (uint256 price)
  {
    (, int256 _price, , , ) = priceFeed.latestRoundData();
    require(_price >= 0, "ChainlinkConsumer/StrangeOracle");
    return (price = uint256(_price).decimalToPreciseDecimal());
  }

  /**
   * @notice Retrieves decimals of price feed
   * @dev (18 for ETH-USD by default, scaled up)
   */
  function getDecimals() external pure returns (uint8 decimals) {
    return (decimals = 27);
  }
}
