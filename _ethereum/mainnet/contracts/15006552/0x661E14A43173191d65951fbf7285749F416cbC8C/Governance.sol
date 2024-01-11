// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Strings.sol";
import "./Proposal.sol";
import "./GlobalProposal.sol";
import "./Ballot.sol";
import "./SignatureConsumer.sol";

abstract contract Governance is SignatureConsumer {
  using Proposal for Proposal.ProposalDetail;
  using GlobalProposal for GlobalProposal.GlobalProposalDetail;
  enum VoteStatus {
    Pending,
    Approved,
    Executed,
    Rejected
  }

  struct ProposalVote {
    VoteStatus status;
    bytes32 hash;
    uint256 againstVoteWeight; // Total weight of against votes
    uint256 forVoteWeight; // Total weight of for votes
    mapping(address => bool) forVoted;
    mapping(address => bool) againstVoted;
    mapping(address => Signature) sig;
  }

  /// @dev Emitted when a proposal is created
  event ProposalCreated(
    uint256 indexed chainId,
    uint256 indexed round,
    bytes32 indexed proposalHash,
    Proposal.ProposalDetail proposal,
    address creator
  );
  /// @dev Emitted when a proposal is created
  event GlobalProposalCreated(
    uint256 indexed round,
    bytes32 indexed proposalHash,
    Proposal.ProposalDetail proposal,
    bytes32 globalProposalHash,
    GlobalProposal.GlobalProposalDetail globalProposal,
    address creator
  );
  /// @dev Emitted when the proposal is voted
  event ProposalVoted(bytes32 indexed proposalHash, address indexed voter, Ballot.VoteType support, uint256 weight);
  /// @dev Emitted when the proposal is approved
  event ProposalApproved(bytes32 indexed proposalHash);
  /// @dev Emitted when the vote is reject
  event ProposalRejected(bytes32 indexed proposalHash);
  /// @dev Emitted when the proposal is executed
  event ProposalExecuted(bytes32 indexed proposalHash);

  /// @dev Mapping from chain id => vote round
  /// @notice chain id = 0 for global proposal
  mapping(uint256 => uint256) public round;
  /// @dev Mapping from chain id => vote round => proposal vote
  mapping(uint256 => mapping(uint256 => ProposalVote)) public vote;

  /**
   * @dev Creates new round voting for the proposal `_proposalHash` of chain `_chainId`.
   */
  function _createVotingRound(uint256 _chainId, bytes32 _proposalHash) internal returns (uint256 _round) {
    _round = round[_chainId]++;
    // Skip checking for the first ever round
    if (_round > 0) {
      require(vote[_chainId][_round].status != VoteStatus.Pending, "Governance: current proposal is not completed");
    }
    vote[_chainId][++_round].hash = _proposalHash;
  }

  /**
   * @dev Proposes for a new proposal.
   *
   * Requirements:
   * - The chain id is not equal to 0.
   *
   * Emits the `ProposalCreated` event.
   *
   */
  function _proposeProposal(
    uint256 _chainId,
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    address _creator
  ) internal virtual returns (uint256 _round) {
    require(_chainId != 0, "Governance: invalid chain id");

    Proposal.ProposalDetail memory _proposal = Proposal.ProposalDetail(
      round[_chainId] + 1,
      _chainId,
      _targets,
      _values,
      _calldatas
    );
    _proposal.validate();

    bytes32 _proposalHash = _proposal.hash();
    _round = _createVotingRound(_chainId, _proposalHash);
    emit ProposalCreated(_chainId, _round, _proposalHash, _proposal, _creator);
  }

  /**
   * @dev Proposes proposal struct.
   *
   * Requirements:
   * - The chain id is not equal to 0.
   * - The proposal nonce is equal to the new round.
   *
   * Emits the `ProposalCreated` event.
   *
   */
  function _proposeProposalStruct(Proposal.ProposalDetail memory _proposal, address _creator)
    internal
    virtual
    returns (uint256 _round)
  {
    uint256 _chainId = _proposal.chainId;
    require(_chainId != 0, "Governance: invalid chain id");
    _proposal.validate();

    bytes32 _proposalHash = _proposal.hash();
    _round = _createVotingRound(_chainId, _proposalHash);
    require(_round == _proposal.nonce, "Governance: invalid proposal nonce");
    emit ProposalCreated(_chainId, _round, _proposalHash, _proposal, _creator);
  }

  /**
   * @dev Proposes for a global proposal.
   *
   * Emits the `GlobalProposalCreated` event.
   *
   */
  function _proposeGlobal(
    GlobalProposal.TargetOption[] calldata _targetOptions,
    uint256[] memory _values,
    bytes[] memory _calldatas,
    address _validatorContract,
    address _gatewayContract,
    address _creator
  ) internal virtual returns (uint256 _round) {
    GlobalProposal.GlobalProposalDetail memory _globalProposal = GlobalProposal.GlobalProposalDetail(
      round[0] + 1,
      _targetOptions,
      _values,
      _calldatas
    );
    Proposal.ProposalDetail memory _proposal = _globalProposal.into_proposal_detail(
      _validatorContract,
      _gatewayContract
    );
    _proposal.validate();

    bytes32 _proposalHash = _proposal.hash();
    _round = _createVotingRound(0, _proposalHash);
    emit GlobalProposalCreated(_round, _proposalHash, _proposal, _globalProposal.hash(), _globalProposal, _creator);
  }

  /**
   * @dev Proposes global proposal struct.
   *
   * Requirements:
   * - The proposal nonce is equal to the new round.
   *
   * Emits the `GlobalProposalCreated` event.
   *
   */
  function _proposeGlobalStruct(
    GlobalProposal.GlobalProposalDetail memory _globalProposal,
    address _validatorContract,
    address _gatewayContract,
    address _creator
  ) internal virtual returns (Proposal.ProposalDetail memory _proposal, uint256 _round) {
    _proposal = _globalProposal.into_proposal_detail(_validatorContract, _gatewayContract);
    _proposal.validate();

    bytes32 _proposalHash = _proposal.hash();
    _round = _createVotingRound(0, _proposalHash);
    require(_round == _proposal.nonce, "Governance: invalid proposal nonce");
    emit GlobalProposalCreated(_round, _proposalHash, _proposal, _globalProposal.hash(), _globalProposal, _creator);
  }

  /**
   * @dev Casts vote for the proposal with data and returns whether the voting is done.
   *
   * Requirements:
   * - The proposal nonce is equal to the round.
   * - The vote is not finalized.
   * - The voter has not voted for the round.
   *
   * Emits the `ProposalVoted` event. Emits the `ProposalApproved`, `ProposalExecuted` or `ProposalRejected` once the
   * proposal is approved, executed or rejected.
   *
   */
  function _castVote(
    Proposal.ProposalDetail memory _proposal,
    Ballot.VoteType _support,
    uint256 _minimumForVoteWeight,
    uint256 _minimumAgainstVoteWeight,
    address _voter,
    Signature memory _signature,
    uint256 _voterWeight
  ) internal virtual returns (bool _done) {
    uint256 _chainId = _proposal.chainId;
    uint256 _round = _proposal.nonce;
    ProposalVote storage _vote = vote[_chainId][_round];

    require(round[_proposal.chainId] == _round, "Governance: query for invalid proposal nonce");
    require(_vote.status == VoteStatus.Pending, "Governance: the vote is finalized");
    if (_vote.forVoted[_voter] || _vote.againstVoted[_voter]) {
      revert(string(abi.encodePacked("Governance: ", Strings.toHexString(uint160(_voter), 20), " already voted")));
    }

    _vote.sig[_voter] = _signature;
    emit ProposalVoted(_vote.hash, _voter, _support, _voterWeight);

    uint256 _forVoteWeight;
    uint256 _againstVoteWeight;
    if (_support == Ballot.VoteType.For) {
      _vote.forVoted[_voter] = true;
      _forVoteWeight = _vote.forVoteWeight += _voterWeight;
    } else if (_support == Ballot.VoteType.Against) {
      _vote.againstVoted[_voter] = true;
      _againstVoteWeight = _vote.againstVoteWeight += _voterWeight;
    } else {
      revert("Governance: unsupported vote type");
    }

    if (_forVoteWeight >= _minimumForVoteWeight) {
      _done = true;
      _vote.status = VoteStatus.Approved;
      emit ProposalApproved(_vote.hash);

      if (_proposal.executable()) {
        _vote.status = VoteStatus.Executed;
        emit ProposalExecuted(_vote.hash);
        _proposal.execute();
      }
    } else if (_againstVoteWeight >= _minimumAgainstVoteWeight) {
      _done = true;
      _vote.status = VoteStatus.Rejected;
      emit ProposalRejected(_vote.hash);
    }
  }

  /**
   * @dev Casts votes by signatures.
   *
   * @notice This method does not verify the proposal hash with the vote hash. Please consider checking it before.
   *
   */
  function _castVotesBySignatures(
    Proposal.ProposalDetail memory _proposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures,
    bytes32 _forDigest,
    bytes32 _againstDigest
  ) internal {
    require(_supports.length > 0 && _supports.length == _signatures.length, "Governance: invalid array length");
    uint256 _minimumForVoteWeight = _getMinimumVoteWeight();
    uint256 _minimumAgainstVoteWeight = _getTotalWeights() - _minimumForVoteWeight + 1;

    address _lastSigner;
    address _signer;
    Signature memory _sig;
    bool _hasValidVotes;
    for (uint256 _i; _i < _signatures.length; _i++) {
      _sig = _signatures[_i];

      if (_supports[_i] == Ballot.VoteType.For) {
        _signer = ECDSA.recover(_forDigest, _sig.v, _sig.r, _sig.s);
      } else if (_supports[_i] == Ballot.VoteType.Against) {
        _signer = ECDSA.recover(_againstDigest, _sig.v, _sig.r, _sig.s);
      } else {
        revert("Governance: query for unsupported vote type");
      }

      require(_lastSigner < _signer, "Governance: invalid order");
      _lastSigner = _signer;

      uint256 _weight = _getWeight(_signer);
      if (_weight > 0) {
        _hasValidVotes = true;
        if (
          _castVote(_proposal, _supports[_i], _minimumForVoteWeight, _minimumAgainstVoteWeight, _signer, _sig, _weight)
        ) {
          return;
        }
      }
    }

    require(_hasValidVotes, "Governance: invalid signatures");
  }

  /**
   * @dev Relays votes by signatures.
   *
   * @notice Does not store the voter signature into storage.
   *
   */
  function _relayVotesBySignatures(
    Proposal.ProposalDetail memory _proposal,
    Ballot.VoteType[] calldata _supports,
    Signature[] calldata _signatures,
    bytes32 _forDigest,
    bytes32 _againstDigest
  ) internal {
    require(_supports.length > 0 && _supports.length == _signatures.length, "Governance: invalid array length");
    uint256 _forVoteCount;
    uint256 _againstVoteCount;
    address[] memory _forVoteSigners = new address[](_signatures.length);
    address[] memory _againstVoteSigners = new address[](_signatures.length);

    {
      address _signer;
      address _lastSigner;
      Ballot.VoteType _support;
      Signature memory _sig;

      for (uint256 _i; _i < _signatures.length; _i++) {
        _sig = _signatures[_i];
        _support = _supports[_i];

        if (_support == Ballot.VoteType.For) {
          _signer = ECDSA.recover(_forDigest, _sig.v, _sig.r, _sig.s);
          _forVoteSigners[_forVoteCount++] = _signer;
        } else if (_support == Ballot.VoteType.Against) {
          _signer = ECDSA.recover(_againstDigest, _sig.v, _sig.r, _sig.s);
          _againstVoteSigners[_againstVoteCount++] = _signer;
        } else {
          revert("Governance: query for unsupported vote type");
        }

        require(_lastSigner < _signer, "Governance: invalid order");
        _lastSigner = _signer;
      }
    }

    assembly {
      mstore(_forVoteSigners, _forVoteCount)
      mstore(_againstVoteSigners, _againstVoteCount)
    }

    ProposalVote storage _vote = vote[_proposal.chainId][_proposal.nonce];
    uint256 _minimumForVoteWeight = _getMinimumVoteWeight();
    uint256 _totalForVoteWeight = _getWeights(_forVoteSigners);
    if (_totalForVoteWeight >= _minimumForVoteWeight) {
      require(_totalForVoteWeight > 0, "Governance: invalid vote weight");
      _vote.status = VoteStatus.Approved;
      emit ProposalApproved(_vote.hash);

      if (_proposal.executable()) {
        _vote.status = VoteStatus.Executed;
        emit ProposalExecuted(_vote.hash);
        _proposal.execute();
      }
      return;
    }

    uint256 _minimumAgainstVoteWeight = _getTotalWeights() - _minimumForVoteWeight + 1;
    uint256 _totalAgainstVoteWeight = _getWeights(_againstVoteSigners);
    if (_totalAgainstVoteWeight >= _minimumAgainstVoteWeight) {
      require(_totalAgainstVoteWeight > 0, "Governance: invalid vote weight");
      _vote.status = VoteStatus.Rejected;
      emit ProposalRejected(_vote.hash);
      return;
    }

    revert("Governance: relay failed");
  }

  /**
   * @dev Returns weight of the govenor.
   */
  function _getWeight(address _governor) internal view virtual returns (uint256) {}

  /**
   * @dev Returns weight of the govenor.
   */
  function _getWeights(address[] memory _governors) internal view virtual returns (uint256) {}

  /**
   * @dev Returns total weight from validators.
   */
  function _getTotalWeights() internal view virtual returns (uint256) {}

  /**
   * @dev Returns minimum vote to pass a proposal.
   */
  function _getMinimumVoteWeight() internal view virtual returns (uint256) {}
}
