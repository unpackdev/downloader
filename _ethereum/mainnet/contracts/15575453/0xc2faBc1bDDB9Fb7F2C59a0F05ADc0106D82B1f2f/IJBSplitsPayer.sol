// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./JBSplit.sol";
import "./JBGroupedSplits.sol";
import "./IJBSplitsStore.sol";

interface IJBSplitsPayer is IERC165 {
  event SetDefaultSplitsReference(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    address caller
  );
  event Pay(
    uint256 indexed projectId,
    address beneficiary,
    address token,
    uint256 amount,
    uint256 decimals,
    uint256 leftoverAmount,
    uint256 minReturnedTokens,
    bool preferClaimedTokens,
    string memo,
    bytes metadata,
    address caller
  );

  event AddToBalance(
    uint256 indexed projectId,
    address beneficiary,
    address token,
    uint256 amount,
    uint256 decimals,
    uint256 leftoverAmount,
    string memo,
    bytes metadata,
    address caller
  );

  event DistributeToSplitGroup(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    address caller
  );

  event DistributeToSplit(
    JBSplit split,
    uint256 amount,
    address defaultBeneficiary,
    address caller
  );

  function defaultSplitsProjectId() external view returns (uint256);

  function defaultSplitsDomain() external view returns (uint256);

  function defaultSplitsGroup() external view returns (uint256);

  function splitsStore() external view returns (IJBSplitsStore);

  function setDefaultSplitsReference(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external;

  function setDefaultSplits(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group,
    JBGroupedSplits[] memory _splitsGroup
  ) external;
}
