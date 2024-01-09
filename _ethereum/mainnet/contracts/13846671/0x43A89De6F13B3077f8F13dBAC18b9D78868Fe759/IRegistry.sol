// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IRegistry {
  function get_n_coins(address pool) external view returns (uint256);

  function get_coins(address pool) external view returns (address[8] memory);

  function get_pool_from_lp_token(address) external view returns (address);
}
