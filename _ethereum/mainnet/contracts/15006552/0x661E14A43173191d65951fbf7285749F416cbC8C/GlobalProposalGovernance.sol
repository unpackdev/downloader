// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Governance.sol";

abstract contract GlobalProposalGovernance is Governance {
  using Proposal for Proposal.ProposalDetail;
  using GlobalProposal for GlobalProposal.GlobalProposalDetail;

  /**
   * @dev Proposes and votes by signature.
   */
  function _proposeGlobalProposalStructAndCastVotes(
    GlobalProposal.GlobalProposalDetail calldata _globalProposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures,
    bytes32 _domainSeparator,
    address _validatorContract,
    address _gatewayContract,
    address _creator
  ) internal returns (Proposal.ProposalDetail memory _proposal) {
    (_proposal, ) = _proposeGlobalStruct(_globalProposal, _validatorContract, _gatewayContract, _creator);
    bytes32 _globalProposalHash = _globalProposal.hash();
    _castVotesBySignatures(
      _proposal,
      _supports,
      _signatures,
      ECDSA.toTypedDataHash(_domainSeparator, Ballot.hash(_globalProposalHash, Ballot.VoteType.For)),
      ECDSA.toTypedDataHash(_domainSeparator, Ballot.hash(_globalProposalHash, Ballot.VoteType.Against))
    );
  }

  /**
   * @dev Proposes a global proposal struct and casts votes by signature.
   */
  function _castGlobalProposalBySignatures(
    GlobalProposal.GlobalProposalDetail calldata _globalProposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures,
    bytes32 _domainSeparator,
    address _validatorContract,
    address _gatewayContract
  ) internal {
    Proposal.ProposalDetail memory _proposal = _globalProposal.into_proposal_detail(
      _validatorContract,
      _gatewayContract
    );
    bytes32 _globalProposalHash = _globalProposal.hash();
    require(vote[0][_proposal.nonce].hash == _proposal.hash(), "GovernanceAdmin: cast vote for invalid proposal");
    _castVotesBySignatures(
      _proposal,
      _supports,
      _signatures,
      ECDSA.toTypedDataHash(_domainSeparator, Ballot.hash(_globalProposalHash, Ballot.VoteType.For)),
      ECDSA.toTypedDataHash(_domainSeparator, Ballot.hash(_globalProposalHash, Ballot.VoteType.Against))
    );
  }

  /**
   * @dev Relays voted global proposal.
   *
   * Requirements:
   * - The relay proposal is finalized.
   *
   */
  function _relayGlobalProposal(
    GlobalProposal.GlobalProposalDetail calldata _globalProposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures,
    bytes32 _domainSeparator,
    address _validatorContract,
    address _gatewayContract,
    address _creator
  ) internal {
    (Proposal.ProposalDetail memory _proposal, ) = _proposeGlobalStruct(
      _globalProposal,
      _validatorContract,
      _gatewayContract,
      _creator
    );
    bytes32 _globalProposalHash = _globalProposal.hash();
    _relayVotesBySignatures(
      _proposal,
      _supports,
      _signatures,
      ECDSA.toTypedDataHash(_domainSeparator, Ballot.hash(_globalProposalHash, Ballot.VoteType.For)),
      ECDSA.toTypedDataHash(_domainSeparator, Ballot.hash(_globalProposalHash, Ballot.VoteType.Against))
    );
  }
}
