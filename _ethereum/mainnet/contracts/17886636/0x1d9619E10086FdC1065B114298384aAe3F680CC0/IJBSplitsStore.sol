// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./JBGroupedSplits.sol";
import "./JBSplit.sol";
import "./IJBDirectory.sol";
import "./IJBProjects.sol";

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 projectId,
    uint256 domain,
    uint256 group
  ) external view returns (JBSplit[] memory);

  function set(uint256 projectId, uint256 domain, JBGroupedSplits[] memory groupedSplits) external;
}
