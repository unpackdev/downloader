// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface ICurve {
  function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;
  function coins(uint256 i) view external returns (address) ;
  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external;
  function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
  function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;
  function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount) external;
}
