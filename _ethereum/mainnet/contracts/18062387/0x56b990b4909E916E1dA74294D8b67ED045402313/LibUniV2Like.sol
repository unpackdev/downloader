// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "./IUniswapV2Pair.sol";

library LibUniV2Like {
  function getAmountsOut(
    uint24 poolFeeBps,
    uint256 amountIn,
    address[] memory tokens,
    address[] memory pools
  ) internal view returns (uint256[] memory amounts) {
    uint256 poolLength = pools.length;

    // For 30 bps, multiply by 997
    uint256 feeFactor = 1_000 - poolFeeBps / 10;

    amounts = new uint256[](tokens.length);
    amounts[0] = amountIn;

    for (uint256 index; index < poolLength; ) {
      address token0 = tokens[index];
      address token1 = tokens[index + 1];

      (uint256 reserveIn, uint256 reserveOut, ) = IUniswapV2Pair(pools[index]).getReserves();

      if (token0 > token1) {
        (reserveIn, reserveOut) = (reserveOut, reserveIn);
      }

      unchecked {
        amountIn =
          ((amountIn * feeFactor) * reserveOut) /
          ((reserveIn * 1000) + (amountIn * feeFactor));
      }

      // Recycling `amountIn`
      amounts[index + 1] = amountIn;

      unchecked {
        index++;
      }
    }
  }
}
