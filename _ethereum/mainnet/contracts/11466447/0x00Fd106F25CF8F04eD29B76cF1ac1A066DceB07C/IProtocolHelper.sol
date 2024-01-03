// SPDX-License-Identifier: Apache-2.0-with-puul-exception
pragma solidity >=0.6.12;

interface IProtocolHelper {
  function swap(string memory path, uint256 amount, uint256 min, address dest) external returns (uint256 result);
}
