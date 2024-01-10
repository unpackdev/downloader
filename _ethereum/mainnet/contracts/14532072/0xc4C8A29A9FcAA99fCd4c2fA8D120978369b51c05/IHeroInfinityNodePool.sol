// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IHeroInfinityNodePool {
  function getNodeNumberOf(address account) external view returns (uint256);
}
