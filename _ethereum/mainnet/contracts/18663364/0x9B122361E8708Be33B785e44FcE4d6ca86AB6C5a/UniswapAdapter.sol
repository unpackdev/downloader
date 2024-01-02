// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "./Structs.sol";
import "./OracleLibrary.sol";
import "./IUniswapV3Pool.sol";
import "./SafeCast.sol";
import "./DecimalMath.sol";

abstract contract UniswapAdapter {
  using SafeCastU256 for uint256;
  using SafeCastU160 for uint160;
  using SafeCastU56 for uint56;
  using SafeCastU32 for uint32;
  using SafeCastI56 for int56;
  using SafeCastI256 for int256;
  using DecimalMath for int256;

  function _getUniswapPrice(address asset, AssetInfo calldata assetInfo, uint32 twapPeriod)
    internal
    view
    returns (uint256)
  {
    uint256 baseAmount = 10 ** assetInfo.assetDecimals;
    uint256 factor = (18 - assetInfo.quoteTokenDecimals); // 18 decimals
    uint256 finalPrice;

    uint32[] memory secondsAgos = new uint32[](2);
    secondsAgos[0] = twapPeriod;
    secondsAgos[1] = 0;

    try IUniswapV3Pool(assetInfo.uniswapPool).observe(secondsAgos) returns (
      int56[] memory tickCumulatives, uint160[] memory
    ) {
      int24 tick = _computeTick(tickCumulatives, twapPeriod);

      int256 price = OracleLibrary.getQuoteAtTick(
        tick, baseAmount.to128(), asset, assetInfo.uniswapQuoteToken
      ).toInt();

      finalPrice = factor > 0
        ? price.upscale(factor).toUint()
        : price.downscale((-factor.toInt()).toUint()).toUint();
      return finalPrice;
    } catch {
      return finalPrice;
    }
  }

  function _computeTick(int56[] memory tickCumulatives, uint32 twapPeriod)
    internal
    pure
    returns (int24)
  {
    int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];

    int24 tick = (tickCumulativesDelta / twapPeriod.to56().toInt()).to24();

    if (tickCumulativesDelta < 0 && (tickCumulativesDelta % twapPeriod.to256().toInt() != 0)) {
      tick--;
    }
    return tick;
  }
}
