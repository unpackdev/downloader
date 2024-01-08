// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./IUniswapV2Pair.sol";
import "./SafeMath.sol";


library NarwhalLibrary {
  using SafeMath for uint256;

  function unpack(bytes32 pairInfo) internal pure returns (bool zeroForOne, address pair) {
    assembly {
      zeroForOne := byte(31, pairInfo)
      pair := shr(8, pairInfo)
    }
  }

  function readPair(bytes32 pairInfo) internal pure returns (address pair) {
    assembly {
      pair := shr(8, pairInfo)
    }
  }

  function tokenIn(bytes32 pairInfo) internal view returns (address token) {
    (bool zeroForOne, address pair) = unpack(pairInfo);
    token = zeroForOne ? IUniswapV2Pair(pair).token0() : IUniswapV2Pair(pair).token1();
  }

  function tokenOut(bytes32 pairInfo) internal view returns (address token) {
    (bool zeroForOne, address pair) = unpack(pairInfo);
    token = zeroForOne ? IUniswapV2Pair(pair).token1() : IUniswapV2Pair(pair).token0();
  }

  function getReserves(bytes32 pairInfo) internal view returns (uint256 reserveIn, uint256 reserveOut) {
    (bool zeroForOne, address pair) = unpack(pairInfo);
    (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
    (reserveIn, reserveOut) = zeroForOne ? (reserve0, reserve1) : (reserve1, reserve0);
  }

  function getAmountOut(bytes32 pairInfo, uint256 amountIn) internal view returns (uint256 amountOut) {
    require(amountIn > 0, "Narwhal: INSUFFICIENT INPUT");
    (uint256 reserveIn, uint256 reserveOut) = getReserves(pairInfo);
    require(reserveIn > 0 && reserveOut > 0, "Narwhal: INSUFFICIENT_LIQUIDITY");
    uint256 amountInWithFee = amountIn.mul(997);
    uint256 numerator = amountInWithFee.mul(reserveOut);
    uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
    amountOut = numerator / denominator;
  }

  function getAmountIn(bytes32 pairInfo, uint256 amountOut)
    internal
    view
    returns (uint256 amountIn)
  {
    require(amountOut > 0, "Narwhal: INSUFFICIENT_OUTPUT");
    (uint256 reserveIn, uint256 reserveOut) = getReserves(pairInfo);
    require(reserveIn > 0 && reserveOut > 0, "Narwhal: INSUFFICIENT_LIQUIDITY");
    uint256 numerator = reserveIn.mul(amountOut).mul(1000);
    uint256 denominator = reserveOut.sub(amountOut).mul(997);
    amountIn = (numerator / denominator).add(1);
  }

  function getAmountsOut(
    uint256 amountIn,
    bytes32[] memory path
  ) internal view returns (uint256[] memory amounts) {
    require(path.length >= 1, "Narwhal: INVALID_PATH");
    amounts = new uint256[](path.length + 1);
    amounts[0] = amountIn;
    for (uint256 i; i < path.length; i++) {
      amounts[i + 1] = getAmountOut(path[i], amounts[i]);
    }
  }

  // performs chained getAmountIn calculations on any number of pairs
  function getAmountsIn(uint256 amountOut, bytes32[] memory path)
    internal
    view
    returns (uint256[] memory amounts)
  {
    require(path.length >= 1, "Narwhal: INVALID_PATH");
    amounts = new uint256[](path.length + 1);
    amounts[amounts.length - 1] = amountOut;
    for (uint256 i = amounts.length - 1; i > 0; i--) {
      amounts[i - 1] = getAmountIn(path[i - 1], amounts[i]);
    }
  }
}