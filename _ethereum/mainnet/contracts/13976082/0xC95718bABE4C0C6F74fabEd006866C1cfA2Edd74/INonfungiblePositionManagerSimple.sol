// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

// We can't use full INonfungiblePositionManager as provided by Uniswap since it's on Solidity 0.7

interface INonfungiblePositionManagerSimple {

  function positions(uint256 tokenId)
    external
    view
    returns (
      uint96 nonce,
      address operator,
      address token0,
      address token1,
      uint24 fee,
      int24 tickLower,
      int24 tickUpper,
      uint128 liquidity,
      uint256 feeGrowthInside0LastX128,
      uint256 feeGrowthInside1LastX128,
      uint128 tokensOwed0,
      uint128 tokensOwed1
    );
}