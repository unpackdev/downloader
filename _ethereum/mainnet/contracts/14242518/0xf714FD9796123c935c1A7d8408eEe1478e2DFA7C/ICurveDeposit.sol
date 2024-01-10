// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ICurveDeposit {
  // 3 coin
  function add_liquidity(uint256[1] memory amounts, uint256 min_mint_amount) external;

  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);

  function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

  function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

  function add_liquidity(
    uint256[3] memory amounts,
    uint256 min_mint_amount,
    bool _use_underlying
  ) external;

  function coins(uint256 arg0) external view returns (address);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function calc_token_amount(uint256[4] memory amounts, bool is_deposit) external view returns (uint256);

  function calc_token_amount(uint256[3] memory amounts, bool is_deposit) external view returns (uint256);

  function calc_token_amount(uint256[2] memory amounts, bool is_deposit) external view returns (uint256);

  /// @notice Withdraw and unwrap a single coin from the pool
  /// @param _token_amount Amount of LP tokens to burn in the withdrawal
  /// @param i Index value of the coin to withdraw, 0-Dai, 1-USDC, 2-USDT
  /// @param _min_amount Minimum amount of underlying coin to receive
  //
  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount
  ) external returns (uint256);
}

interface ICurveDepositTrio {
  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount
  ) external;
}
