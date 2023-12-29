// solhint-disable max-states-count
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "./IAMPH.sol";
import "./IGovernorCharlie.sol";

import "./GovernanceStructs.sol";

contract GovernorCharlie is IGovernorCharlie {
  /// @notice The name of this contract
  string public constant NAME = 'Amphora Protocol Governor';

  /// @notice The maximum number of actions that can be included in a proposal
  uint256 public constant PROPOSAL_MAX_OPERATIONS = 10;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

  /// @notice The EIP-712 typehash for the ballot struct used by the contract
  bytes32 public constant BALLOT_TYPEHASH = keccak256('Ballot(uint256 proposalId,uint8 support)');

  /// @notice The time for a proposal to be executed after passing
  uint256 public constant GRACE_PERIOD = 14 days;

  /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
  uint256 public quorumVotes;

  /// @notice The number of votes in support of a proposal required in order for an emergency quorum to be reached and for a vote to succeed
  uint256 public emergencyQuorumVotes;

  /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
  uint256 public votingDelay;

  /// @notice The duration of voting on a proposal, in blocks
  uint256 public votingPeriod;

  /// @notice The number of votes required in order for a voter to become a proposer
  uint256 public proposalThreshold;

  /// @notice Initial proposal id set at become
  uint256 public initialProposalId;

  /// @notice The total number of proposals
  uint256 public proposalCount;

  /// @notice The address of the Amphora Protocol governance token
  IAMPH public amph;

  /// @notice The official record of all proposals ever proposed
  mapping(uint256 => Proposal) public proposals;

  /// @notice The latest proposal for each proposer
  mapping(address => uint256) public latestProposalIds;

  /// @notice The mapping that saves queued transactions
  mapping(bytes32 => bool) public queuedTransactions;

  /// @notice The proposal holding period
  uint256 public proposalTimelockDelay;

  /// @notice Stores the expiration of account whitelist status as a timestamp
  mapping(address => uint256) public whitelistAccountExpirations;

  /// @notice Address which manages whitelisted proposals and whitelist accounts
  address public whitelistGuardian;

  /// @notice The duration of the voting on a emergency proposal, in blocks
  uint256 public emergencyVotingPeriod;

  /// @notice The emergency proposal holding period
  uint256 public emergencyTimelockDelay;

  /// @notice all receipts for proposal
  mapping(uint256 => mapping(address => Receipt)) public proposalReceipts;

  /// @notice The number of votes to reject an optimistic proposal
  uint256 public optimisticQuorumVotes;

  /// @notice The delay period before voting begins
  uint256 public optimisticVotingDelay;

  /// @notice The maximum number of seconds an address can be whitelisted for
  uint256 public maxWhitelistPeriod;

  constructor(address _amph) {
    amph = IAMPH(_amph);
    votingPeriod = 1 days;
    votingDelay = 4 hours;
    proposalTimelockDelay = 2 days;
    proposalThreshold = 1_000_000 ether;
    quorumVotes = 2_000_000 ether;

    emergencyQuorumVotes = 400_000_000 ether;
    emergencyVotingPeriod = 6 hours;
    emergencyTimelockDelay = 1 days;

    optimisticQuorumVotes = 2_000_000 ether;
    optimisticVotingDelay = 7 hours;
    maxWhitelistPeriod = 365 days;

    proposalCount = 0;
  }

  /// @notice any function with this modifier can only be called by governance
  modifier onlyGov() {
    if (msg.sender != address(this)) revert GovernorCharlie_NotGovernorCharlie();
    _;
  }

  // @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
  // @param _targets Target addresses for proposal calls
  // @param _values Eth values for proposal calls
  // @param _signatures Function signatures for proposal calls
  // @param _calldatas Calldatas for proposal calls
  // @param _description String description of the proposal
  // @return _proposalId Proposal id of new proposal
  function propose(
    address[] memory _targets,
    uint256[] memory _values,
    string[] memory _signatures,
    bytes[] memory _calldatas,
    string memory _description
  ) public override returns (uint256 _proposalId) {
    _proposalId = _propose(_targets, _values, _signatures, _calldatas, _description, false);
  }

  // @notice Function used to propose a new emergency proposal. Sender must have delegates above the proposal threshold
  // @param _targets Target addresses for proposal calls
  // @param _values Eth values for proposal calls
  // @param _signatures Function signatures for proposal calls
  // @param _calldatas Calldatas for proposal calls
  // @param _description String description of the proposal
  // @return _proposalId Proposal id of new proposal
  function proposeEmergency(
    address[] memory _targets,
    uint256[] memory _values,
    string[] memory _signatures,
    bytes[] memory _calldatas,
    string memory _description
  ) public override returns (uint256 _proposalId) {
    _proposalId = _propose(_targets, _values, _signatures, _calldatas, _description, true);
  }

  // @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
  // @param _targets Target addresses for proposal calls
  // @param _values Eth values for proposal calls
  // @param _signatures Function signatures for proposal calls
  // @param _calldatas Calldatas for proposal calls
  // @param _description String description of the proposal
  // @param _emergency Bool to determine if proposal an emergency proposal
  // @return _proposalId Proposal id of new proposal
  function _propose(
    address[] memory _targets,
    uint256[] memory _values,
    string[] memory _signatures,
    bytes[] memory _calldatas,
    string memory _description,
    bool _emergency
  ) internal returns (uint256 _proposalId) {
    // Reject proposals before initiating as Governor
    if (quorumVotes == 0) revert GovernorCharlie_NotActive();
    // Allow addresses above proposal threshold and whitelisted addresses to propose
    if (amph.getPriorVotes(msg.sender, (block.number - 1)) < proposalThreshold && !isWhitelisted(msg.sender)) {
      revert GovernorCharlie_VotesBelowThreshold();
    }
    if (
      _targets.length != _values.length || _targets.length != _signatures.length || _targets.length != _calldatas.length
    ) revert GovernorCharlie_ArityMismatch();
    if (_targets.length == 0) revert GovernorCharlie_NoActions();
    if (_targets.length > PROPOSAL_MAX_OPERATIONS) revert GovernorCharlie_TooManyActions();

    uint256 _latestProposalId = latestProposalIds[msg.sender];
    if (_latestProposalId != 0) {
      ProposalState _proposersLatestProposalState = state(_latestProposalId);
      if (_proposersLatestProposalState == ProposalState.Active) revert GovernorCharlie_MultipleActiveProposals();
      if (_proposersLatestProposalState == ProposalState.Pending) revert GovernorCharlie_MultiplePendingProposals();
    }

    proposalCount++;
    Proposal memory _newProposal = Proposal({
      id: proposalCount,
      proposer: msg.sender,
      eta: 0,
      targets: _targets,
      values: _values,
      signatures: _signatures,
      calldatas: _calldatas,
      startBlock: block.number + votingDelay,
      endBlock: block.number + votingDelay + votingPeriod,
      forVotes: 0,
      againstVotes: 0,
      abstainVotes: 0,
      canceled: false,
      executed: false,
      emergency: _emergency,
      quorumVotes: quorumVotes,
      delay: proposalTimelockDelay
    });

    //whitelist can't make emergency
    if (_emergency && !isWhitelisted(msg.sender)) {
      _newProposal.startBlock = block.number;
      _newProposal.endBlock = block.number + emergencyVotingPeriod;
      _newProposal.quorumVotes = emergencyQuorumVotes;
      _newProposal.delay = emergencyTimelockDelay;
    }

    //whitelist can only make optimistic proposals
    if (isWhitelisted(msg.sender)) {
      _newProposal.quorumVotes = optimisticQuorumVotes;
      _newProposal.startBlock = block.number + optimisticVotingDelay;
      _newProposal.endBlock = block.number + optimisticVotingDelay + votingPeriod;
    }

    proposals[_newProposal.id] = _newProposal;
    latestProposalIds[_newProposal.proposer] = _newProposal.id;

    emit ProposalCreatedIndexed(
      _newProposal.id,
      msg.sender,
      _targets,
      _values,
      _signatures,
      _calldatas,
      _newProposal.startBlock,
      _newProposal.endBlock,
      _description
    );

    emit ProposalCreated(
      _newProposal.id,
      msg.sender,
      _targets,
      _values,
      _signatures,
      _calldatas,
      _newProposal.startBlock,
      _newProposal.endBlock,
      _description
    );
    _proposalId = _newProposal.id;
  }

  // @notice Queues a proposal of state succeeded
  // @param _proposalId The id of the proposal to queue
  function queue(uint256 _proposalId) external override {
    if (state(_proposalId) != ProposalState.Succeeded) revert GovernorCharlie_ProposalNotSucceeded();
    Proposal storage _proposal = proposals[_proposalId];
    uint256 _eta = block.timestamp + _proposal.delay;
    for (uint256 _i = 0; _i < _proposal.targets.length; _i++) {
      if (
        queuedTransactions[keccak256(
          abi.encode(
            _proposal.targets[_i], _proposal.values[_i], _proposal.signatures[_i], _proposal.calldatas[_i], _eta
          )
        )]
      ) revert GovernorCharlie_ProposalAlreadyQueued();
      _queueTransaction(
        _proposal.targets[_i],
        _proposal.values[_i],
        _proposal.signatures[_i],
        _proposal.calldatas[_i],
        _eta,
        _proposal.delay
      );
    }
    _proposal.eta = _eta;
    emit ProposalQueuedIndexed(_proposalId, _eta);
    emit ProposalQueued(_proposalId, _eta);
  }

  /// @notice Queues a transaction
  /// @param _target Target address for transaction
  /// @param _value Eth value for transaction
  /// @param _signature Function signature for transaction
  /// @param _data Calldata for transaction
  /// @param _eta Timestamp for transaction
  /// @param _delay Delay for transaction
  /// @return _txHash Transaction hash
  function _queueTransaction(
    address _target,
    uint256 _value,
    string memory _signature,
    bytes memory _data,
    uint256 _eta,
    uint256 _delay
  ) internal returns (bytes32 _txHash) {
    if (_eta < (_getBlockTimestamp() + _delay)) revert GovernorCharlie_DelayNotReached();

    _txHash = keccak256(abi.encode(_target, _value, _signature, _data, _eta));
    queuedTransactions[_txHash] = true;

    emit QueueTransaction(_txHash, _target, _value, _signature, _data, _eta);
  }

  // @notice Executes a queued proposal if eta has passed
  // @param _proposalId The id of the proposal to execute
  function execute(uint256 _proposalId) external payable override {
    if (state(_proposalId) != ProposalState.Queued) revert GovernorCharlie_ProposalNotQueued();
    Proposal storage _proposal = proposals[_proposalId];
    _proposal.executed = true;
    for (uint256 _i = 0; _i < _proposal.targets.length; _i++) {
      this.executeTransaction{value: _proposal.values[_i]}(
        _proposal.targets[_i], _proposal.values[_i], _proposal.signatures[_i], _proposal.calldatas[_i], _proposal.eta
      );
    }
    emit ProposalExecutedIndexed(_proposalId);
    emit ProposalExecuted(_proposalId);
  }

  /// @notice Executes a transaction
  /// @param _target Target address for transaction
  /// @param _value Eth value for transaction
  /// @param _signature Function signature for transaction
  /// @param _data Calldata for transaction
  /// @param _eta Timestamp for transaction
  function executeTransaction(
    address _target,
    uint256 _value,
    string memory _signature,
    bytes memory _data,
    uint256 _eta
  ) external payable override {
    if (msg.sender != address(this)) revert GovernorCharlie_NotGovernorCharlie();

    bytes32 _txHash = keccak256(abi.encode(_target, _value, _signature, _data, _eta));
    if (!queuedTransactions[_txHash]) revert GovernorCharlie_ProposalNotQueued();
    if (_getBlockTimestamp() < _eta) revert GovernorCharlie_TimelockNotReached();
    if (_getBlockTimestamp() > _eta + GRACE_PERIOD) revert GovernorCharlie_TransactionStale();

    queuedTransactions[_txHash] = false;

    bytes memory _callData;

    if (bytes(_signature).length == 0) _callData = _data;
    else _callData = abi.encodePacked(bytes4(keccak256(bytes(_signature))), _data);

    // solhint-disable-next-line avoid-low-level-calls
    (bool _success, /*bytes memory returnData*/ ) = _target.call{value: _value}(_callData);
    if (!_success) revert GovernorCharlie_TransactionReverted();

    emit ExecuteTransaction(_txHash, _target, _value, _signature, _data, _eta);
  }

  // @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
  // @notice whitelistGuardian can cancel proposals from whitelisted addresses
  // @param _proposalId The id of the proposal to cancel
  function cancel(uint256 _proposalId) external override {
    if (state(_proposalId) == ProposalState.Executed) revert GovernorCharlie_ProposalAlreadyExecuted();

    Proposal storage _proposal = proposals[_proposalId];

    // Proposer can cancel
    if (msg.sender != _proposal.proposer) {
      // Whitelisted proposers can't be canceled for falling below proposal threshold
      if (isWhitelisted(_proposal.proposer)) {
        if (
          (amph.getPriorVotes(_proposal.proposer, (block.number - 1)) >= proposalThreshold)
            || msg.sender != whitelistGuardian
        ) revert GovernorCharlie_WhitelistedProposer();
      } else {
        if ((amph.getPriorVotes(_proposal.proposer, (block.number - 1)) >= proposalThreshold)) {
          revert GovernorCharlie_ProposalAboveThreshold();
        }
      }
    }

    _proposal.canceled = true;
    for (uint256 _i = 0; _i < _proposal.targets.length; _i++) {
      _cancelTransaction(
        _proposal.targets[_i], _proposal.values[_i], _proposal.signatures[_i], _proposal.calldatas[_i], _proposal.eta
      );
    }

    emit ProposalCanceledIndexed(_proposalId);
    emit ProposalCanceled(_proposalId);
  }

  /// @notice Cancels a transaction
  /// @param _target Target address for transaction
  /// @param _value Eth value for transaction
  /// @param _signature Function signature for transaction
  /// @param _data Calldata for transaction
  /// @param _eta Timestamp for transaction
  function _cancelTransaction(
    address _target,
    uint256 _value,
    string memory _signature,
    bytes memory _data,
    uint256 _eta
  ) internal {
    bytes32 _txHash = keccak256(abi.encode(_target, _value, _signature, _data, _eta));
    queuedTransactions[_txHash] = false;

    emit CancelTransaction(_txHash, _target, _value, _signature, _data, _eta);
  }

  // @notice Gets actions of a proposal
  // @param _proposalId The id of the proposal
  // @return _targets The proposal targets
  // @return _values The proposal values
  // @return _signatures The proposal signatures
  // @return _calldatas The proposal calldata
  function getActions(uint256 _proposalId)
    external
    view
    override
    returns (
      address[] memory _targets,
      uint256[] memory _values,
      string[] memory _signatures,
      bytes[] memory _calldatas
    )
  {
    Proposal storage _proposal = proposals[_proposalId];
    return (_proposal.targets, _proposal.values, _proposal.signatures, _proposal.calldatas);
  }

  // @notice Returns the proposal
  // @param _proposalId The id of proposal
  // @return _proposal The proposal
  function getProposal(uint256 _proposalId) external view returns (Proposal memory _proposal) {
    _proposal = proposals[_proposalId];
  }

  // @notice Gets the receipt for a voter on a given proposal
  // @param _proposalId The id of proposal
  // @param _voter The address of the voter
  // @return _votingReceipt The voting receipt
  function getReceipt(
    uint256 _proposalId,
    address _voter
  ) external view override returns (Receipt memory _votingReceipt) {
    _votingReceipt = proposalReceipts[_proposalId][_voter];
  }

  // @notice Gets the state of a proposal
  // @param _proposalId The id of the proposal
  // @return _state Proposal state
  // solhint-disable-next-line code-complexity
  function state(uint256 _proposalId) public view override returns (ProposalState _state) {
    if (proposalCount < _proposalId || _proposalId <= initialProposalId) revert GovernorCharlie_InvalidProposalId();
    Proposal storage _proposal = proposals[_proposalId];
    bool _whitelisted = isWhitelisted(_proposal.proposer);
    if (_proposal.canceled) return ProposalState.Canceled;
    else if (block.number <= _proposal.startBlock) return ProposalState.Pending;
    else if (block.number <= _proposal.endBlock) return ProposalState.Active;
    else if (
      (_whitelisted && _proposal.againstVotes > _proposal.quorumVotes)
        || (!_whitelisted && _proposal.forVotes <= _proposal.againstVotes)
        || (!_whitelisted && _proposal.forVotes < _proposal.quorumVotes)
    ) return ProposalState.Defeated;
    else if (_proposal.eta == 0) return ProposalState.Succeeded;
    else if (_proposal.executed) return ProposalState.Executed;
    else if (block.timestamp >= (_proposal.eta + GRACE_PERIOD)) return ProposalState.Expired;
    _state = ProposalState.Queued;
  }

  // @notice Cast a vote for a proposal
  // @param _proposalId The id of the proposal to vote on
  // @param _support The support value for the vote. 0=against, 1=for, 2=abstain
  function castVote(uint256 _proposalId, uint8 _support) external override {
    uint96 _numberOfVotes = _castVoteInternal(msg.sender, _proposalId, _support);
    emit VoteCastIndexed(msg.sender, _proposalId, _support, _numberOfVotes, '');
    emit VoteCast(msg.sender, _proposalId, _support, _numberOfVotes, '');
  }

  // @notice Cast a vote for a proposal with a reason
  // @param _proposalId The id of the proposal to vote on
  // @param _support The support value for the vote. 0=against, 1=for, 2=abstain
  // @param _reason The reason given for the vote by the voter
  function castVoteWithReason(uint256 _proposalId, uint8 _support, string calldata _reason) external override {
    uint96 _numberOfVotes = _castVoteInternal(msg.sender, _proposalId, _support);
    emit VoteCastIndexed(msg.sender, _proposalId, _support, _numberOfVotes, _reason);
    emit VoteCast(msg.sender, _proposalId, _support, _numberOfVotes, _reason);
  }

  // @notice Cast a vote for a proposal by signature
  // @dev External override function that accepts EIP-712 signatures for voting on proposals.
  function castVoteBySig(uint256 _proposalId, uint8 _support, uint8 _v, bytes32 _r, bytes32 _s) external override {
    bytes32 _domainSeparator =
      keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(NAME)), _getChainIdInternal(), address(this)));
    bytes32 _structHash = keccak256(abi.encode(BALLOT_TYPEHASH, _proposalId, _support));

    bytes32 _digest = keccak256(abi.encodePacked('\x19\x01', _domainSeparator, _structHash));

    if (uint256(_s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      revert GovernorCharlie_InvalidSignature();
    }
    address _signatory = ecrecover(_digest, _v, _r, _s);
    if (_signatory == address(0)) revert GovernorCharlie_InvalidSignature();
    uint96 _numberOfVotes = _castVoteInternal(_signatory, _proposalId, _support);
    emit VoteCastIndexed(_signatory, _proposalId, _support, _numberOfVotes, '');
    emit VoteCast(_signatory, _proposalId, _support, _numberOfVotes, '');
  }

  // @notice Internal function that caries out voting logic
  // @param _voter The voter that is casting their vote
  // @param _proposalId The id of the proposal to vote on
  // @param _support The support value for the vote. 0=against, 1=for, 2=abstain
  // @return _numberOfVotes The number of votes cast
  function _castVoteInternal(
    address _voter,
    uint256 _proposalId,
    uint8 _support
  ) internal returns (uint96 _numberOfVotes) {
    if (state(_proposalId) != ProposalState.Active) revert GovernorCharlie_VotingClosed();
    if (_support > 2) revert GovernorCharlie_InvalidVoteType();
    Proposal storage _proposal = proposals[_proposalId];
    Receipt storage _receipt = proposalReceipts[_proposalId][_voter];
    if (_receipt.hasVoted) revert GovernorCharlie_AlreadyVoted();
    uint96 _votes = amph.getPriorVotes(_voter, _proposal.startBlock);

    if (_support == 0) _proposal.againstVotes = _proposal.againstVotes + _votes;
    else if (_support == 1) _proposal.forVotes = _proposal.forVotes + _votes;
    else if (_support == 2) _proposal.abstainVotes = _proposal.abstainVotes + _votes;

    _receipt.hasVoted = true;
    _receipt.support = _support;
    _receipt.votes = _votes;

    _numberOfVotes = _votes;
  }

  // @notice View function which returns if an account is whitelisted
  // @param _account Account to check white list status of
  // @return _isWhitelisted If the account is whitelisted
  function isWhitelisted(address _account) public view override returns (bool _isWhitelisted) {
    return (whitelistAccountExpirations[_account] > block.timestamp);
  }

  // @notice Governance function for setting the governance token
  // @param  _token The new token address
  function setNewToken(address _token) external onlyGov {
    address _oldAmph = address(amph);
    amph = IAMPH(_token);

    emit NewTokenSet(_oldAmph, _token);
  }

  // @notice Governance function for setting the max whitelist period
  // @param  _second How many seconds to whitelist for
  function setMaxWhitelistPeriod(uint256 _second) external onlyGov {
    uint256 _oldSeconds = maxWhitelistPeriod;
    maxWhitelistPeriod = _second;

    emit MaxWhitelistPeriodSet(_oldSeconds, _second);
  }

  // @notice Used to update the timelock period
  // @param _proposalTimelockDelay The proposal holding period
  function setDelay(uint256 _proposalTimelockDelay) public override onlyGov {
    uint256 _oldTimelockDelay = proposalTimelockDelay;
    proposalTimelockDelay = _proposalTimelockDelay;

    emit NewDelay(_oldTimelockDelay, proposalTimelockDelay);
  }

  // @notice Used to update the emergency timelock period
  // @param _emergencyTimelockDelay The proposal holding period
  function setEmergencyDelay(uint256 _emergencyTimelockDelay) public override onlyGov {
    uint256 _oldEmergencyTimelockDelay = emergencyTimelockDelay;
    emergencyTimelockDelay = _emergencyTimelockDelay;

    emit NewEmergencyDelay(_oldEmergencyTimelockDelay, emergencyTimelockDelay);
  }

  // @notice Governance function for setting the voting delay
  // @param _newVotingDelay The new voting delay, in blocks
  function setVotingDelay(uint256 _newVotingDelay) external override onlyGov {
    uint256 _oldVotingDelay = votingDelay;
    votingDelay = _newVotingDelay;

    emit VotingDelaySet(_oldVotingDelay, votingDelay);
  }

  // @notice Governance function for setting the voting period
  // @param _newVotingPeriod The new voting period, in blocks
  function setVotingPeriod(uint256 _newVotingPeriod) external override onlyGov {
    uint256 _oldVotingPeriod = votingPeriod;
    votingPeriod = _newVotingPeriod;

    emit VotingPeriodSet(_oldVotingPeriod, votingPeriod);
  }

  // @notice Governance function for setting the emergency voting period
  // @param _newEmergencyVotingPeriod The new voting period, in blocks
  function setEmergencyVotingPeriod(uint256 _newEmergencyVotingPeriod) external override onlyGov {
    uint256 _oldEmergencyVotingPeriod = emergencyVotingPeriod;
    emergencyVotingPeriod = _newEmergencyVotingPeriod;

    emit EmergencyVotingPeriodSet(_oldEmergencyVotingPeriod, emergencyVotingPeriod);
  }

  // @notice Governance function for setting the proposal threshold
  // @param _newProposalThreshold The new proposal threshold
  function setProposalThreshold(uint256 _newProposalThreshold) external override onlyGov {
    uint256 _oldProposalThreshold = proposalThreshold;
    proposalThreshold = _newProposalThreshold;

    emit ProposalThresholdSet(_oldProposalThreshold, proposalThreshold);
  }

  // @notice Governance function for setting the quorum
  // @param _newQuorumVotes The new proposal quorum
  function setQuorumVotes(uint256 _newQuorumVotes) external override onlyGov {
    uint256 _oldQuorumVotes = quorumVotes;
    quorumVotes = _newQuorumVotes;

    emit NewQuorum(_oldQuorumVotes, quorumVotes);
  }

  // @notice Governance function for setting the emergency quorum
  // @param _newEmergencyQuorumVotes The new proposal quorum
  function setEmergencyQuorumVotes(uint256 _newEmergencyQuorumVotes) external override onlyGov {
    uint256 _oldEmergencyQuorumVotes = emergencyQuorumVotes;
    emergencyQuorumVotes = _newEmergencyQuorumVotes;

    emit NewEmergencyQuorum(_oldEmergencyQuorumVotes, emergencyQuorumVotes);
  }

  // @notice Governance function for setting the whitelist expiration as a timestamp
  // for an account. Whitelist status allows accounts to propose without meeting threshold
  // @param _account Account address to set whitelist expiration for
  // @param _expiration Expiration for account whitelist status as timestamp (if now < expiration, whitelisted)
  function setWhitelistAccountExpiration(address _account, uint256 _expiration) external override onlyGov {
    if (_expiration >= (maxWhitelistPeriod + block.timestamp)) revert GovernorCharlie_ExpirationExceedsMax();
    whitelistAccountExpirations[_account] = _expiration;

    emit WhitelistAccountExpirationSet(_account, _expiration);
  }

  // @notice Governance function for setting the whitelistGuardian. WhitelistGuardian can cancel proposals from whitelisted addresses
  // @param _account Account to set whitelistGuardian to (0x0 to remove whitelistGuardian)
  function setWhitelistGuardian(address _account) external override onlyGov {
    address _oldGuardian = whitelistGuardian;
    whitelistGuardian = _account;

    emit WhitelistGuardianSet(_oldGuardian, whitelistGuardian);
  }

  // @notice Governance function for setting the optimistic voting delay
  // @param _newOptimisticVotingDelay The new optimistic voting delay, in blocks
  function setOptimisticDelay(uint256 _newOptimisticVotingDelay) external override onlyGov {
    uint256 _oldOptimisticVotingDelay = optimisticVotingDelay;
    optimisticVotingDelay = _newOptimisticVotingDelay;

    emit OptimisticVotingDelaySet(_oldOptimisticVotingDelay, optimisticVotingDelay);
  }

  // @notice Governance function for setting the optimistic quorum
  // @param _newOptimisticQuorumVotes The new optimistic quorum votes, in blocks
  function setOptimisticQuorumVotes(uint256 _newOptimisticQuorumVotes) external override onlyGov {
    uint256 _oldOptimisticQuorumVotes = optimisticQuorumVotes;
    optimisticQuorumVotes = _newOptimisticQuorumVotes;

    emit OptimisticQuorumVotesSet(_oldOptimisticQuorumVotes, optimisticQuorumVotes);
  }

  /// @notice Returns the timelock address
  /// @param _timelock The timelock address
  function timelock() external view override returns (address _timelock) {
    _timelock = address(this);
  }

  /// @notice Returns the proposal time lock delay
  /// @return _delay The proposal time lock delay
  function delay() external view override returns (uint256 _delay) {
    _delay = proposalTimelockDelay;
  }

  /// @notice Returns the chaid id of the blockchain
  /// @return _chainId The chain id
  function _getChainIdInternal() internal view returns (uint256 _chainId) {
    _chainId = block.chainid;
  }

  /// @notice Returns the block timestamp
  /// @return _timestamp The block timestamp
  function _getBlockTimestamp() internal view returns (uint256 _timestamp) {
    // solium-disable-next-line security/no-block-members
    _timestamp = block.timestamp;
  }
}
