// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface ICurveRegistry {
  function pool_count() external view returns(uint256);
  function pool_from_lp_token(address lp) external view returns(address);
  function get_underlying_coins(address pool) external view returns(address[] memory);
  function get_virtual_price_from_lp_token(address lp) external view returns(uint256);
}
