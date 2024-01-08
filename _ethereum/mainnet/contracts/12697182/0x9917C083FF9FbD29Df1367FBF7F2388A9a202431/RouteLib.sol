// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Pair.sol";

library RouteLib {
  address internal constant _SUSHI_FACTORY = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
  bytes32 internal constant _SUSHI_ROUTER_INIT_HASH = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303;
  bytes32 internal constant _UNI_V2_ROUTER_INIT_HASH = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;
  bytes32 internal constant _UNI_V3_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

  /// @notice The identifying key of the pool
  struct PoolKey {
      address token0;
      address token1;
      uint24 fee;
  }

  /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
  /// @param tokenA The first token of a pool, unsorted
  /// @param tokenB The second token of a pool, unsorted
  /// @param fee The fee level of the pool
  /// @return Poolkey The pool details with ordered token0 and token1 assignments
  function getPoolKey(
      address tokenA,
      address tokenB,
      uint24 fee
  ) internal pure returns (PoolKey memory) {
      if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
      return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
  }

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
    require(tokenA != tokenB, 'RouteLib: IDENTICAL_ADDRESSES');
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), 'RouteLib: ZERO_ADDRESS');
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    bytes32 initHash = factory == _SUSHI_FACTORY ? _SUSHI_ROUTER_INIT_HASH : _UNI_V2_ROUTER_INIT_HASH;
    pair = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              factory,
              keccak256(abi.encodePacked(token0, token1)),
              initHash // init code hash
            )
          )
        )
      )
    );
  }

  /// @notice Deterministically computes the pool address given the factory and PoolKey
  /// @param factory The Uniswap V3 factory contract address
  /// @param key The PoolKey
  /// @return pool The contract address of the V3 pool
  function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
      require(key.token0 < key.token1);
      pool = address(
          uint160(
              uint256(
                  keccak256(
                      abi.encodePacked(
                          hex'ff',
                          factory,
                          keccak256(abi.encode(key.token0, key.token1, key.fee)),
                          _UNI_V3_INIT_CODE_HASH
                      )
                  )
              )
          )
      );
  }

  // fetches and sorts the reserves for a pair
  function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
    (address token0,) = sortTokens(tokenA, tokenB);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
    (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
  function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
    require(amountA > 0, 'RouteLib: INSUFFICIENT_AMOUNT');
    require(reserveA > 0 && reserveB > 0, 'RouteLib: INSUFFICIENT_LIQUIDITY');
    amountB = amountA * (reserveB) / reserveA;
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
    require(amountIn > 0, 'RouteLib: INSUFFICIENT_INPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'RouteLib: INSUFFICIENT_LIQUIDITY');
    uint amountInWithFee = amountIn * 997;
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = reserveIn * 1000 + amountInWithFee;
    amountOut = numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
    require(amountOut > 0, 'RouteLib: INSUFFICIENT_OUTPUT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'RouteLib: INSUFFICIENT_LIQUIDITY');
    uint numerator = reserveIn * amountOut * 1000;
    uint denominator = (reserveOut - amountOut) * 997;
    amountIn = (numerator / denominator) + 1;
  }

  // performs chained getAmountOut calculations on any number of pairs
  function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'RouteLib: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[0] = amountIn;
    for (uint i; i < path.length - 1; i++) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
      amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
    require(path.length >= 2, 'RouteLib: INVALID_PATH');
    amounts = new uint[](path.length);
    amounts[amounts.length - 1] = amountOut;
    for (uint i = path.length - 1; i > 0; i--) {
      (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
      amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
    }
  }
}