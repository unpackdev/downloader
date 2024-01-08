//SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.6;
pragma abicoder v2;

import "./IUniswapV3Pool.sol";
import "./TickMath.sol";
import "./FullMath.sol";
import "./LiquidityMath.sol";
import "./SqrtPriceMath.sol";
import "./SwapMath.sol";
import "./FixedPoint128.sol";
import "./LiquidityAmounts.sol";

import "./TickBitmap.sol";

contract Exchanger {
  using TickBitmap for IUniswapV3Pool;
  using SafeCast for uint256;
  using SafeCast for uint128;

  struct Slot0 {
    // the current price
    uint160 sqrtPriceX96;
    // the current tick
    int24 tick;
    // the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)%
    uint8 feeProtocol;
  }

  struct SwapCache {
    // the protocol fee for the input token
    uint8 feeProtocol;
    // lowerPrice
    uint160 sqrtRatioAX96;
    // upperPrice
    uint160 sqrtRatioBX96;
    // amount0 = token0
    uint256 amount0;
    // amount1 = token1
    uint256 amount1;
    bool originalZeroForOne;
  }

  // the top level state of the swap, the results of which are recorded in storage at the end
  struct SwapState {
    // the amount remaining to be swapped in/out of the input/output asset
    uint256 amountSpecifiedRemaining;
    uint256 sellAmount0;
    uint256 sellAmount1;
    uint256 amount0AfterSwap;
    uint256 amount1AfterSwap;
    // current sqrt(price)
    uint160 sqrtPriceX96;
    // the tick associated with the current price
    int24 tick;
    // the current liquidity in range
    uint128 liquidity;
    bool zeroForOneAfterSwap;
  }

  struct StepComputations {
    // the price at the beginning of the step
    uint160 sqrtPriceStartX96;
    // the next tick to swap to from the current tick in the swap direction
    int24 tickNext;
    // whether tickNext is initialized or not
    bool initialized;
    // sqrt(price) for the next tick (1/0)
    uint160 sqrtPriceNextX96;
    // how much is being swapped in in this step
    uint256 amountIn;
    // how much is being swapped out
    uint256 amountOut;
    // how much fee is being paid in
    uint256 feeAmount;
  }

  uint256 private constant EPSILON = 10**8;

  int24 public immutable tickSpacing;
  uint24 public immutable protocolFee;

  IUniswapV3Pool public immutable uniswapV3Pool;
  address public immutable token0;
  address public immutable token1;

  constructor(address _uniswapV3Pool) {
    uniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);

    {
      IUniswapV3Pool UniswapV3Pool = IUniswapV3Pool(_uniswapV3Pool);
      token0 = UniswapV3Pool.token0();
      token1 = UniswapV3Pool.token1();
      protocolFee = UniswapV3Pool.fee();
      tickSpacing = UniswapV3Pool.tickSpacing();
    }
  }

  function _bestAmounts(
    uint160 sqrtRatioX96,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount0,
    uint256 amount1
  ) private pure returns (uint256, uint256) {
    require(sqrtRatioAX96 <= sqrtRatioX96, 'The current price lower than expected');
    require(sqrtRatioX96 <= sqrtRatioBX96, 'The current price upper than expected');

    uint128 liquidity0 = LiquidityAmounts.getLiquidityForAmount0(
      sqrtRatioX96,
      sqrtRatioBX96,
      amount0
    );
    uint128 liquidity1 = LiquidityAmounts.getLiquidityForAmount1(
      sqrtRatioAX96,
      sqrtRatioX96,
      amount1
    );

    uint256 midLiquidity = ((uint256(liquidity0) + uint256(liquidity1)) >> 1);

    return (
      uint256(SqrtPriceMath.getAmount0Delta(sqrtRatioX96, sqrtRatioBX96, int128(midLiquidity))),
      uint256(SqrtPriceMath.getAmount1Delta(sqrtRatioAX96, sqrtRatioX96, int128(midLiquidity)))
    );
  }

  function _zeroForOne(
    uint160 sqrtRatioX96,
    uint160 sqrtRatioAX96,
    uint160 sqrtRatioBX96,
    uint256 amount0,
    uint256 amount1
  )
    private
    pure
    returns (
      bool,
      uint256,
      bool
    )
  {
    (uint256 bestAmount0, uint256 bestAmount1) = _bestAmounts(
      sqrtRatioX96,
      sqrtRatioAX96,
      sqrtRatioBX96,
      amount0,
      amount1
    );

    if (bestAmount1 < amount1) {
      // we need sell token1
      return (false, amount1 - bestAmount1, false);
    }
    if (amount0 >= bestAmount0) {
      // we need sell token0
      return (true, amount0 - bestAmount0, false);
    }
    // overflow
    return (true, 0, true);
  }

  function rebalance(
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0,
    uint256 amount1
  )
    public
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint160
    )
  {
    Slot0 memory slot0Start;
    {
      (uint160 sqrtPriceX96, int24 tick, , , , uint8 feeProtocol, ) = uniswapV3Pool.slot0();
      slot0Start = Slot0({ sqrtPriceX96: sqrtPriceX96, tick: tick, feeProtocol: feeProtocol });
    }

    SwapCache memory cache = SwapCache({
      feeProtocol: 0,
      sqrtRatioAX96: TickMath.getSqrtRatioAtTick(tickLower),
      sqrtRatioBX96: TickMath.getSqrtRatioAtTick(tickUpper),
      amount0: amount0,
      amount1: amount1,
      originalZeroForOne: false
    });

    SwapState memory state = SwapState({
      amountSpecifiedRemaining: 0,
      sellAmount0: 0,
      sellAmount1: 0,
      amount0AfterSwap: 0,
      amount1AfterSwap: 0,
      sqrtPriceX96: slot0Start.sqrtPriceX96,
      tick: slot0Start.tick,
      liquidity: uniswapV3Pool.liquidity(),
      zeroForOneAfterSwap: false
    });

    bool overflow;
    (cache.originalZeroForOne, state.amountSpecifiedRemaining, overflow) = _zeroForOne(
      slot0Start.sqrtPriceX96,
      cache.sqrtRatioAX96,
      cache.sqrtRatioBX96,
      cache.amount0,
      cache.amount1
    );
    if (overflow) {
      return (0, 0, 0, 0, 0);
    }

    cache.feeProtocol = cache.originalZeroForOne
      ? (slot0Start.feeProtocol % 16)
      : (slot0Start.feeProtocol >> 4);

    while (state.amountSpecifiedRemaining > 0) {
      StepComputations memory step;

      step.sqrtPriceStartX96 = state.sqrtPriceX96;

      (step.tickNext, step.initialized) = uniswapV3Pool.nextInitializedTickWithinOneWord(
        state.tick,
        tickSpacing,
        cache.originalZeroForOne
      );

      // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
      if (step.tickNext < TickMath.MIN_TICK) {
        step.tickNext = TickMath.MIN_TICK;
      } else if (step.tickNext > TickMath.MAX_TICK) {
        step.tickNext = TickMath.MAX_TICK;
      }

      // get the price for the next tick
      step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

      uint160 sqrtPriceX96BeforeSwap = state.sqrtPriceX96;
      uint160 sqrtRatioTargetX96;
      {
        uint160 sqrtPriceLimitX96 = cache.originalZeroForOne
          ? TickMath.MIN_SQRT_RATIO + 1
          : TickMath.MAX_SQRT_RATIO - 1;
        sqrtRatioTargetX96 = (
          cache.originalZeroForOne
            ? step.sqrtPriceNextX96 < sqrtPriceLimitX96
            : step.sqrtPriceNextX96 > sqrtPriceLimitX96
        )
          ? sqrtPriceLimitX96
          : step.sqrtPriceNextX96;
      }

      // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
      (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath
      .computeSwapStep(
        sqrtPriceX96BeforeSwap,
        sqrtRatioTargetX96,
        state.liquidity,
        state.amountSpecifiedRemaining.toInt256(),
        protocolFee
      );

      if (cache.originalZeroForOne) {
        state.amount0AfterSwap = cache.amount0 - (step.amountIn + step.feeAmount);
        state.amount1AfterSwap = cache.amount1 + (step.amountOut);
      } else {
        state.amount0AfterSwap = cache.amount0 + (step.amountOut);
        state.amount1AfterSwap = cache.amount1 - (step.amountIn + step.feeAmount);
      }

      uint256 previousAmountRemaining = state.amountSpecifiedRemaining;
      (state.zeroForOneAfterSwap, state.amountSpecifiedRemaining, overflow) = _zeroForOne(
        state.sqrtPriceX96,
        cache.sqrtRatioAX96,
        cache.sqrtRatioBX96,
        state.amount0AfterSwap,
        state.amount1AfterSwap
      );
      if (overflow) {
        return (0, 0, 0, 0, 0);
      }

      // We swapped too much, which means that we need to swap in the backward direction
      // But we don't want to swap in the backward direction, we need to swap less in forward direction
      // Let's recalculate forward swap again
      // Or, if we swapped the full amount
      if (
        state.zeroForOneAfterSwap != cache.originalZeroForOne ||
        state.amountSpecifiedRemaining < EPSILON
      ) {
        // let's do binary search to find right value which we need pass into swap
        int256 l = 0;
        int256 r = 2 * previousAmountRemaining.toInt256();
        uint256 i = 0;
        while (true) {
          i = i + 1;
          int256 mid = (l + r) / 2;

          (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath
          .computeSwapStep(
            sqrtPriceX96BeforeSwap,
            sqrtRatioTargetX96,
            state.liquidity,
            mid,
            protocolFee
          );

          if (cache.originalZeroForOne) {
            state.amount0AfterSwap = cache.amount0 - (step.amountIn + step.feeAmount);
            state.amount1AfterSwap = cache.amount1 + (step.amountOut);
          } else {
            state.amount0AfterSwap = cache.amount0 + (step.amountOut);
            state.amount1AfterSwap = cache.amount1 - (step.amountIn + step.feeAmount);
          }

          uint128 liquidity0 = LiquidityAmounts.getLiquidityForAmount0(
            state.sqrtPriceX96,
            cache.sqrtRatioBX96,
            state.amount0AfterSwap
          );
          uint128 liquidity1 = LiquidityAmounts.getLiquidityForAmount1(
            cache.sqrtRatioAX96,
            state.sqrtPriceX96,
            state.amount1AfterSwap
          );

          bool rightDirection = false;
          if (cache.originalZeroForOne) {
            if (liquidity0 > liquidity1) {
              rightDirection = true;
              l = mid;
            } else {
              r = mid;
            }
          } else {
            if (liquidity0 < liquidity1) {
              rightDirection = true;
              l = mid;
            } else {
              r = mid;
            }
          }

          if (rightDirection && (i >= 70 || l + 1 >= r)) {
            if (cache.originalZeroForOne) {
              state.sellAmount0 += step.amountIn + step.feeAmount;
            } else {
              state.sellAmount1 += step.amountIn + step.feeAmount;
            }
            break;
          }
        }

        state.amountSpecifiedRemaining = 0;
      } else {
        if (cache.originalZeroForOne) {
          state.sellAmount0 += step.amountIn + step.feeAmount;
        } else {
          state.sellAmount1 += step.amountIn + step.feeAmount;
        }

        cache.amount0 = state.amount0AfterSwap;
        cache.amount1 = state.amount1AfterSwap;

        // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
        if (cache.feeProtocol > 0) {
          uint256 delta = step.feeAmount / cache.feeProtocol;
          step.feeAmount -= delta;
        }

        // shift tick if we reached the next price
        if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
          // if the tick is initialized, run the tick transition
          if (step.initialized) {
            (, int128 liquidityNet, , , , , , ) = uniswapV3Pool.ticks(step.tickNext);

            // if we're moving leftward, we interpret liquidityNet as the opposite sign
            // safe because liquidityNet cannot be type(int128).min
            if (cache.originalZeroForOne) liquidityNet = -liquidityNet;

            state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);
          }

          state.tick = cache.originalZeroForOne ? step.tickNext - 1 : step.tickNext;
        } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
          // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
          state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
        }
      }
    }

    return (
      state.sellAmount0,
      state.sellAmount1,
      state.amount0AfterSwap,
      state.amount1AfterSwap,
      state.sqrtPriceX96
    );
  }
}
