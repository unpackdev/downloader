pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

abstract contract ICurve {
  uint256 constant N_COINS = 4;
  function add_liquidity(uint256[N_COINS] calldata amounts, uint256 min_mint_amount) external virtual;
  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external virtual;
  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external virtual;
  function remove_liquidity(uint256 _amount, uint256[N_COINS] calldata min_amounts) external virtual;
  function remove_liquidity_imbalance(uint256[N_COINS] calldata amounts, uint256 max_burn_amount) external virtual;
  function coins(uint256 i) external virtual returns (address payable);
  function underlying_coins(uint256 i) external virtual returns (address payable);
}
