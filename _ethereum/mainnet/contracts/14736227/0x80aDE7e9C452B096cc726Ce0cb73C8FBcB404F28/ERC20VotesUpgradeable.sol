// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-ERC20PermitUpgradeable.sol";
import "./MathUpgradeable.sol";
import "./SafeCastUpgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./IERC20Votes.sol";

/**
 * @dev @openzeppelin Extension of the ERC20 governance token contract to allow voting/proposal and delegation.
 *
 * This extensions keeps a history (snapshots) of each account's vote/proposal power. Vote/Proposition power can be delegated either
 * by calling the {delegate} directly, or by providing a signature that can later be verified and processed using {delegateFromBySig}.
 * Voting power can be checked through the public accessors {propositionPower/votingPower} and {propositionPowerAt/votingPowerAt}.
 *
 */
abstract contract ERC20VotesUpgradeable is
	Initializable,
	ERC20PermitUpgradeable,
	IERC20Votes
{
	/* delegates */
	mapping(address => address) private _votingDelegates;
	mapping(address => address) private _propositionDelegates;

	/* snapshots */
	mapping(address => Snapshot[]) private _votingSnapshots;
	mapping(address => Snapshot[]) private _propositionSnapshots;

	mapping(address => Snapshot[]) private _balanceSnapshots;

	Snapshot[] private _totalSupplySnapshots;

	/* hashes */
	bytes32 private constant _DELEGATION_TYPEHASH =
		keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

	bytes32 private constant _DELEGATION_OF_PROPOSAL_TYPEHASH =
		keccak256(
			"DelegationOfProposal(address delegatee,uint256 nonce,uint256 expiry)"
		);

	bytes32 private constant _DELEGATION_OF_VOTE_TYPEHASH =
		keccak256(
			"DelegationOfVote(address delegatee,uint256 nonce,uint256 expiry)"
		);

	function __ERC20Votes_init_unchained() internal initializer {}

	function propositionSnapshots(address account, uint32 pos)
		external
		view
		virtual
		override
		returns (Snapshot memory)
	{
		return _propositionSnapshots[account][pos];
	}

	function votingSnapshots(address account, uint32 pos)
		external
		view
		virtual
		override
		returns (Snapshot memory)
	{
		return _votingSnapshots[account][pos];
	}

	function numPropositionSnapshots(address account)
		external
		view
		virtual
		override
		returns (uint32)
	{
		return
			SafeCastUpgradeable.toUint32(_propositionSnapshots[account].length);
	}

	function numVotingSnapshots(address account)
		external
		view
		virtual
		override
		returns (uint32)
	{
		return SafeCastUpgradeable.toUint32(_votingSnapshots[account].length);
	}

	/**
	 * @dev Get the address `account` is currently delegating proposition power to.
	 */
	function propositionDelegates(address account)
		public
		view
		virtual
		override
		returns (address)
	{
		return _propositionDelegates[account];
	}

	/**
	 * @dev Get the address `account` is currently delegating voting power to.
	 */
	function votingDelegates(address account)
		public
		view
		virtual
		override
		returns (address)
	{
		return _votingDelegates[account];
	}

	/**
	 * @notice Gets the current proposal power for `account`
	 * @param account The address to get its proposal power
	 * @return The number of current votes for `account`
	 */
	function propositionPower(address account)
		external
		view
		override
		returns (uint256)
	{
		uint256 pos = _propositionSnapshots[account].length;
		return pos == 0 ? 0 : _propositionSnapshots[account][pos - 1].votes;
	}

	/**
	 * @notice Gets the current voting power for `account`
	 * @param account The address to get its voting power
	 * @return The number of current votes for `account`
	 */
	function votingPower(address account)
		external
		view
		override
		returns (uint256)
	{
		uint256 pos = _votingSnapshots[account].length;
		return pos == 0 ? 0 : _votingSnapshots[account][pos - 1].votes;
	}

	/**
	 * @notice Determine the prior number of proposition power for an account as of a block number
	 * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
	 * @param account The address of the account to check
	 * @param blockNumber The block number to get the vote balance at
	 * @return The number of votes the account had as of the given block
	 */
	function propositionPowerAt(address account, uint256 blockNumber)
		external
		view
		override
		returns (uint256)
	{
		return _getPriorPower(_propositionSnapshots, account, blockNumber);
	}

	/**
	 * @notice Determine the prior number of voting power for an account as of a block number
	 * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
	 * @param account The address of the account to check
	 * @param blockNumber The block number to get the vote balance at
	 * @return The number of votes the account had as of the given block
	 */
	function votingPowerAt(address account, uint256 blockNumber)
		external
		view
		override
		returns (uint256)
	{
		return _getPriorPower(_votingSnapshots, account, blockNumber);
	}

	/**
	 * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
	 *
	 * Requirements:
	 *
	 * - `blockNumber` must have been already mined
	 */
	function _getPriorPower(
		mapping(address => Snapshot[]) storage snapshots,
		address account,
		uint256 blockNumber
	) private view returns (uint256) {
		require(blockNumber < block.number, "block not yet mined");

		return _snapshotsLookup(snapshots[account], blockNumber);
	}

	/**
	 * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
	 */
	function balanceOfAt(address account, uint256 blockNumber)
		public
		view
		override
		returns (uint256)
	{
		require(blockNumber < block.number, "block not yet mined");
		return _snapshotsLookup(_balanceSnapshots[account], blockNumber);
	}

	/**
	 * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
	 * It is but NOT the sum of all the delegated votes!
	 *
	 * Requirements:
	 *
	 * - `blockNumber` must have been already mined
	 */
	function totalSupplyAt(uint256 blockNumber)
		public
		view
		override
		returns (uint256)
	{
		require(blockNumber < block.number, "block not yet mined");
		return _snapshotsLookup(_totalSupplySnapshots, blockNumber);
	}

	/**
	 * @dev Lookup a value in a list of (sorted) snapshots.
	 */
	function _snapshotsLookup(Snapshot[] storage ckpts, uint256 blockNumber)
		private
		view
		returns (uint256)
	{
		// We run a binary search to look for the earliest snapshot taken after `blockNumber`.
		//
		// During the loop, the index of the wanted snapshot remains in the range [low, high).
		// With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
		// - If the middle snapshot is after `blockNumber`, we look in [low, mid)
		// - If the middle snapshot is before `blockNumber`, we look in [mid+1, high)
		// Once we reach a single value (when low == high), we've found the right snapshot at the index high-1, if not
		// out of bounds (in which case we're looking too far in the past and the result is 0).
		// Note that if the latest snapshot available is exactly for `blockNumber`, we end up with an index that is
		// past the end of the array, so we technically don't find a snapshot after `blockNumber`, but it works out
		// the same.
		uint256 high = ckpts.length;
		uint256 low = 0;
		while (low < high) {
			uint256 mid = MathUpgradeable.average(low, high);
			if (ckpts[mid].fromBlock > blockNumber) {
				high = mid;
			} else {
				low = mid + 1;
			}
		}

		return high == 0 ? 0 : ckpts[high - 1].votes;
	}

	/**
	 * @notice Delegate votes from the sender to `delegatee`
	 * @param delegatee The address to delegate votes to
	 */
	function delegate(address delegatee) external virtual override {
		_delegatePower(
			DelegationType.PROPOSITION_POWER,
			_msgSender(),
			delegatee
		);
		_delegatePower(DelegationType.VOTING_POWER, _msgSender(), delegatee);
	}

	/**
	 * @notice Delegate votes from the sender to `delegatee`
	 * @param delegatee The address to delegate votes to
	 */
	function delegatePropositionPower(address delegatee)
		external
		virtual
		override
	{
		return
			_delegatePower(
				DelegationType.PROPOSITION_POWER,
				_msgSender(),
				delegatee
			);
	}

	/**
	 * @notice Delegate votes from the sender to `delegatee`
	 * @param delegatee The address to delegate votes to
	 */
	function delegateVotingPower(address delegatee) external virtual override {
		return
			_delegatePower(
				DelegationType.VOTING_POWER,
				_msgSender(),
				delegatee
			);
	}

	/**
	 * @notice Delegates votes from signatory to `delegatee`
	 * @param delegatee The address to delegate votes to
	 * @param nonce The contract state required to match the signature
	 * @param expiry The time at which to expire the signature
	 * @param v The recovery byte of the signature
	 * @param r Half of the ECDSA signature pair
	 * @param s Half of the ECDSA signature pair
	 */
	function delegateBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual override {
		return
			_delegateWHashBySig(
				delegatee,
				_DELEGATION_TYPEHASH,
				nonce,
				expiry,
				v,
				r,
				s
			);
	}

	function delegateProposalBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual override {
		return
			_delegateWHashBySig(
				delegatee,
				_DELEGATION_OF_PROPOSAL_TYPEHASH,
				nonce,
				expiry,
				v,
				r,
				s
			);
	}

	function delegateVoteBySig(
		address delegatee,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual override {
		return
			_delegateWHashBySig(
				delegatee,
				_DELEGATION_OF_VOTE_TYPEHASH,
				nonce,
				expiry,
				v,
				r,
				s
			);
	}

	/**
	 * @notice Delegates votes from signatory to `delegatee`
	 * @param delegatee The address to delegate votes to
	 * @param delegationHash the type of delegation (VOTING_POWER, PROPOSITION_POWER)
	 * @param nonce The contract state required to match the signature
	 * @param expiry The time at which to expire the signature
	 * @param v The recovery byte of the signature
	 * @param r Half of the ECDSA signature pair
	 * @param s Half of the ECDSA signature pair
	 */
	function _delegateWHashBySig(
		address delegatee,
		bytes32 delegationHash,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal virtual {
		//solhint-disable-next-line not-rely-on-time
		require(block.timestamp <= expiry, "signature expired");
		address signatory = ECDSAUpgradeable.recover(
			_hashTypedDataV4(
				keccak256(abi.encode(delegationHash, delegatee, nonce, expiry))
			),
			v,
			r,
			s
		);
		require(nonce == _useNonce(signatory), "invalid nonce");

		if (
			delegationHash == _DELEGATION_TYPEHASH ||
			delegationHash == _DELEGATION_OF_VOTE_TYPEHASH
		) {
			_delegatePower(DelegationType.VOTING_POWER, signatory, delegatee);
		}
		if (
			delegationHash == _DELEGATION_TYPEHASH ||
			delegationHash == _DELEGATION_OF_PROPOSAL_TYPEHASH
		) {
			_delegatePower(
				DelegationType.PROPOSITION_POWER,
				signatory,
				delegatee
			);
		}
	}

	/**
	 * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
	 */
	function _maxSupply() internal view virtual returns (uint224) {
		return type(uint224).max;
	}

	/**
	 * @dev Snapshots the totalSupply after it has been increased.
	 */
	function _mint(address account, uint256 amount) internal virtual override {
		super._mint(account, amount);
		require(
			totalSupply() <= _maxSupply(),
			"total supply risks overflowing votes" //"max possible supply achieved"
		);

		_writeSnapshot(_balanceSnapshots[account], _add, amount);
		_writeSnapshot(_totalSupplySnapshots, _add, amount);
	}

	/**
	 * @dev Snapshots the totalSupply after it has been decreased.
	 */
	function _burn(address account, uint256 amount) internal virtual override {
		super._burn(account, amount);

		_writeSnapshot(_balanceSnapshots[account], _subtract, amount);
		_writeSnapshot(_totalSupplySnapshots, _subtract, amount);
	}

	/**
	 * @dev Move voting power when tokens are transferred.
	 *
	 * Emits a {DelegateVotesChanged} event.
	 */
	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal virtual override {
		super._afterTokenTransfer(from, to, amount);

		_moveVotingPower(
			DelegationType.VOTING_POWER,
			votingDelegates(from),
			votingDelegates(to),
			amount
		);
		_moveVotingPower(
			DelegationType.PROPOSITION_POWER,
			propositionDelegates(from),
			propositionDelegates(to),
			amount
		);
	}

	function _delegatePower(
		DelegationType delegationType,
		address delegator,
		address delegatee
	) internal virtual {
		require(delegatee != address(0), "invalid delegate");

		address currentDelegate = delegationType == DelegationType.VOTING_POWER
			? votingDelegates(delegator)
			: propositionDelegates(delegator);
		uint256 delegatorBalance = balanceOf(delegator);

		if (delegationType == DelegationType.VOTING_POWER) {
			_votingDelegates[delegator] = delegatee;
		} else {
			_propositionDelegates[delegator] = delegatee;
		}

		emit DelegateChanged(
			delegator,
			currentDelegate,
			delegatee,
			delegationType
		);

		_moveVotingPower(
			delegationType,
			currentDelegate,
			delegatee,
			delegatorBalance
		);
	}

	function _moveVotingPower(
		DelegationType delegationType,
		address src,
		address dst,
		uint256 amount
	) private {
		if (src != dst && amount > 0) {
			// delegationType required below, hence not declaring snapshots in parameters

			mapping(address => Snapshot[]) storage snapshots = delegationType ==
				DelegationType.VOTING_POWER
				? _votingSnapshots
				: _propositionSnapshots;

			if (src != address(0)) {
				(uint256 oldWeight, uint256 newWeight) = _writeSnapshot(
					snapshots[src],
					_subtract,
					amount
				);
				emit DelegatePowerChanged(
					src,
					oldWeight,
					newWeight,
					delegationType
				);
			}

			if (dst != address(0)) {
				(uint256 oldWeight, uint256 newWeight) = _writeSnapshot(
					snapshots[dst],
					_add,
					amount
				);
				emit DelegatePowerChanged(
					dst,
					oldWeight,
					newWeight,
					delegationType
				);
			}
		}
	}

	function _writeSnapshot(
		Snapshot[] storage ckpts,
		function(uint256, uint256) view returns (uint256) op,
		uint256 delta
	) private returns (uint256 oldWeight, uint256 newWeight) {
		uint256 pos = ckpts.length;
		oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
		newWeight = op(oldWeight, delta);

		if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
			ckpts[pos - 1].votes = SafeCastUpgradeable.toUint224(newWeight);
		} else {
			ckpts.push(
				Snapshot({
					fromBlock: SafeCastUpgradeable.toUint32(block.number),
					votes: SafeCastUpgradeable.toUint224(newWeight)
				})
			);
		}
	}

	function _add(uint256 a, uint256 b) private pure returns (uint256) {
		return a + b;
	}

	function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
		return a - b;
	}
}
