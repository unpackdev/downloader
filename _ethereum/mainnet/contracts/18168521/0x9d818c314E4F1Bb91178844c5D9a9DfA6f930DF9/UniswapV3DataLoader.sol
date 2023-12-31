//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

import "./console.sol";
import "./IUniswapV3Pool.sol";

contract UniswapV3DataLoader {
  constructor() {
  }

  struct BriefTickInfo {
    int128 liquidity_net;
    int24 tick;
  }

  struct State {
    uint block_number;
    bytes32 block_hash;
    bool exist;
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

  function load(IUniswapV3Pool pool, int limit) external view returns (State memory state, BriefTickInfo[] memory ticks) {
    {
      address token0;
      address token1;
      uint24 fee;
      uint128 liquidity;
      int24 tickSpacing;
      uint160 sqrtPriceX96;
      int24 slot0tick;
      uint160 slot0sqrtPriceX96;

      try pool.token0() returns (address t0) {
        token0 = t0;
      } catch {
        state.exist = false;
        return (state, ticks);
      }

      try pool.token1() returns (address t1) {
        token1 = t1;
      } catch {
        state.exist = false;
        return (state, ticks);
      }

      try pool.fee() returns (uint24 f) {
        fee = f;
      } catch {
        state.exist = false;
        return (state, ticks);
      }

      try pool.liquidity() returns (uint128 l) {
        liquidity = l;
      } catch {
        state.exist = false;
        return (state, ticks);
      }

      try pool.tickSpacing() returns (int24 ts) {
        tickSpacing = ts;
      } catch {
        state.exist = false;
        return (state, ticks);
      }

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

      state = State({
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

  struct BatchResultItem {
    State state;
    BriefTickInfo[] ticks;
  }

  function batch(IUniswapV3Pool[] memory pools, int limit) external view returns(BatchResultItem[] memory res) {
    res = new BatchResultItem[](pools.length);
    for (uint i = 0; i < pools.length; i++) {
      try this.load(pools[i], limit) returns (State memory state, BriefTickInfo[] memory ticks) {
        res[i].state = state;
        res[i].ticks = ticks;
      } catch {
        res[i].state.exist = false;
      }
    }
  }
}
