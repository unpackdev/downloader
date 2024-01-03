// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IAaveGovernanceV2.sol";

interface IGovernanceV2Helper {
  struct ProposalStats {
    uint256 minimumQuorum;
    uint256 minimumDiff;
    uint256 executionTimeWithGracePeriod;
    uint256 proposalCreated;
  }

  function getProposals(
    uint256 skip,
    uint256 limit,
    IAaveGovernanceV2 governance
  )
    external
    virtual
    view
    returns (
      IAaveGovernanceV2.ProposalWithoutVotes[] memory proposals,
      IAaveGovernanceV2.ProposalState[] memory proposalsState,
      ProposalStats[] memory proposalsStats
    );

  function getProposal(uint256 id, IAaveGovernanceV2 governance)
    external
    virtual
    view
    returns (
      IAaveGovernanceV2.ProposalWithoutVotes memory proposal,
      IAaveGovernanceV2.ProposalState proposalState,
      ProposalStats memory proposalStats
    );
}
