// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./GovernorTimelockControl.sol";
import "./IPolicy.sol";
import "./DataStruct.sol";

contract ElyfiGovernanceCore is Governor, GovernorTimelockControl {
  constructor(TimelockController timelock)
    Governor('ElyfiGovernanceCore')
    GovernorTimelockControl(timelock)
  {
    _policy = IPolicy(address(timelock));
  }

  IPolicy private _policy;

  mapping(uint256 => DataStruct.ProposalVote) private _proposalVotes;

  mapping(uint256 => mapping(address => bool)) private _hasVoted;

  /// @dev See {IGovernor-COUNTING_MODE}.
  /// support=bravo refers to the vote options 0 = For, 1 = Against, 2 = Abstain
  /// quourm=for,abstain means that both For and Abstain votes are counted towards quorum.
  // solhint-disable-next-line func-name-mixedcase
  function COUNTING_MODE() public pure virtual override returns (string memory) {
    return 'support=bravo&quorum=for,abstain';
  }

  /// @dev See {IGovernor-hasVoted}.
  /// @notice Returns weither account has cast a vote on proposalId.
  function hasVoted(uint256 proposalId, address account)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _hasVoted[proposalId][account];
  }

  /// @dev Accessor to the internal vote counts.
  function proposalVotes(uint256 proposalId)
    public
    view
    virtual
    returns (
      uint256 againstVotes,
      uint256 forVotes,
      uint256 abstainVotes
    )
  {
    DataStruct.ProposalVote storage proposalvote = _proposalVotes[proposalId];
    return (proposalvote.againstVotes, proposalvote.forVotes, proposalvote.abstainVotes);
  }

  /// @dev See {Governor-_quorumReached}.
  /// @notice Amount of votes already cast passes the threshold limit.
  function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
    DataStruct.ProposalVote storage proposalvote = _proposalVotes[proposalId];

    return _policy.quorumReached(proposalvote, proposalSnapshot(proposalId));
  }

  /// @dev See {Governor-_voteSucceeded}.
  /// @notice In this module, the forVotes must be scritly over the againstVotes. Is the proposal successful or not.
  function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
    DataStruct.ProposalVote storage proposalvote = _proposalVotes[proposalId];

    return _policy.voteSucceeded(proposalvote);
  }

  /// @dev See {Governor-_countVote}.
  /// Register a vote with a given support and voting weight.
  /// In this module, the support follows the `DataStruct.VoteType` enum (from Governor Bravo).
  function _countVote(
    uint256 proposalId,
    address account,
    uint8 support,
    uint256 weight
  ) internal virtual override {
    require(
      _policy.validateVoter(account, proposalSnapshot(proposalId)),
      'ElyfiGovernor: Invalid Voter'
    );

    DataStruct.ProposalVote storage proposalvote = _proposalVotes[proposalId];

    require(!_hasVoted[proposalId][account], 'ElyfiGovernor: Vote already casted');
    _hasVoted[proposalId][account] = true;

    if (support == uint8(DataStruct.VoteType.Against)) {
      proposalvote.againstVotes += weight;
    } else if (support == uint8(DataStruct.VoteType.For)) {
      proposalvote.forVotes += weight;
    } else if (support == uint8(DataStruct.VoteType.Abstain)) {
      proposalvote.abstainVotes += weight;
    } else {
      revert('ElyfiGovernor: invalid VoteType');
    }
  }

  /// @notice Delay (in number of blocks) since the proposal is submitted until voting power is fixed and voting starts.
  /// @dev This can be used to enforce a delay after a proposal is published for users to buy tokens, or delegate their votes.
  function votingDelay() public view virtual override returns (uint256) {
    return 1; // 1 block
  }

  /// @notice Delay (in number of blocks) since the proposal starts until voting ends.
  /// @dev average blockTime = 13.2s, 86400 / 13.2 = 6545
  function votingPeriod() public view virtual override returns (uint256) {
    return 6545; // 1 week
  }

  /**** The following functions are overrides required by Solidity. *****/

  /// @notice The quorum set in the policy module
  /// @param blockNumber The block number at which to retrieve the prior number of votes.
  function quorum(uint256 blockNumber) public view override(IGovernor) returns (uint256) {
    return _policy.quorum(blockNumber);
  }

  /// @notice Voting power of an account at a specific blockNumber
  /// @param account the account in which to retrieve the prior number of votes
  /// @param blockNumber The block number at which to retrieve the prior number of votes.
  function getVotes(address account, uint256 blockNumber)
    public
    view
    override(IGovernor)
    returns (uint256)
  {
    return _policy.getVotes(account, blockNumber);
  }

  /// @notice Current state of a proposal, following openzepplin convention
  /// @param proposalId The id of proposal
  function state(uint256 proposalId)
    public
    view
    override(Governor, GovernorTimelockControl)
    returns (ProposalState)
  {
    return super.state(proposalId);
  }

  /// @notice Create a new proposal
  /// @dev Authurity depends on the policy module
  /// @param targets The list of target addresses for calls to be made
  /// @param values The list of msg.value to be passed to the calls
  /// @param calldatas The list of function signatures to be passed during execution
  /// @param description The description of new proposal
  function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description
  ) public override(Governor, IGovernor) returns (uint256) {
    require(_policy.validateProposer(_msgSender(), block.number), 'Invaild Proposer');
    return super.propose(targets, values, calldatas, description);
  }

  /// @dev Internal execution mechanism
  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) {
    super._execute(proposalId, targets, values, calldatas, descriptionHash);
  }

  /// @dev Cancel the timelocked proposal if it as already been queued.
  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
    return super._cancel(targets, values, calldatas, descriptionHash);
  }

  function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
    return super._executor();
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(Governor, GovernorTimelockControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
