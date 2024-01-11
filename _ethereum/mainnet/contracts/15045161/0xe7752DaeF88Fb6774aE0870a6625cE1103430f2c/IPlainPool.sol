// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IPlainPool {
  function calc_token_amount(uint256[3] memory amounts, bool isDeposit) external view returns (uint256);

  function add_liquidity(uint256[3] memory amounts, uint256 minMint) external returns (uint256);
}
