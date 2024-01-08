//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./console.sol";

// UniswapV3 core
import "./IUniswapV3Factory.sol";
import "./IUniswapV3Pool.sol";
import "./TickMath.sol";

// UniswapV3 periphery contracts
import "./INonfungiblePositionManager.sol";
import "./ISwapRouter.sol";
import "./LiquidityAmounts.sol";

contract UniStatusViewer {
  address constant _UNI_POS_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
  address constant _UNI_POOL_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;

  // INonfungiblePositionManager(uniPosManager).positions(posId)
  // uint96 nonce,
  // address operator,
  // address token0,
  // address token1,
  // uint24 fee,
  // int24 tickLower,
  // int24 tickUpper,
  // uint128 liquidity,
  // uint256 feeGrowthInside0LastX128,
  // uint256 feeGrowthInside1LastX128,
  // uint128 tokensOwed0,
  // uint128 tokensOwed1


  function getSqrtPriceX96(address _token0, address _token1, uint24 _fee) public view returns(uint160) {
    address poolAddr = IUniswapV3Factory(_UNI_POOL_FACTORY).getPool(
      _token0, _token1, _fee
    );
    (uint160 sqrtPriceX96,,,,,,) = IUniswapV3Pool(poolAddr).slot0();
    return sqrtPriceX96;
  }

  function getSqrtPriceX96ForPosition(uint256 posId) public view returns(uint160) {
    (,,address _token0, address _token1, uint24 _fee,,,,,,,)= INonfungiblePositionManager(_UNI_POS_MANAGER).positions(posId);
    return getSqrtPriceX96(_token0, _token1, _fee);
  }

  function getAmountsForPosition(uint256 posId) public view returns (uint256 amount0, uint256 amount1) {
    (,,address _token0, address _token1, uint24 _fee, int24 _tickLower, int24 _tickUpper, uint128 _liquidity,,,,)= INonfungiblePositionManager(_UNI_POS_MANAGER).positions(posId);
    uint160 sqrtRatioX96 = getSqrtPriceX96(_token0, _token1, _fee);
    uint160 sqrtRatioXA96 = TickMath.getSqrtRatioAtTick(_tickLower);
    uint160 sqrtRatioXB96 = TickMath.getSqrtRatioAtTick(_tickUpper);
    (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
        sqrtRatioX96, sqrtRatioXA96, sqrtRatioXB96, _liquidity
    );
  }



}