// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IPair {
  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);
}
