// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FixedPoint96.sol";
import "./FullMath.sol";
import "./PoolAddress.sol";
import "./IERC20Metadata.sol";
import "./IV3TwapUtilities.sol";

contract V3TwapUtilities is IV3TwapUtilities, Ownable {
  uint32 constant INTERVAL = 10 minutes;

  function getV3Pool(
    address _v3Factory,
    address _t0,
    address _t1,
    uint24 _poolFee
  ) external pure override returns (address) {
    (address _token0, address _token1) = _t0 < _t1 ? (_t0, _t1) : (_t1, _t0);
    PoolAddress.PoolKey memory _key = PoolAddress.PoolKey({
      token0: _token0,
      token1: _token1,
      fee: _poolFee
    });
    return PoolAddress.computeAddress(_v3Factory, _key);
  }

  function getPoolPriceUSDX96(
    address _pricePool,
    address _nativeStablePool,
    address _WETH9
  ) public view override returns (uint256) {
    address _token0 = IUniswapV3Pool(_nativeStablePool).token0();
    uint256 _priceStableWETH9X96 = _adjustedPriceX96(
      IUniswapV3Pool(_nativeStablePool),
      _token0 == _WETH9 ? IUniswapV3Pool(_nativeStablePool).token1() : _token0
    );
    if (_pricePool == _nativeStablePool) {
      return _priceStableWETH9X96;
    }
    uint256 _priceMainX96 = _adjustedPriceX96(
      IUniswapV3Pool(_pricePool),
      _WETH9
    );
    return (_priceStableWETH9X96 * _priceMainX96) / FixedPoint96.Q96;
  }

  function sqrtPriceX96FromPoolAndInterval(
    address _poolAddress
  ) public view override returns (uint160 sqrtPriceX96) {
    IUniswapV3Pool _pool = IUniswapV3Pool(_poolAddress);
    if (INTERVAL == 0) {
      (sqrtPriceX96, , , , , , ) = _pool.slot0();
    } else {
      uint32[] memory secondsAgo = new uint32[](2);
      secondsAgo[0] = INTERVAL;
      secondsAgo[1] = 0;
      (int56[] memory tickCumulatives, ) = _pool.observe(secondsAgo);
      sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
        int24((tickCumulatives[1] - tickCumulatives[0]) / INTERVAL)
      );
    }
  }

  function priceX96FromSqrtPriceX96(
    uint160 sqrtPriceX96
  ) public pure override returns (uint256 priceX96) {
    return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
  }

  function _adjustedPriceX96(
    IUniswapV3Pool _pool,
    address _numeratorToken
  ) internal view returns (uint256) {
    address _token1 = _pool.token1();
    uint8 _decimals0 = IERC20Metadata(_pool.token0()).decimals();
    uint8 _decimals1 = IERC20Metadata(_token1).decimals();
    uint160 _sqrtPriceX96 = sqrtPriceX96FromPoolAndInterval(address(_pool));
    uint256 _priceX96 = priceX96FromSqrtPriceX96(_sqrtPriceX96);
    uint256 _ratioPriceX96 = _token1 == _numeratorToken
      ? _priceX96
      : FixedPoint96.Q96 ** 2 / _priceX96;
    return
      _token1 == _numeratorToken
        ? (_ratioPriceX96 * 10 ** _decimals0) / 10 ** _decimals1
        : (_ratioPriceX96 * 10 ** _decimals1) / 10 ** _decimals0;
  }
}
