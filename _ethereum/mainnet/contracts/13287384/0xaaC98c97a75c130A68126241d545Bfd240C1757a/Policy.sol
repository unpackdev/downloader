// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./IPolicy.sol";

import "./ERC20Votes.sol";
import "./AccessControl.sol";

contract Policy is IPolicy, AccessControl {
  bytes32 public constant LENDING_COMPANY_ROLE = keccak256('LENDING_COMPANY_ROLE');
  bytes32 public constant POLICY_ADMIN_ROLE = keccak256('POLICY_ADMIN_ROLE');

  ERC20Votes public immutable token;

  uint256 private _quorumNumerator;
  uint256 private _minVotingPower;

  event MinVotingPowerUpdated(uint256 oldMinVotingPower, uint256 newMinVotingPower);
  event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

  constructor(
    address token_,
    uint256 minVotingPower_,
    uint16 quorumNumerator_
  ) {
    _setRoleAdmin(POLICY_ADMIN_ROLE, POLICY_ADMIN_ROLE);
    _setRoleAdmin(LENDING_COMPANY_ROLE, POLICY_ADMIN_ROLE);

    _setupRole(POLICY_ADMIN_ROLE, address(this));
    _setupRole(POLICY_ADMIN_ROLE, _msgSender());

    _minVotingPower = minVotingPower_;
    _quorumNumerator = quorumNumerator_;

    token = ERC20Votes(token_);

    emit MinVotingPowerUpdated(0, minVotingPower_);
  }

  ///////// Main Interfaces

  /// @notice Check whether the account can create the proposal at the end of the blockNumber
  /// @dev Proposer must be authorized in this version
  /// @param account The proposer address
  /// @param blockNumber The past blocknumber
  function validateProposer(address account, uint256 blockNumber)
    external
    view
    virtual
    override
    returns (bool)
  {
    blockNumber;
    return _validateProposer(account);
  }

  /// @notice Check whether the account can vote on the proposal at the end of the blockNumber
  /// @dev Voting power should be over the
  /// @param account The voter address
  /// @param blockNumber The past blocknumber
  function validateVoter(address account, uint256 blockNumber)
    external
    view
    virtual
    override
    returns (bool)
  {
    return token.getPastVotes(account, blockNumber) >= minVotingPower();
  }

  /// @notice Check whether the proposal has been succeeded under the current governance policy
  /// @dev The propose should be ... TODO : set requirements for the success
  /// @param proposalVote The currnet proposal data
  function voteSucceeded(DataStruct.ProposalVote memory proposalVote)
    external
    view
    virtual
    override
    returns (bool)
  {
    return proposalVote.forVotes > proposalVote.againstVotes;
  }

  /// @notice Returns the voting power of an account at a specific blockNumber
  /// @dev The voting power is the amount of staked governance token
  /// @param account The address
  /// @param blockNumber The past blocknumber
  function getVotes(address account, uint256 blockNumber) external view override returns (uint256) {
    return token.getPastVotes(account, blockNumber);
  }

  /// @notice Returns whether the casted vote in the proposal exceeds quorum
  /// @dev The quorum can be updated
  /// @param proposalVote The proposal to check
  /// @param blockNumber The vote start blockNumber
  function quorumReached(DataStruct.ProposalVote memory proposalVote, uint256 blockNumber)
    external
    view
    override
    returns (bool)
  {
    return (quorum(blockNumber) <= proposalVote.forVotes + proposalVote.abstainVotes);
  }

  /// @notice Returns whether the casted vote in the proposal exceeds quorum
  /// @dev The quorum can be updated
  /// @param blockNumber The blockNumber for counting vote in the past
  function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
    return (token.getPastTotalSupply(blockNumber) * quorumNumerator()) / quorumDenominator();
  }

  //////////////////////// Quorum

  function quorumNumerator() public view virtual returns (uint256) {
    return _quorumNumerator;
  }

  function quorumDenominator() public view virtual returns (uint256) {
    return 100;
  }

  /// @notice Returns whether the casted vote in the proposal exceeds quorum
  /// @param newQuorumNumerator The new quorum numerator
  function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual {
    require(hasRole(POLICY_ADMIN_ROLE, msg.sender), 'Only Policy Admin');
    _updateQuorumNumerator(newQuorumNumerator);
  }

  function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
    require(newQuorumNumerator <= quorumDenominator(), 'QuorumNumerator over QuorumDenominator');

    uint256 oldQuorumNumerator = _quorumNumerator;
    _quorumNumerator = newQuorumNumerator;

    emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
  }

  //////////////////////// Propose

  /// @notice In the current elyfi, the lending company who has a collateral service provider role is allowed to create proposal.
  /// @param account The address of proposer
  function _validateProposer(address account) internal view returns (bool) {
    return hasRole(LENDING_COMPANY_ROLE, account);
  }

  /////////////////////// Voting power

  function minVotingPower() public view returns (uint256) {
    return _minVotingPower;
  }

  function updateMinVotingPower(uint256 newMinVotingPower) external {
    require(hasRole(POLICY_ADMIN_ROLE, msg.sender), 'Only Policy Admin');
    _updateMinVotingPower(newMinVotingPower);
  }

  function _updateMinVotingPower(uint256 newMinVotingPower) internal {
    require(newMinVotingPower <= token.totalSupply(), 'VotingPower exceeds TotalSupply');

    uint256 oldMinVotingPower = _minVotingPower;
    _minVotingPower = newMinVotingPower;

    emit MinVotingPowerUpdated(oldMinVotingPower, newMinVotingPower);
  }
}
