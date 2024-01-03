// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import "./IAaveGovernanceV2.sol";
import "./IProposalValidator.sol";
import "./IExecutorWithTimelock.sol";
import "./IGovernanceStrategy.sol";
import "./IGovernanceV2Helper.sol";
import "./SafeMath.sol";

/**
 * @title Governance V2 helper contract
 * @dev Allows to easily read data from AaveGovernanceV2 contract
 * - List of proposals with state
 * - List of votes per proposal and voters
 * @author Aave
 **/
contract GovernanceV2Helper is IGovernanceV2Helper {
  using SafeMath for uint256;
  uint256 public constant ONE_HUNDRED_WITH_PRECISION = 10000;

  function getProposals(
    uint256 skip,
    uint256 limit,
    IAaveGovernanceV2 governance
  )
    external
    override
    view
    returns (
      IAaveGovernanceV2.ProposalWithoutVotes[] memory proposals,
      IAaveGovernanceV2.ProposalState[] memory proposalsState,
      ProposalStats[] memory proposalsStats
    )
  {
    uint256 count = governance.getProposalsCount().sub(skip);
    uint256 maxLimit = limit > count ? count : limit;

    proposals = new IAaveGovernanceV2.ProposalWithoutVotes[](maxLimit);
    proposalsState = new IAaveGovernanceV2.ProposalState[](maxLimit);
    proposalsStats = new ProposalStats[](maxLimit);

    for (uint256 i = 0; i < maxLimit; i++) {
      proposals[i] = governance.getProposalById(i.add(skip));
      uint256 votingSupply = IGovernanceStrategy(proposals[i].strategy).getTotalVotingSupplyAt(
        proposals[i].startBlock
      );
      proposalsState[i] = governance.getProposalState(i.add(skip));
      proposalsStats[i] = ProposalStats(
        IProposalValidator(address(proposals[i].executor)).getMinimumVotingPowerNeeded(
          votingSupply
        ),
        proposals[i].againstVotes.mul(ONE_HUNDRED_WITH_PRECISION).div(votingSupply).add(
          IProposalValidator(address(proposals[i].executor)).VOTE_DIFFERENTIAL()
        ),
        proposals[i].executionTime > 0
          ? IExecutorWithTimelock(proposals[i].executor).GRACE_PERIOD().add(
            proposals[i].executionTime
          )
          : proposals[i].executionTime,
        proposals[i].startBlock.sub(governance.getVotingDelay())
      );
    }

    return (proposals, proposalsState, proposalsStats);
  }

  function getProposal(uint256 id, IAaveGovernanceV2 governance)
    external
    override
    view
    returns (
      IAaveGovernanceV2.ProposalWithoutVotes memory proposal,
      IAaveGovernanceV2.ProposalState proposalState,
      ProposalStats memory proposalStats
    )
  {
    proposal = governance.getProposalById(id);
    uint256 votingSupply = IGovernanceStrategy(proposal.strategy).getTotalVotingSupplyAt(
      proposal.startBlock
    );
    proposalState = governance.getProposalState(id);
    proposalStats = ProposalStats(
      IProposalValidator(address(proposal.executor)).getMinimumVotingPowerNeeded(votingSupply),
      proposal.againstVotes.mul(ONE_HUNDRED_WITH_PRECISION).div(votingSupply).add(
        IProposalValidator(address(proposal.executor)).VOTE_DIFFERENTIAL()
      ),
      proposal.executionTime > 0
        ? IExecutorWithTimelock(proposal.executor).GRACE_PERIOD().add(proposal.executionTime)
        : proposal.executionTime,
      proposal.startBlock.sub(governance.getVotingDelay())
    );
    return (proposal, proposalState, proposalStats);
  }
}
