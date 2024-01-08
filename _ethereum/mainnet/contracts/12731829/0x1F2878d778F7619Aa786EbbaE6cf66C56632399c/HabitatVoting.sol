// SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

import "./HabitatBase.sol";
import "./HabitatWallet.sol";
import "./HabitatVault.sol";
import "./IModule.sol";

/// @notice Voting Functionality.
// Audit-1: ok
contract HabitatVoting is HabitatBase, HabitatWallet, HabitatVault {
  event ProposalCreated(address indexed vault, bytes32 indexed proposalId, uint256 startDate);
  event VotedOnProposal(address indexed account, bytes32 indexed proposalId, uint8 signalStrength, uint256 shares);
  event DelegateeVotedOnProposal(address indexed account, bytes32 indexed proposalId, uint8 signalStrength, uint256 shares);
  event ProposalProcessed(bytes32 indexed proposalId, uint256 indexed votingStatus);

  /// @dev Validates if `timestamp` is inside a valid range.
  /// `timestamp` should not be under/over now +- `_PROPOSAL_DELAY`.
  function _validateTimestamp (uint256 timestamp) internal virtual {
    uint256 time = _getTime();
    uint256 delay = _PROPOSAL_DELAY();

    if (time > timestamp) {
      require(time - timestamp < delay, 'VT1');
    } else {
      require(timestamp - time < delay, 'VT2');
    }
  }

  /// @dev Parses and executes `internalActions`.
  /// TODO Only `TRANSFER_TOKEN` is currently implemented
  function _executeInternalActions (address vaultAddress, bytes calldata internalActions) internal {
    // Types, related to actionable proposal items on L2.
    // L1 has no such items and only provides an array of [<address><calldata] for on-chain execution.
    // enum L2ProposalActions {
    //  RESERVED,
    //  TRANSFER_TOKEN,
    //  UPDATE_COMMUNITY_METADATA
    // }

    // assuming that `length` can never be > 2^16
    uint256 ptr;
    uint256 end;
    assembly {
      let len := internalActions.length
      ptr := internalActions.offset
      end := add(ptr, len)
    }

    while (ptr < end) {
      uint256 actionType;

      assembly {
        actionType := byte(0, calldataload(ptr))
        ptr := add(ptr, 1)
      }

      // TRANSFER_TOKEN
      if (actionType == 1) {
        address token;
        address receiver;
        uint256 value;
        assembly {
          token := shr(96, calldataload(ptr))
          ptr := add(ptr, 20)
          receiver := shr(96, calldataload(ptr))
          ptr := add(ptr, 20)
          value := calldataload(ptr)
          ptr := add(ptr, 32)
        }
        _transferToken(token, vaultAddress, receiver, value);
        continue;
      }

      revert('EIA1');
    }

    // revert if out of bounds read(s) happened
    if (ptr > end) {
      revert('EIA2');
    }
  }

  /// @dev Invokes IModule.onCreateProposal(...) on `vault`
  function _callCreateProposal (
    address vault,
    address proposer,
    uint256 startDate,
    bytes memory internalActions,
    bytes memory externalActions
  ) internal {
    bytes32 communityId = HabitatBase.communityOfVault(vault);
    address governanceToken = HabitatBase.tokenOfCommunity(communityId);

    // encoding all all the statistics
    bytes memory _calldata = abi.encodeWithSelector(
      0x5e79ee45,
      communityId,
      HabitatBase.getTotalMemberCount(communityId),
      getTotalValueLocked(governanceToken),
      proposer,
      getBalance(governanceToken, proposer),
      startDate,
      internalActions,
      externalActions
    );
    uint256 MAX_GAS = 90000;
    address vaultCondition = _getVaultCondition(vault);
    assembly {
      // check if we have enough gas to spend (relevant in challenges)
      if lt(gas(), MAX_GAS) {
        // do a silent revert to signal the challenge routine that this is an exception
        revert(0, 0)
      }
      let success := staticcall(MAX_GAS, vaultCondition, add(_calldata, 32), mload(_calldata), 0, 0)
      // revert and forward any returndata
      if iszero(success) {
        // propagate any revert messages
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  /// @notice Creates a proposal belonging to `vault`.
  /// @param startDate Should be within a reasonable range. See `_PROPOSAL_DELAY`
  /// @param internalActions includes L2 specific actions if this proposal passes.
  /// @param externalActions includes L1 specific actions if this proposal passes. (execution permit)
  function onCreateProposal (
    address msgSender,
    uint256 nonce,
    uint256 startDate,
    address vault,
    bytes memory internalActions,
    bytes memory externalActions,
    bytes calldata metadata
  ) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);
    _validateTimestamp(startDate);

    // compute a deterministic id
    bytes32 proposalId = HabitatBase._calculateSeed(msgSender, nonce);
    // revert if such a proposal already exists (generally not possible due to msgSender, nonce)
    require(HabitatBase._getStorage(_PROPOSAL_VAULT_KEY(proposalId)) == 0, 'OCP1');

    // The vault module receives a callback at creation
    // Reverts if the module does not allow the creation of this proposal or if `vault` is invalid.
    _callCreateProposal(vault, msgSender, startDate, internalActions, externalActions);

    // store
    HabitatBase._setStorage(_PROPOSAL_START_DATE_KEY(proposalId), startDate);
    HabitatBase._setStorage(_PROPOSAL_VAULT_KEY(proposalId), vault);
    HabitatBase._setStorage(_PROPOSAL_HASH_INTERNAL_KEY(proposalId), keccak256(internalActions));
    HabitatBase._setStorage(_PROPOSAL_HASH_EXTERNAL_KEY(proposalId), keccak256(externalActions));
    // update member count
    HabitatBase._maybeUpdateMemberCount(proposalId, msgSender);

    if (_shouldEmitEvents()) {
      emit ProposalCreated(vault, proposalId, startDate);
      // internal event for submission deadlines
      _emitTransactionDeadline(startDate + _PROPOSAL_DELAY());
    }
  }

  /// @dev Helper function to retrieve the governance token given `proposalId`.
  /// Reverts if `proposalId` is invalid.
  function _getTokenOfProposal (bytes32 proposalId) internal returns (address) {
    address vault = address(HabitatBase._getStorage(_PROPOSAL_VAULT_KEY(proposalId)));
    bytes32 communityId = HabitatBase.communityOfVault(vault);
    address token = HabitatBase.tokenOfCommunity(communityId);
    // only check token here, assuming any invalid proposalId / vault will end with having a zero address
    require(token != address(0), 'GTOP1');

    return token;
  }

  /// @dev Helper function for validating and applying votes
  function _votingRoutine (
    address account,
    uint256 previousVote,
    uint256 previousSignal,
    uint256 signalStrength,
    uint256 shares,
    bytes32 proposalId,
    bool delegated
  ) internal {
    // requires that the signal is in a specific range...
    require(signalStrength < 101, 'VR1');

    if (previousVote == 0 && shares != 0) {
      // a new vote - increment vote count
      HabitatBase._incrementStorage(HabitatBase._VOTING_COUNT_KEY(proposalId), 1);
    }
    if (shares == 0) {
      // removes a vote - decrement vote count
      require(signalStrength == 0 && previousVote != 0, 'VR2');
      HabitatBase._decrementStorage(HabitatBase._VOTING_COUNT_KEY(proposalId), 1);
    }

    HabitatBase._maybeUpdateMemberCount(proposalId, account);

    if (delegated) {
      HabitatBase._setStorage(_DELEGATED_VOTING_SHARES_KEY(proposalId, account), shares);
      HabitatBase._setStorage(_DELEGATED_VOTING_SIGNAL_KEY(proposalId, account), signalStrength);
    } else {
      HabitatBase._setStorage(_VOTING_SHARES_KEY(proposalId, account), shares);
      HabitatBase._setStorage(_VOTING_SIGNAL_KEY(proposalId, account), signalStrength);
    }

    // update total share count and staking amount
    if (previousVote != shares) {
      address token = _getTokenOfProposal(proposalId);
      uint256 activeStakeKey =
        delegated ? _DELEGATED_VOTING_ACTIVE_STAKE_KEY(token, account) : _VOTING_ACTIVE_STAKE_KEY(token, account);

      HabitatBase._setStorageDelta(activeStakeKey, previousVote, shares);
      HabitatBase._setStorageDelta(_VOTING_TOTAL_SHARE_KEY(proposalId), previousVote, shares);
    }

    // update total signal
    if (previousSignal != signalStrength) {
      HabitatBase._setStorageDelta(_VOTING_TOTAL_SIGNAL_KEY(proposalId), previousSignal, signalStrength);
    }
  }

  /// @dev State transition routine for `VoteOnProposal`.
  /// Note: Votes can be changed/removed anytime.
  function onVoteOnProposal (
    address msgSender,
    uint256 nonce,
    bytes32 proposalId,
    uint256 shares,
    address delegatee,
    uint8 signalStrength
  ) external {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    address token = _getTokenOfProposal(proposalId);

    if (delegatee == address(0)) {
      // voter account
      address account = msgSender;
      uint256 previousVote = HabitatBase._getStorage(_VOTING_SHARES_KEY(proposalId, account));
      // check for discrepancy between balance and stake
      uint256 stakableBalance = getUnlockedBalance(token, account) + previousVote;
      require(stakableBalance >= shares, 'OVOP1');
      uint256 previousSignal = HabitatBase._getStorage(_VOTING_SIGNAL_KEY(proposalId, account));

      _votingRoutine(account, previousVote, previousSignal, signalStrength, shares, proposalId, false);

      if (_shouldEmitEvents()) {
        emit VotedOnProposal(account, proposalId, signalStrength, shares);
      }
    } else {
      uint256 previousVote = HabitatBase._getStorage(_DELEGATED_VOTING_SHARES_KEY(proposalId, delegatee));
      uint256 previousSignal = HabitatBase._getStorage(_DELEGATED_VOTING_SIGNAL_KEY(proposalId, delegatee));
      uint256 maxAmount = HabitatBase._getStorage(_DELEGATED_ACCOUNT_TOTAL_AMOUNT_KEY(delegatee, token));
      uint256 currentlyStaked = HabitatBase._getStorage(_DELEGATED_VOTING_ACTIVE_STAKE_KEY(token, delegatee));
      // should not happen but anyway...
      require(maxAmount >= currentlyStaked, 'ODVOP1');

      if (msgSender == delegatee) {
        // the amount that is left
        uint256 freeAmount = maxAmount - (currentlyStaked - previousVote);
        // check for discrepancy between balance and stake
        require(freeAmount >= shares, 'ODVOP2');
      } else {
        // a user may only remove shares if there is no other choice
        // we have to account for
        // - msgSender balance
        // - msgSender personal stakes
        // - msgSender delegated balance
        // - delegatee staked balance

        // new shares must be less than old shares, otherwise what are we doing here?
        require(shares < previousVote, 'ODVOP3');

        if (shares != 0) {
          // the user is not allowed to change the signalStrength if not removing the vote
          require(signalStrength == previousSignal, 'ODVOP4');
        }

        uint256 unusedBalance = maxAmount - currentlyStaked;
        uint256 maxRemovable = HabitatBase._getStorage(_DELEGATED_ACCOUNT_ALLOWANCE_KEY(msgSender, delegatee, token));
        // only allow changing the stake if the user has no other choice
        require(maxRemovable > unusedBalance, 'ODVOP5');
        // the max. removable amount is the total delegated amount - the unused balance of delegatee
        maxRemovable = maxRemovable - unusedBalance;
        if (maxRemovable > previousVote) {
          // clamp
          maxRemovable = previousVote;
        }

        uint256 sharesToRemove = previousVote - shares;
        require(maxRemovable >= sharesToRemove, 'ODVOP6');
      }

      _votingRoutine(delegatee, previousVote, previousSignal, signalStrength, shares, proposalId, true);

      if (_shouldEmitEvents()) {
        emit DelegateeVotedOnProposal(delegatee, proposalId, signalStrength, shares);
      }
    }
  }

  /// @dev Invokes IModule.onProcessProposal(...) on `vault`
  /// Assumes that `vault` was already validated.
  function _callProcessProposal (
    bytes32 proposalId,
    address vault
  ) internal returns (uint256 votingStatus, uint256 secondsTillClose, uint256 quorumPercent)
  {
    uint256 secondsPassed;
    {
      uint256 dateNow = _getTime();
      uint256 proposalStartDate = HabitatBase._getStorage(_PROPOSAL_START_DATE_KEY(proposalId));

      if (dateNow > proposalStartDate) {
        secondsPassed = dateNow - proposalStartDate;
      }
    }

    bytes32 communityId = HabitatBase.communityOfVault(vault);
    // call vault with all the statistics
    bytes memory _calldata = abi.encodeWithSelector(
      0xf8d8ade6,
      proposalId,
      communityId,
      HabitatBase.getTotalMemberCount(communityId),
      HabitatBase._getStorage(_VOTING_COUNT_KEY(proposalId)),
      HabitatBase.getTotalVotingShares(proposalId),
      HabitatBase._getStorage(_VOTING_TOTAL_SIGNAL_KEY(proposalId)),
      getTotalValueLocked(HabitatBase.tokenOfCommunity(communityId)),
      secondsPassed
    );
    uint256 MAX_GAS = 90000;
    address vaultCondition = _getVaultCondition(vault);
    assembly {
      let ptr := mload(64)
      // clear memory
      calldatacopy(ptr, calldatasize(), 96)
      // check if we have enough gas to spend (relevant in challenges)
      if lt(gas(), MAX_GAS) {
        // do a silent revert to signal the challenge routine that this is an exception
        revert(0, 0)
      }
      // call
      let success := staticcall(MAX_GAS, vaultCondition, add(_calldata, 32), mload(_calldata), ptr, 96)
      if success {
        votingStatus := mload(ptr)
        ptr := add(ptr, 32)
        secondsTillClose := mload(ptr)
        ptr := add(ptr, 32)
        quorumPercent := mload(ptr)
      }
    }
  }

  /// @notice Updates the state of a proposal.
  /// @dev Only emits a event if the status changes to CLOSED or PASSED
  function onProcessProposal (
    address msgSender,
    uint256 nonce,
    bytes32 proposalId,
    bytes calldata internalActions,
    bytes calldata externalActions
  ) external returns (uint256 votingStatus, uint256 secondsTillClose, uint256 quorumPercent) {
    HabitatBase._commonChecks();
    HabitatBase._checkUpdateNonce(msgSender, nonce);

    {
      uint256 previousVotingStatus = HabitatBase.getProposalStatus(proposalId);
      require(previousVotingStatus < uint256(IModule.VotingStatus.CLOSED), 'CLOSED');
    }

    // this will revert in _getVaultCondition if the proposal doesn't exist or `vault` is invalid
    address vault = address(HabitatBase._getStorage(_PROPOSAL_VAULT_KEY(proposalId)));

    (votingStatus, secondsTillClose, quorumPercent) = _callProcessProposal(proposalId, vault);

    // finalize if the new status is CLOSED or PASSED
    if (votingStatus > uint256(IModule.VotingStatus.OPEN)) {
      // save voting status
      HabitatBase._setStorage(_PROPOSAL_STATUS_KEY(proposalId), votingStatus);

      // PASSED
      if (votingStatus == uint256(IModule.VotingStatus.PASSED)) {
        // verify the internal actions and execute
        bytes32 hash = keccak256(internalActions);
        require(HabitatBase._getStorage(_PROPOSAL_HASH_INTERNAL_KEY(proposalId)) == uint256(hash), 'IHASH');
        _executeInternalActions(vault, internalActions);

        // verify external actions and store a permit
        hash = keccak256(externalActions);
        require(HabitatBase._getStorage(_PROPOSAL_HASH_EXTERNAL_KEY(proposalId)) == uint256(hash), 'EHASH');
        if (externalActions.length != 0) {
          HabitatBase._setExecutionPermit(vault, proposalId, hash);
        }
      }

      if (_shouldEmitEvents()) {
        emit ProposalProcessed(proposalId, votingStatus);
      }
    }
  }
}
