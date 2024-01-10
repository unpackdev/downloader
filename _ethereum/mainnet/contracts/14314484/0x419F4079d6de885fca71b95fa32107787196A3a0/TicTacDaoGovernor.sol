// SPDX-License-Identifier: MIT
// Adapted from OpenZeppelin Contracts
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./GovernorCountingSimple.sol";
import "./GovernorPreventLateQuorum.sol";
import "./GovernorSettings.sol";
import "./Votes.sol";

/// Combines OpenZeppelin Governor contracts in a format suitable for TicTacDao
abstract contract TicTacDaoGovernor is Ownable, GovernorSettings, GovernorCountingSimple, GovernorPreventLateQuorum, Votes {

	/// @dev The saved quorum numerator
	uint256 private _quorumNumerator;

	/// @dev The total voting power for each account
	mapping(address => uint256) private _totalVotingPower;

	/// @dev Saving the initial proposal threshold
	uint256 private immutable _initialProposalThreshold;

	event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

	/// Initialize the TicTacDaoGovernor with initial properties
	/// @param name The name of the DAO
	/// @param initialVotingDelay The duration, in blocks, before a vote begins
	/// @param initialVotingPeriod The duration, in blocks, of the voting period
	/// @param initialProposalThreshold The votes required to submit a proposal
	/// @param quorumNumeratorValue The per-100 fraction of the total supply of votes
	/// @param quorumReachedExtension The additional delay, in blocks, of the vote once quorum is reached
	constructor(string memory name, uint256 initialVotingDelay, uint256 initialVotingPeriod, uint256 initialProposalThreshold, uint256 quorumNumeratorValue, uint64 quorumReachedExtension)
		Governor(name)
		GovernorPreventLateQuorum(quorumReachedExtension)
		GovernorSettings(initialVotingDelay, initialVotingPeriod, initialProposalThreshold)
	{
		_initialProposalThreshold = initialProposalThreshold;
		_updateQuorumNumerator(quorumNumeratorValue);
		_delegate(owner(), owner());
		_transferVotingUnits(address(0), owner(), initialProposalThreshold);
	}

	/// @inheritdoc Votes
	function getVotes(address account) public view override returns (uint256) {
		return super.getVotes(account);
	}

	/// @inheritdoc IGovernor
	function getVotes(address account, uint256 blockNumber) public view override returns (uint256) {
		return super.getPastVotes(account, blockNumber);
	}

	/// @inheritdoc Governor
	function proposalDeadline(uint256 proposalId) public view virtual override(Governor, GovernorPreventLateQuorum) returns (uint256) {
		return super.proposalDeadline(proposalId);
	}

	/// @inheritdoc Governor
	function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
		return super.proposalThreshold();
	}

	/// @dev Returns the current quorum numerator. See {quorumDenominator}.
	function quorumNumerator() public view virtual returns (uint256) {
		return _quorumNumerator;
	}

	/// @dev Returns the quorum denominator. Defaults to 100, but may be overridden.
	function quorumDenominator() public view virtual returns (uint256) {
		return 100;
	}

	/// @dev Returns the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`.
	function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
		return (getPastTotalSupply(blockNumber) * quorumNumerator()) / quorumDenominator();
	}

	/// Allows the owner to reject a proposal after determining that it harms the community
	/// @param targets The array of target addresses being called
	/// @param values The array of ETH values to send for each call
	/// @param calldatas The encoding of functions+parameters for each call
	/// @param descriptionHash The hash of the initial description
	function rejectProposal(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash) external onlyOwner {
		_cancel(targets, values, calldatas, descriptionHash);
	}

	/// @inheritdoc Ownable
	function transferOwnership(address newOwner) public virtual override {
		if (newOwner != owner()) {
			if (delegates(newOwner) == address(0)) {
				_delegate(newOwner, newOwner); // Go ahead and configure voting for the new owner
			}
			_transferVotingUnits(owner(), newOwner, _initialProposalThreshold);
		}
		super.transferOwnership(newOwner);
	}

	/**
	* @dev Changes the quorum numerator.
	*
	* Emits a {QuorumNumeratorUpdated} event.
	*
	* Requirements:
	*
	* - Must be called through a governance proposal.
	* - New numerator must be smaller or equal to the denominator.
	*/
	function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
		_updateQuorumNumerator(newQuorumNumerator);
	}

	function _castVote(uint256 proposalId, address account, uint8 support, string memory reason) internal virtual override(Governor, GovernorPreventLateQuorum) returns (uint256) {
		return super._castVote(proposalId, account, support, reason);
	}

	/// @dev Returns the sum of wins for all games belonging to `account`.
	function _getVotingUnits(address account) internal virtual override returns (uint256) {
		return _totalVotingPower[account];
	}

	function _transferVotingUnits(address from, address to, uint256 amount) internal virtual override {
		super._transferVotingUnits(from, to, amount);
		if (from != to) {
			if (from == address(0)) {
				_totalVotingPower[to] += amount;
			} else {
				uint256 currentVotingPower = _totalVotingPower[from];
				if (currentVotingPower <= amount) {
					delete _totalVotingPower[from];
					_totalVotingPower[to] += currentVotingPower;
				} else {
					_totalVotingPower[from] = currentVotingPower - amount;
					_totalVotingPower[to] += amount;
				}
			}
		}
	}

	/**
	* @dev Changes the quorum numerator.
	*
	* Emits a {QuorumNumeratorUpdated} event.
	*
	* Requirements:
	*
	* - New numerator must be smaller or equal to the denominator.
	*/
	function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
		// solhint-disable-next-line reason-string
		require(
			newQuorumNumerator <= quorumDenominator(),
			"GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
		);

		uint256 oldQuorumNumerator = _quorumNumerator;
		_quorumNumerator = newQuorumNumerator;

		emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
	}
}
