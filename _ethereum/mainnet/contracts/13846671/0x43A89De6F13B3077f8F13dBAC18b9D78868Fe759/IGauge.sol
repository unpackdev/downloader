// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IGauge {
  function minter() external view returns (address);

  function crv_token() external view returns (address);

  function lp_token() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function deposit(uint256 amount) external;

  function deposit(uint256 amount, address recipient) external;

  function withdraw(uint256 amount) external;
}
