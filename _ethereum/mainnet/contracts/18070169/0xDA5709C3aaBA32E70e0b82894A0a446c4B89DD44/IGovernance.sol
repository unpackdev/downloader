// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IVoteStrategy.sol";

enum ProposalState { Auto, Pending, Voting, Passed, Failed, Queued, Executed, Canceled, Expired }

struct ProposalMeta {
    uint256 proposalId;
    ProposalState state;        
    uint64 startedAt;   // the timestamp when this proposal is active for voting
    uint64 endedBy;     // the timestamp when this proposal finish
    uint64 executionTime;
    bytes32 contentHash;    // hash of the proposal content
    address target;     // the address of the affected DABot, 0x0 address for platform setting
    address proposer;   // the account who initiates this proposal
    uint256 blockNo;
    uint256 forVotes;
    uint256 againstVotes;
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] args;
    bool[] delegateCalls;
}

interface IGovernanceEvent {
    event DefaultStrategyChanged(address indexed strategy);
    event StrategyChanged(address indexed target, address indexed strategy);
    event ExecutorChanged(address indexed executor);
    event NewProposal(uint proposalId, string title, uint64 startedAt, uint64 endedBy, address indexed target,
                    address indexed proposer, bytes32 contentHash);
    event StateChanged(uint proposalId, ProposalState newState, bytes data);
    event Vote(address indexed voter, uint proposalId, uint votePower, bool support);
    event Unvote(address indexed voter, uint proposalId);
}

interface IGovernance is IGovernanceEvent {

    function setDefaultStrategy(IVoteStrategy strategy) external;
    function setVoteStrategy(address target, IVoteStrategy strategy) external;

    function getProposalById(uint proposalId) external view returns(ProposalMeta memory);
    function createProposal(
        string memory title,
        address target,
        bytes32 contentHash,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory args,
        bool[] memory delegateCalls
    ) external returns(uint);
    function cancelProposal(uint256 proposalId) external;
    function vote(uint256 proposalId, bool support) external;
    function unvote(uint256 proposalId) external;
    function updateState(uint256 proposalId, ProposalState state) external;
    function queueProposal(uint256 proposalId) external;
    function executeProposal(uint256 proposalId) external payable;
}
