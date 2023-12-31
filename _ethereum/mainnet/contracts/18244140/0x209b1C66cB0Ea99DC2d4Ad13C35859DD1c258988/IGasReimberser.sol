// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IGasReimberser {
  function flush() external;
  function flush_erc20(address token) external;
}
