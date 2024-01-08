// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./ITokenTimelock.sol";
import "./IDetf.sol";


/**
 * @title Storage for Governor Delegate
 * @notice For future upgrades, do not change GovernorStorage. Create a new
 * contract which implements GovernorStorage and following the naming convention
 * Governor DelegateStorageVX.
 */
contract GovernorStorage {
    /// @notice Administrator for this contract
    address public admin;

    /// @notice Pending administrator for this contract
    address public pendingAdmin;

    /// @notice Active brains of Governor
    address public implementation;

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

    /// @notice The address of the DETF Protocol Timelock
    ITokenTimelock public timelock;

    /// @notice The address of the DETF token
    IDetf public detf;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;


    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;

        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;

        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;

        /// @notice The ordered list of function signatures to be called
        string[] signatures;

        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;

        /// @notice Current number of votes in favor of this proposal
        uint256 forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint256 againstVotes;

        /// @notice Current number of votes for abstaining for this proposal
        uint256 abstainVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal or abstains
        uint8 support;

        /// @notice The number of votes the voter had, which were cast
        uint256 votes;
    }

    /// @notice Possible states that a proposal may be in
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }
}