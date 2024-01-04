// SPDX-License-Identifier: MIT
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;


/**
 * @title MetaGovernorUNI
 * @dev Meta-governance contract for Uniswap's GovernorAlpha.
 *
 * This contract enables NDX holders to vote, by simple majority, on how to cast
 * votes for Uniswap governance proposals.
 *
 * Each Uniswap proposal is wrapped as a meta proposal, which has an endBlock which
 * ends some number of blocks prior to the end of the real proposal in order to give
 * NDX holders time to cast meta votes prior to casting votes for the entire dao.
 *
 * This contract counts voting power from users the same way as the typical GovernorAlpha,
 * which is to call getPriorVotes to check the delegation a voting account held at the time
 * the external proposal began.
 *
 * Once a meta proposal has ended, it may be executed to cast votes on Uniswap. If the proposal
 * has more votes in favor than against, it will cast votes supporting the proposal. Otherwise,
 * it will cast votes against the proposal.
 *
 * This contract may not be used to submit proposals to Uniswap, only to vote on them.
 */
contract MetaGovernorUNI {
  /** @dev The name of this contract */
  string public constant name = "Indexed UNI Meta Governor";

  /**
   * @dev The number of blocks subtracted from the endBlock of an external
   * proposal to set the end block of a meta proposal.
   */
  uint32 public immutable votingGracePeriod;

  /** @dev The address of the Indexed governance token */
  NdxInterface public immutable ndx;


  /** @dev The address of the UNI GovernorAlpha */
  IGovernorAlpha public immutable uniGovernor;

  /**
   * @param startBlock The block at which voting begins: holders must delegate their votes prior to this block
   * @param endBlock The block at which voting ends: votes must be cast prior to this block
   * @param forVotes Current number of votes in favor of this proposal
   * @param againstVotes Current number of votes in opposition to this proposal
   * @param voteSubmitted Flag marking whether the vote has been cast on the external governor
   * @param receipts Receipts of ballots for the entire set of voters
   */
  struct MetaProposal {
    uint32 startBlock;
    uint32 endBlock;
    uint96 forVotes;
    uint96 againstVotes;
    bool voteSubmitted;
    mapping(address => Receipt) receipts;
  }

  /**
   * @dev Possible states that a meta proposal may be in
   */
  enum MetaProposalState {
    Active,
    Defeated,
    Succeeded,
    Executed
  }

  mapping(uint256 => MetaProposal) public proposals;

  /**
   * @dev Ballot receipt record for a voter
   * @param hasVoted Whether or not a vote has been cast
   * @param support Whether or not the voter supports the proposal
   * @param votes The number of votes the voter had, which were cast
   */
  struct Receipt {
    bool hasVoted;
    bool support;
    uint96 votes;
  }

  /**
   * @dev An event emitted when a vote has been cast on a proposal
   */
  event MetaVoteCast(
    address voter,
    uint256 proposalId,
    bool support,
    uint256 votes
  );

  event ExternalVoteSubmitted(
    uint256 proposalId,
    bool support
  );

  constructor(address ndx_, address uniGovernor_, uint32 votingGracePeriod_) public {
    ndx = NdxInterface(ndx_);
    uniGovernor = IGovernorAlpha(uniGovernor_);
    votingGracePeriod = votingGracePeriod_;
  }

  function getReceipt(uint256 proposalId, address voter)
    external
    view
    returns (Receipt memory)
  {
    return proposals[proposalId].receipts[voter];
  }

  function submitExternalVote(uint256 proposalId) external {
    MetaProposal storage proposal = proposals[proposalId];
    MetaProposalState state = _state(proposal);
    require(
      state == MetaProposalState.Succeeded || state == MetaProposalState.Defeated,
      "MetaGovernorUNI::submitExternalVote: proposal must be in Succeeded or Defeated state to execute"
    );
    proposal.voteSubmitted = true;
    bool support = state == MetaProposalState.Succeeded;
    uniGovernor.castVote(proposalId, support);
    emit ExternalVoteSubmitted(proposalId, support);
  }

  function _getMetaProposal(uint256 proposalId) internal returns (MetaProposal storage) {
    // Get the meta proposal if it exists, else initialize the block fields using the external proposal.
    MetaProposal storage proposal = proposals[proposalId];
    if (proposal.startBlock == 0) {
      IGovernorAlpha.Proposal memory externalProposal = uniGovernor.proposals(proposalId);
      proposal.startBlock = safe32(externalProposal.startBlock);
      proposal.endBlock = sub32(safe32(externalProposal.endBlock), votingGracePeriod);
    }
    return proposal;
  }

  function castVote(uint256 proposalId, bool support) external {
    MetaProposal storage proposal = _getMetaProposal(proposalId);
    require(
      _state(proposal) == MetaProposalState.Active,
      "MetaGovernorUNI::_castVote: meta proposal not active"
    );
    Receipt storage receipt = proposal.receipts[msg.sender];
    require(
      receipt.hasVoted == false,
      "MetaGovernorUNI::_castVote: voter already voted"
    );
    uint96 votes = ndx.getPriorVotes(msg.sender, proposal.startBlock);
    require(
      votes > 0,
      "MetaGovernorUNI::_castVote: caller has no delegated NDX"
    );

    if (support) {
      proposal.forVotes = add96(proposal.forVotes, votes);
    } else {
      proposal.againstVotes = add96(proposal.againstVotes, votes);
    }

    receipt.hasVoted = true;
    receipt.support = support;
    receipt.votes = votes;

    emit MetaVoteCast(msg.sender, proposalId, support, votes);
  }

  function state(uint256 proposalId) external view returns (MetaProposalState) {
    MetaProposal storage proposal = proposals[proposalId];
    return _state(proposal);
  }

  function _state(MetaProposal storage proposal) internal view returns (MetaProposalState) {
    require(
      proposal.startBlock != 0 && block.number > proposal.startBlock,
      "MetaGovernorUNI::_state: meta proposal does not exist or is not ready"
    );
    if (block.number <= proposal.endBlock) {
      return MetaProposalState.Active;
    } else if (proposal.voteSubmitted) {
      return MetaProposalState.Executed;
    } else if (proposal.forVotes > proposal.againstVotes) {
      return MetaProposalState.Succeeded;
    }
    return MetaProposalState.Defeated;
  }

  function add96(uint96 a, uint96 b) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, "addition overflow");
    return c;
  }

  function safe32(uint256 a) internal pure returns (uint32) {
    require(a <= uint32(-1), "uint32 overflow");
    return uint32(a);
  }

  function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
    require(b <= a, "subtraction underflow");
    return a - b;
  }
}


interface IGovernorAlpha {
  struct Proposal {
    uint256 id;
    address proposer;
    uint256 eta;
    uint256 startBlock;
    uint256 endBlock;
    uint256 forVotes;
    uint256 againstVotes;
    bool canceled;
    bool executed;
  }

  function proposals(uint256 proposalId) external view returns (Proposal memory);

  function castVote(uint256 proposalId, bool support) external;
}


interface NdxInterface {
  function getPriorVotes(address account, uint256 blockNumber)
    external
    view
    returns (uint96);
}