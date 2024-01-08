// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IShare {
  function balanceOf(address account) external view returns (uint256);
}