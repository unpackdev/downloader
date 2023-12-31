// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./JBBallotState.sol";
import "./JBFundAccessConstraints.sol";
import "./JBFundingCycle.sol";
import "./JBFundingCycleData.sol";
import "./JBFundingCycleMetadata.sol";
import "./JBGroupedSplits.sol";
import "./JBProjectMetadata.sol";
import "./JBSplit.sol";
import "./IJBController3_0_1.sol";
import "./IJBDirectory.sol";
import "./IJBFundAccessConstraintsStore.sol";
import "./IJBFundingCycleStore.sol";
import "./IJBMigratable.sol";
import "./IJBPaymentTerminal.sol";
import "./IJBProjects.sol";
import "./IJBSplitsStore.sol";
import "./IJBTokenStore.sol";

interface IJBController3_1 is IJBController3_0_1, IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function fundAccessConstraintsStore() external view returns (IJBFundAccessConstraintsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 projectId) external view returns (uint256);

  function totalOutstandingTokensOf(uint256 projectId) external view returns (uint256);

  function getFundingCycleOf(
    uint256 projectId,
    uint256 configuration
  )
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(
    uint256 projectId
  )
    external
    view
    returns (JBFundingCycle memory, JBFundingCycleMetadata memory metadata, JBBallotState);

  function currentFundingCycleOf(
    uint256 projectId
  )
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(
    uint256 projectId
  )
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address owner,
    JBProjectMetadata calldata projectMetadata,
    JBFundingCycleData calldata data,
    JBFundingCycleMetadata calldata metadata,
    uint256 mustStartAtOrAfter,
    JBGroupedSplits[] memory groupedSplits,
    JBFundAccessConstraints[] memory fundAccessConstraints,
    IJBPaymentTerminal[] memory terminals,
    string calldata memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 projectId,
    JBFundingCycleData calldata data,
    JBFundingCycleMetadata calldata metadata,
    uint256 mustStartAtOrAfter,
    JBGroupedSplits[] memory groupedSplits,
    JBFundAccessConstraints[] memory fundAccessConstraints,
    IJBPaymentTerminal[] memory terminals,
    string calldata memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 projectId,
    JBFundingCycleData calldata data,
    JBFundingCycleMetadata calldata metadata,
    uint256 mustStartAtOrAfter,
    JBGroupedSplits[] memory groupedSplits,
    JBFundAccessConstraints[] memory fundAccessConstraints,
    string calldata memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 projectId,
    uint256 tokenCount,
    address beneficiary,
    string calldata memo,
    bool preferClaimedTokens,
    bool useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address holder,
    uint256 projectId,
    uint256 tokenCount,
    string calldata memo,
    bool preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(
    uint256 projectId,
    string memory memo
  ) external returns (uint256);

  function migrate(uint256 projectId, IJBMigratable to) external;
}
