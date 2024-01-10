// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.3;

interface ICurve_3 {
  function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
    external;

  function remove_liquidity_one_coin(
    uint256 burn_amount,
    int128 i,
    uint256 mim_received
  ) external;

  function coins(uint256) external view returns (address);

  function calc_withdraw_one_coin(uint256, int128)
    external
    view
    returns (uint256);
}
