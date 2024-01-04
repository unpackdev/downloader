// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./FixedPoint.sol";
import "./ICirculatingMarketCapOracle.sol";


/**
 * @dev Temporary contract to convert market caps denominated in ETH
 * to market caps denominated in USD.
 */
contract CirculatingMarketCapEthToDAI {
  using FixedPoint for FixedPoint.uq112x112;
  using FixedPoint for FixedPoint.uq144x112;

  address public immutable uniswapOracle;
  address public immutable circulatingMarketCapOracle;
  address public immutable dai;

  uint32 internal constant SHORT_TWAP_MIN_TIME_ELAPSED = 20 minutes;
  uint32 internal constant SHORT_TWAP_MAX_TIME_ELAPSED = 2 days;

  constructor (
    address uniswapOracle_,
    address circulatingMarketCapOracle_,
    address dai_
  ) public {
    uniswapOracle = uniswapOracle_;
    circulatingMarketCapOracle = circulatingMarketCapOracle_;
    dai = dai_;
  }

  function getCirculatingMarketCaps(address[] calldata tokens) external view returns (uint256[] memory values) {
    uint256 len = tokens.length;
    FixedPoint.uq112x112 memory ethPriceForDai = IIndexedUniswapV2Oracle(uniswapOracle).computeAverageEthPrice(
      dai,
      SHORT_TWAP_MIN_TIME_ELAPSED,
      SHORT_TWAP_MAX_TIME_ELAPSED
    );
    values = ICirculatingMarketCapOracle(circulatingMarketCapOracle).getCirculatingMarketCaps(tokens);
    for (uint256 i = 0; i < len; i++) {
      values[i] = ethPriceForDai.mul(values[i]).decode144();
    }
  }
}


interface IIndexedUniswapV2Oracle {
  function computeAverageEthPrice(
    address token,
    uint256 minTimeElapsed,
    uint256 maxTimeElapsed
  )
    external
    view
    returns (FixedPoint.uq112x112 memory priceAverage);
}