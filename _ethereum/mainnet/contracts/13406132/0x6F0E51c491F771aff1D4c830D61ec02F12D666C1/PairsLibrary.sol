// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./LowGasSafeMath.sol";
import "./IUniswapV2Pair.sol";


library PairsLibrary {
  using LowGasSafeMath for uint256;
  address internal constant uniswapFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
  address internal constant sushiswapFactory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculateUniPair(address token0, address token1 ) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            uniswapFactory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  function calculateSushiPair(address token0, address token1) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            sushiswapFactory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
          )
        )
      )
    );
  }

  function tryGetReserves(address pair) internal view returns (uint112 reserve0, uint112 reserve1) {
    (bool success, bytes memory retData) = pair.staticcall(abi.encodeWithSelector(IUniswapV2Pair.getReserves.selector));
    if (success) {
      (reserve0, reserve1, ) = abi.decode(retData, (uint112, uint112, uint32));
    }
  }

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) internal pure returns (uint256 amountOut) {
    require(amountIn > 0, "PairsLibrary: INSUFFICIENT_INPUT_AMOUNT");
    require(
      reserveIn > 0 && reserveOut > 0,
      "PairsLibrary: INSUFFICIENT_LIQUIDITY"
    );
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }
}