// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface IHeroInfinityNodePool {
  struct NodeEntity {
    string name;
    uint256 creationTime;
    uint256 lastClaimTime;
    uint256 feeTime;
    uint256 dueTime;
  }

  function getNodeNumberOf(address account) external view returns (uint256);

  function getNodes(address account)
    external
    view
    returns (NodeEntity[] memory nodes);
}
