// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./JBFundAccessConstraints.sol";
import "./JBFundingCycleData.sol";
import "./JBFundingCycleMetadata.sol";
import "./JBGroupedSplits.sol";
import "./JBProjectMetadata.sol";
import "./IJBController.sol";
import "./IJBDirectory.sol";
import "./IJBFundingCycleStore.sol";
import "./IJBMigratable.sol";
import "./IJBPaymentTerminal.sol";
import "./IJBSplitsStore.sol";
import "./IJBTokenStore.sol";

interface IJBController3_0_1 {
  function reservedTokenBalanceOf(uint256 _projectId) external view returns (uint256);
  function totalOutstandingTokensOf(uint256 _projectId) external view returns (uint256);
}
