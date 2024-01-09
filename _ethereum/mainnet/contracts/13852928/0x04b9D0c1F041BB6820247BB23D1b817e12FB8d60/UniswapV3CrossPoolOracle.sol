// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.5;

import "OracleLibrary.sol";
import "PoolAddress.sol";
import "SafeUint128.sol";

contract UniswapV3SpotOracle {
  address public immutable uniswapV3Factory;

  constructor(address _uniswapV3Factory) {
    uniswapV3Factory = _uniswapV3Factory;
  }

  function uniV3SpotAssetToAsset(
    address _tokenIn,
    uint256 _amountIn,
    address _tokenOut,
    uint24 _uniswapV3PoolFee
  ) public view returns (uint256 amountOut) {
    address pool =
      PoolAddress.computeAddress(uniswapV3Factory, PoolAddress.getPoolKey(_tokenIn, _tokenOut, _uniswapV3PoolFee));
    (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3PoolState(pool).slot0();

    // 160 + 160 - 64 = 256; 96 + 96 - 64 = 128
    uint256 priceX128 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 64);

    // Pool prices base/quote with lowerToken/higherToken, so adjust for inputs
    return
      _tokenIn < _tokenOut
        ? FullMath.mulDiv(priceX128, _amountIn, 1 << 128)
        : FullMath.mulDiv(1 << 128, _amountIn, priceX128);
  }
}