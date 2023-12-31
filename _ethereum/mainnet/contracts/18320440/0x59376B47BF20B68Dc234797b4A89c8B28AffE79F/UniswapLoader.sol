//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

//import "./console.sol";
import "./IUniswapV3Pool.sol";
import "./IUniswapV2Pair.sol";

contract UniswapLoader {
  constructor() {
  }

  struct BriefTickInfo {
    int128 liquidity_net;
    int24 tick;
  }

  struct UniV3State {
    bool exist;
    uint block_number;
    bytes32 block_hash;
    address token0;
    address token1;
    uint24 fee;
    int24 slot0tick;
    uint160 slot0sqrtPriceX96;
    uint128 liquidity;
    int24 tickSpacing;
    uint counter;
    int total_sum;
    int sum_from_slot0tick;
    int24 tick_to_look_up;
    uint bitmap;
    int i;
    int j;
  }

  function load(IUniswapV3Pool pool, int limit) external view returns (UniV3State memory state, BriefTickInfo[] memory ticks) {
    {
      address token0 = pool.token0();
      address token1 = pool.token1();
      uint24 fee = pool.fee();
      uint128 liquidity = pool.liquidity();
      int24 tickSpacing = pool.tickSpacing();
      uint160 sqrtPriceX96;
      int24 slot0tick;
      uint160 slot0sqrtPriceX96;

      try pool.slot0() returns (
              uint160 sqrtPriceX96,
              int24 tick,
              uint16 observationIndex,
              uint16 observationCardinality,
              uint16 observationCardinalityNext,
              uint8 feeProtocol,
              bool unlocked
          ) {
        slot0tick = tick;
        slot0sqrtPriceX96 = sqrtPriceX96;
      } catch {
        state.exist = false;
        return (state, ticks);
      }

      state = UniV3State({
        block_number: block.number,
        block_hash: blockhash(block.number),
        exist: true,
        token0: token0,
        token1: token1,
        fee: fee,
        slot0tick: slot0tick,
        slot0sqrtPriceX96: slot0sqrtPriceX96,
        liquidity: liquidity,
        tickSpacing: tickSpacing,
        counter: 0,
        total_sum: 0,
        sum_from_slot0tick: 0,
        tick_to_look_up: 0,
        bitmap: 0,
        i: 0,
        j: 0
      });
    }

//    state.counter = 0;
    {
      for (state.i = -limit; state.i < limit; state.i++) {
        state.bitmap = pool.tickBitmap(int16(state.i));
        if (state.bitmap != 0) {
          for (state.j = 0; state.j < 256; state.j++) {
            if (state.bitmap & (1<<uint(int(state.j))) != 0) {
              state.counter++;
            }
          }
        }
      }
    }
    ticks = new BriefTickInfo[](state.counter);
    state.counter = 0;

    state.total_sum= 0;
    state.sum_from_slot0tick = int128(pool.liquidity());
    for (state.i = -limit; state.i < limit; state.i++) {
      state.bitmap = pool.tickBitmap(int16(state.i));
      if (state.bitmap != 0) {
        state.tick_to_look_up = int24(state.i)*256*state.tickSpacing;
        for (state.j = 0; state.j < 256; state.j++) {
          if (state.bitmap & (1<<uint(int(state.j))) != 0) {
//            (
//              uint128 liquidityGross,
//              int128 liquidityNet,
//              uint256 feeGrowthOutside0X128,
//              uint256 feeGrowthOutside1X128,
//              int56 tickCumulativeOutside,
//              uint160 secondsPerLiquidityOutsideX128,
//              uint32 secondsOutside,
//              bool initialized
//            ) = IUniswapV3Pool(pool).ticks(tick_to_look_up);

            (
//              uint128 liquidityGross,
              ,
              int128 liquidityNet,
              ,
              ,
              ,
              ,
              ,
//              uint256 feeGrowthOutside0X128,
//              uint256 feeGrowthOutside1X128,
//              int56 tickCumulativeOutside,
//              uint160 secondsPerLiquidityOutsideX128,
//              uint32 secondsOutside,
//              bool initialized
            ) = pool.ticks(state.tick_to_look_up);
            ticks[state.counter] = BriefTickInfo({
              liquidity_net: liquidityNet,
              tick: state.tick_to_look_up
            });
            state.counter++;
            state.total_sum += liquidityNet;
            if (state.slot0tick < state.tick_to_look_up) {
              state.sum_from_slot0tick += liquidityNet;
            }
          }
          state.tick_to_look_up += state.tickSpacing;
        }
      }
    }
  }

  struct UniV3StateWithTicks {
    UniV3State state;
    BriefTickInfo[] ticks;
  }

  function batchV3(IUniswapV3Pool[] calldata pools, int limit) external view returns(UniV3StateWithTicks[] memory res) {
    res = new UniV3StateWithTicks[](pools.length);
    for (uint i = 0; i < pools.length; i++) {
      try this.load(pools[i], limit) returns (UniV3State memory state, BriefTickInfo[] memory ticks) {
        res[i].state = state;
        res[i].ticks = ticks;
      } catch {
        res[i].state.exist = false;
      }
    }
  }

  function batchV3Internal(IUniswapV3Pool[] calldata pools, int limit) internal view returns(UniV3StateWithTicks[] memory res) {
    res = new UniV3StateWithTicks[](pools.length);
    for (uint i = 0; i < pools.length; i++) {
      try this.load(pools[i], limit) returns (UniV3State memory state, BriefTickInfo[] memory ticks) {
        res[i].state = state;
        res[i].ticks = ticks;
      } catch {
        res[i].state.exist = false;
      }
    }
  }

  struct UniV2State {
    bool exist;
    address token0;
    address token1;
    uint reserve0;
    uint reserve1;
  }

  function mixedBatch(IUniswapV3Pool[] calldata pools, IUniswapV2Pair[] calldata pairs, int limit) external view returns(UniV3StateWithTicks[] memory v3res, UniV2State[] memory v2res) {
    v3res = batchV3Internal(pools, limit);
    v2res = batchV2Internal(pairs);
  }

  function batchV2Internal(IUniswapV2Pair[] calldata pairs) internal view returns(UniV2State[] memory v2res) {
    v2res = new UniV2State[](pairs.length);
    for (uint i = 0; i < pairs.length; i++) {
      try this.univ2load(pairs[i]) returns(UniV2State memory v2state) {
        v2res[i] = v2state;
      } catch {
        v2res[i].exist = false;
      }
    }
  }

  function univ2load(IUniswapV2Pair pair) external view returns(UniV2State memory v2state) {
    return univ2loadInternal(pair);
  }

  function univ2loadInternal(IUniswapV2Pair pair) internal view returns(UniV2State memory v2state) {
    v2state.token0 = pair.token0();
    v2state.token1 = pair.token1();
    (uint112 r0, uint112 r1, uint32 blockTimestampLast) = pair.getReserves();
    v2state.reserve0 = r0;
    v2state.reserve1 = r1;
    v2state.exist = true;
  }
}
