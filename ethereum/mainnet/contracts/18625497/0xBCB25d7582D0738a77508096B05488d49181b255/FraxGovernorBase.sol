// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FraxGovernorBase =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Jon Walch: https://github.com/jonwalch

// Reviewers
// Drake Evans: https://github.com/DrakeEvans
// Dennis: https://github.com/denett
// Sam Kazemian: https://github.com/samkazemian

// ====================================================================

import "./Checkpoints.sol";
import "./IERC5805.sol";
import "./Governor.sol";
import "./GovernorCountingFractional.sol";
import "./GovernorSettings.sol";
import "./GovernorVotesQuorumFraction.sol";
import "./GovernorVotesQuorumFraction.sol";
import "./IVeFxs.sol";

struct ConstructorParams {
    address veFxs;
    address veFxsVotingDelegation;
    string _name;
    uint256 initialVotingDelay;
    uint256 initialVotingPeriod;
    uint256 initialProposalThreshold;
    uint256 quorumNumeratorValue;
    uint256 initialVotingDelayBlocks;
    uint256 initialShortCircuitNumerator;
}

/// @title FraxGovernorBase
/// @author Jon Walch (Frax Finance) https://github.com/jonwalch
/// @notice An abstract contract which contains the shared core logic and storage for FraxGovernorAlpha and FraxGovernorOmega
abstract contract FraxGovernorBase is GovernorSettings, GovernorVotesQuorumFraction, GovernorCountingFractional {
    using SafeCast for *;
    using Checkpoints for Checkpoints.Trace224;

    /// @notice Voting delay in number of blocks
    /// @dev only used to look up total veFXS supply on the VE_FXS contract
    uint256 public $votingDelayBlocks;

    /// @notice Address of the veFXS contract
    IVeFxs public immutable VE_FXS;

    /// @notice Checkpoints for short circuit numerator mirroring _quorumNumeratorHistory from GovernorVotesQuorumFraction.sol
    Checkpoints.Trace224 private _$shortCircuitNumeratorHistory;

    /// @notice Lookup from snapshot timestamp to corresponding snapshot block number, used for quorum
    mapping(uint256 snapshot => uint256 blockNumber) public $snapshotTimestampToSnapshotBlockNumber;

    /// @notice The ```ShortCircuitNumeratorUpdated``` event is emitted when governance changes the short circuit numerator
    /// @param oldShortCircuitNumerator The old short circuit numerator
    /// @param newShortCircuitNumerator The new contract address
    event ShortCircuitNumeratorUpdated(uint256 oldShortCircuitNumerator, uint256 newShortCircuitNumerator);

    /// @notice The ```VeFxsVotingDelegationSet``` event is emitted when governance changes the voting weight IERC5805 contract
    /// @param oldVotingDelegation The old contract address
    /// @param newVotingDelegation The new contract address
    event VeFxsVotingDelegationSet(address oldVotingDelegation, address newVotingDelegation);

    /// @notice The ```VotingDelayBlocksSet``` event is emitted when governance changes the voting delay in blocks
    /// @param oldVotingDelayBlocks The old short circuit numerator
    /// @param newVotingDelayBlocks The new contract address
    event VotingDelayBlocksSet(uint256 oldVotingDelayBlocks, uint256 newVotingDelayBlocks);

    /// @notice The ```constructor``` function is called on deployment
    /// @param params ConstructorParams struct
    constructor(
        ConstructorParams memory params
    )
        Governor(params._name)
        GovernorSettings(params.initialVotingDelay, params.initialVotingPeriod, params.initialProposalThreshold)
        GovernorVotes(IVotes(params.veFxsVotingDelegation))
        GovernorVotesQuorumFraction(params.quorumNumeratorValue)
    {
        VE_FXS = IVeFxs(params.veFxs);
        _updateShortCircuitNumerator(params.initialShortCircuitNumerator);
        _setVotingDelayBlocks(params.initialVotingDelayBlocks);

        // Emit manually because initial setting of `token` is in GovernorVotes' constructor
        emit VeFxsVotingDelegationSet({
            oldVotingDelegation: address(0),
            newVotingDelegation: params.veFxsVotingDelegation
        });
    }

    /// @notice The ```_requireSenderAboveProposalThreshold``` function checks if the proposer has sufficient voting weight
    function _requireSenderAboveProposalThreshold() internal view {
        if (_getVotes(msg.sender, block.timestamp - 1, "") < proposalThreshold()) {
            revert SenderVotingWeightBelowProposalThreshold();
        }
    }

    /// @notice The ```_setVotingDelayBlocks``` function is called by governance to change the voting delay in blocks
    /// @notice This must be changed in tandem with ```votingDelay``` to properly set quorum values
    /// @param votingDelayBlocks New voting delay in blocks value
    function _setVotingDelayBlocks(uint256 votingDelayBlocks) internal {
        uint256 oldVotingDelayBlocks = $votingDelayBlocks;
        $votingDelayBlocks = votingDelayBlocks;
        emit VotingDelayBlocksSet({
            oldVotingDelayBlocks: oldVotingDelayBlocks,
            newVotingDelayBlocks: votingDelayBlocks
        });
    }

    /// @notice The ```_setVeFxsVotingDelegation``` function is called by governance to change the voting weight IERC5805 contract
    /// @param veFxsVotingDelegation new IERC5805 VeFxsVotingDelegation contract address
    function _setVeFxsVotingDelegation(address veFxsVotingDelegation) internal {
        address oldVeFxsVotingDelegation = address(token);
        token = IERC5805(veFxsVotingDelegation);
        emit VeFxsVotingDelegationSet({
            oldVotingDelegation: oldVeFxsVotingDelegation,
            newVotingDelegation: veFxsVotingDelegation
        });
    }

    /// @notice The ```_quorumReached``` function is called by state() to check for early proposal success
    /// @param proposalId Proposal ID
    /// @return isQuorum Represents if quorum was reached or not
    function _quorumReached(
        uint256 proposalId
    ) internal view override(Governor, GovernorCountingFractional) returns (bool isQuorum) {
        (uint256 againstVoteWeight, uint256 forVoteWeight, uint256 abstainVoteWeight) = proposalVotes(proposalId);
        uint256 larger = againstVoteWeight > forVoteWeight ? againstVoteWeight : forVoteWeight;

        uint256 proposalVoteStart = proposalSnapshot(proposalId);
        isQuorum = quorum(proposalVoteStart) <= larger + abstainVoteWeight;
    }

    /// @notice The ```_shortCircuitFor``` function is called by state() to check for early proposal success
    /// @param proposalId Proposal ID
    /// @return isShortCircuitFor Represents if short circuit threshold for votes were reached or not
    function _shortCircuitFor(uint256 proposalId) internal view returns (bool isShortCircuitFor) {
        (, uint256 forVoteWeight, ) = proposalVotes(proposalId);

        uint256 proposalVoteStart = proposalSnapshot(proposalId);
        isShortCircuitFor = forVoteWeight > shortCircuitThreshold(proposalVoteStart);
    }

    /// @notice The ```_shortCircuitAgainst``` function is called by state() to check for early proposal failure
    /// @param proposalId Proposal ID
    /// @return isShortCircuitAgainst Represents if short circuit threshold against votes were reached or not
    function _shortCircuitAgainst(uint256 proposalId) internal view returns (bool isShortCircuitAgainst) {
        (uint256 againstVoteWeight, , ) = proposalVotes(proposalId);

        uint256 proposalVoteStart = proposalSnapshot(proposalId);
        isShortCircuitAgainst = againstVoteWeight > shortCircuitThreshold(proposalVoteStart);
    }

    /// @notice The ```_updateShortCircuitNumerator``` function is called by governance to change the short circuit numerator
    /// @dev Mirrors ```GovernorVotesQuorumFraction::_updateQuorumNumerator(uint256 newQuorumNumerator)```
    /// @param newShortCircuitNumerator New short circuit numerator value
    function _updateShortCircuitNumerator(uint256 newShortCircuitNumerator) internal {
        // Numerator must be less than or equal to denominator
        if (newShortCircuitNumerator > quorumDenominator()) {
            revert ShortCircuitNumeratorGreaterThanQuorumDenominator();
        }

        uint256 oldShortCircuitNumerator = shortCircuitNumerator();

        // Set new quorum for future proposals
        _$shortCircuitNumeratorHistory.push(SafeCast.toUint32(clock()), SafeCast.toUint224(newShortCircuitNumerator));

        emit ShortCircuitNumeratorUpdated({
            oldShortCircuitNumerator: oldShortCircuitNumerator,
            newShortCircuitNumerator: newShortCircuitNumerator
        });
    }

    function COUNTING_MODE() public pure override(IGovernor, GovernorCountingFractional) returns (string memory) {
        return "support=bravo&quorum=against,abstain&quorum=for,abstain&params=fractional";
    }

    /// @notice The ```shortCircuitNumerator``` function returns the latest short circuit numerator
    /// @dev Mirrors ```GovernorVotesQuorumFraction::quorumNumerator()```
    /// @return latestShortCircuitNumerator The short circuit numerator
    function shortCircuitNumerator() public view returns (uint256 latestShortCircuitNumerator) {
        latestShortCircuitNumerator = _$shortCircuitNumeratorHistory.latest();
    }

    /// @notice The ```shortCircuitNumerator``` function returns the short circuit numerator at ```timepoint```
    /// @dev Mirrors ```GovernorVotesQuorumFraction::quorumNumerator(uint256 timepoint)```
    /// @param timepoint A block.timestamp
    /// @return shortCircuitNumeratorAtTimepoint Short circuit numerator
    function shortCircuitNumerator(uint256 timepoint) public view returns (uint256 shortCircuitNumeratorAtTimepoint) {
        // If history is empty, fallback to old storage
        uint256 length = _$shortCircuitNumeratorHistory._checkpoints.length;

        // Optimistic search, check the latest checkpoint
        Checkpoints.Checkpoint224 memory latest = _$shortCircuitNumeratorHistory._checkpoints[length - 1];
        if (latest._key <= timepoint) {
            shortCircuitNumeratorAtTimepoint = latest._value;
            return shortCircuitNumeratorAtTimepoint;
        }

        // Otherwise, do the binary search
        shortCircuitNumeratorAtTimepoint = _$shortCircuitNumeratorHistory.upperLookupRecent(
            SafeCast.toUint32(timepoint)
        );
    }

    /// @notice The ```shortCircuitThreshold``` function returns the latest short circuit numerator
    /// @dev Only supports historical quorum values for proposals that actually exist at ```timepoint```
    /// @param timepoint A block.timestamp corresponding to a proposal snapshot
    /// @return shortCircuitThresholdAtTimepoint Total voting weight needed for short circuit to succeed
    function shortCircuitThreshold(uint256 timepoint) public view returns (uint256 shortCircuitThresholdAtTimepoint) {
        // uint256 snapshotBlockNumber = $snapshotTimestampToSnapshotBlockNumber[timepoint];
        if (timepoint == 0 || timepoint >= block.timestamp) revert InvalidTimepoint();

        shortCircuitThresholdAtTimepoint =
            (VE_FXS.totalSupplyAt(timepoint) * shortCircuitNumerator(timepoint)) /
            quorumDenominator();
    }

    /// @notice The ```quorum``` function returns the quorum value at ```timepoint```
    /// @dev Only supports historical quorum values for proposals that actually exist at ```timepoint```
    /// @param timepoint A block.timestamp corresponding to a proposal snapshot
    /// @return quorumAtTimepoint Quorum value at ```timepoint```
    function quorum(
        uint256 timepoint
    ) public view override(IGovernor, GovernorVotesQuorumFraction) returns (uint256 quorumAtTimepoint) {
        // uint256 snapshotBlockNumber = $snapshotTimestampToSnapshotBlockNumber[timepoint];
        if (timepoint == 0 || timepoint >= block.timestamp) revert InvalidTimepoint();

        quorumAtTimepoint =
            (VE_FXS.totalSupplyAt(timepoint) * quorumNumerator(timepoint)) /
            quorumDenominator();
    }

    /// @notice The ```bulkCastVote``` function allows the caller to vote on many proposals at once
    /// @param proposalId An array of proposalId
    /// @param support An array of support
    function bulkCastVote(uint256[] calldata proposalId, uint8[] calldata support) external {
        uint256 proposalIdsLength = proposalId.length;
        if (proposalIdsLength != support.length) {
            revert ParamLengthsNotEqual();
        }

        for (uint256 i = 0; i < proposalIdsLength; ++i) {
            castVote({ proposalId: proposalId[i], support: support[i] });
        }
    }

    /// Boilerplate overrides

    /**
     * @notice Cast a vote with a reason and additional encoded parameters using
     * the user's cryptographic signature.
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length
     * of params.
     *
     * @dev If casting a fractional vote via `params`, the voter's current nonce
     * must be appended to the `params` as the last 16 bytes and included in the
     * signature. I.e., the params used when constructing the signature would be:
     *
     *   abi.encodePacked(againstVotes, forVotes, abstainVotes, nonce)
     *
     * See {fractionalVoteNonce} and {_castVote} for more information.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override(Governor, GovernorCountingFractional) returns (uint256) {
        return
            GovernorCountingFractional.castVoteWithReasonAndParamsBySig({
                proposalId: proposalId,
                support: support,
                reason: reason,
                params: params,
                v: v,
                r: r,
                s: s
            });
    }

    /**
     * @dev See {Governor-proposalThreshold}.
     */
    function proposalThreshold() public view virtual override(Governor, GovernorSettings) returns (uint256) {
        return GovernorSettings.proposalThreshold();
    }

    error InvalidTimepoint();
    error ParamLengthsNotEqual();
    error SenderVotingWeightBelowProposalThreshold();
    error ShortCircuitNumeratorGreaterThanQuorumDenominator();
    error Unauthorized();
}
