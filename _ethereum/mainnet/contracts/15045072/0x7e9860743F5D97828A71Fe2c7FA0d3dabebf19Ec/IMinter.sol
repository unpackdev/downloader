// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

// solhint-disable func-name-mixedcase
interface IMinter {
  function minted(address wallet, address gauge) external view returns (uint256);

  function mint(address gauge) external;
}
