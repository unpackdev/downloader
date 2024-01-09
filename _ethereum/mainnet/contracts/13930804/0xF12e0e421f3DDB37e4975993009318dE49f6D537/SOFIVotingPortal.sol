// SPDX-License-Identifier: NONLINCENSE
pragma solidity ^0.8.0;

import "./Governable.sol";
import "./Signature.sol";
import "./Interfaces.sol";
import "./Strings.sol";
import "./ERC20.sol";

contract SOFIVotingPortal is Governable, Signature {
    using Strings for uint256;
    
    address public voteToken;
    address private signer;
    uint256 public proposalCount;
    
    uint256 public quorumVoteCount;
    uint256 public proposalThresholdCount;
    uint256 public globalPendingTime;
    uint256 public minDuration;
    uint256 public maxDuration;

    /// @notice The maximum number of actions that can be included in a proposal
    uint public constant proposalMaxOperations = 10; // 10 actions

     TimelockInterface public timelock;

    function initialize(address _governor) public override initializer {
        super.initialize(_governor);
    }

    function setInitialValue(
        address timelock_,
        address _voteToken,
        address _signer,
        uint256 _quorumVoteCount,
        uint256 _proposalThresholdCount,
        uint256 _globalPendingTime,
        uint256 _minDuration,
        uint256 _maxDuration) external governance {
            timelock = TimelockInterface(timelock_);
            voteToken = _voteToken;
            signer = _signer;
            quorumVoteCount = _quorumVoteCount;
            proposalThresholdCount = _proposalThresholdCount;
            globalPendingTime = _globalPendingTime;
            minDuration = _minDuration;
            maxDuration = _maxDuration;
        }

    function setTimelock(address timelock_) external governance {
        timelock = TimelockInterface(timelock_);
    }
    
    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function setQuorumVotes(uint256 count) external governance {
        quorumVoteCount = count;
    }
    /// @notice The number of votes required in order for a voter to become a proposer
    function setProposalThrehold(uint256 count) external governance {
        proposalThresholdCount = count;
    }
    
    function setGlobalPendingTime(uint256 time) external governance {
        globalPendingTime = time;
    }
    
    function setStartTime(uint256 proposalId, uint256 time) external governance {
        proposals[proposalId].startTime = time;
    }
    
    function setEndTime(uint256 proposalId, uint256 time) external governance {
        proposals[proposalId].endTime = time;
    }
    
    function setMinDuration(uint256 _duration) external governance {
        minDuration = _duration;
    }
    
    function setMaxDuration(uint256 _duration) external governance {
        maxDuration = _duration;
    }
    
    function setSigner(address _signer) external governance {
        signer = _signer;
    }
    
    struct Proposal {

        uint256 id;

        address proposer;

        uint256 proposalThresholdCount;

        uint256 eta;

        address[] targets;

        uint[] values;

        string[] signatures;

        bytes[] calldatas;

        uint256 createTime;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 blockHeight;
        
        bool canceled;

        bool executed;
        
        bool withdrawn;
    }
    
    struct Receipt {
        bool hasVoted;

        bool support;

        uint256 votes;
    }
    
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
    
    /// @notice The official record of all proposals ever proposed
    mapping (uint256 => Proposal) public proposals;
    
    /// @notice Receipts of ballots for the entire set of voters
    mapping (uint256 => mapping(address => Receipt)) public receipts;
    
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint256 id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint256 startTime, uint256 endTime, string title, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalDepositWithdrawn(uint256 id, address claimer);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);
    
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, uint256 endTime, string memory title, string memory description) public returns (uint256) {
        uint256 startTime = block.timestamp + globalPendingTime;
        require(startTime < endTime, "propose:: start time must be earlier than end time");
        require((endTime - startTime > minDuration) && (endTime - startTime < maxDuration), "propose:: illegal duration");

        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "propose: proposal function information mismatch");
        require(targets.length <= proposalMaxOperations, "propose: too many actions");

        ERC20(voteToken).transferFrom(msg.sender, address(this), proposalThresholdCount);
        proposalCount++;
        Proposal memory newProposal = Proposal(
            proposalCount,
            msg.sender,
            proposalThresholdCount,
            0,
            targets,
            values,
            signatures,
            calldatas,
            block.timestamp,
            block.timestamp + globalPendingTime,
            endTime,
            0,
            0,
            block.number,
            false,
            false,
            false);
        proposals[proposalCount] = newProposal;

        emit ProposalCreated(proposalCount, msg.sender, targets, values, signatures, calldatas, startTime, endTime, title, description);
        return proposalCount;
    }

    /**
      * @notice Queues a proposal of state succeeded
      * @param proposalId The id of the proposal to queue
      */
    function queue(uint proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorBravo::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.targets.length > 0, "queue: proposal no actions");
        uint eta = block.timestamp + timelock.delay();
        for (uint i = 0; i < proposal.targets.length; i++) {
            queueOrRevertInternal(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function queueOrRevertInternal(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorBravo::queueOrRevertInternal: identical proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    /**
      * @notice Executes a queued proposal if eta has passed
      * @param proposalId The id of the proposal to execute
      */
    function execute(uint proposalId) external payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorBravo::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        require(proposal.targets.length > 0, "execute: proposal no actions");
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }
    
    function cancel(uint256 proposalId) public {
        require(msg.sender == proposals[proposalId].proposer, "cancel: only proposal owner could cancel proposal.");
        ProposalState _state = state(proposalId);
        require(_state != ProposalState.Executed, "cancel: cannot cancel executed proposal");
        Proposal storage proposal = proposals[proposalId];
        proposal.canceled = true;
        _claim(proposalId);
        emit ProposalCanceled(proposalId);
    }
    
    function claim(uint256 proposalId) public {
        require(msg.sender == proposals[proposalId].proposer, "claim: only proposal owner could claim proposal.");
        ProposalState _state = state(proposalId);
        require(_state != ProposalState.Canceled, "claim: cannot claim canceled proposal");
        require(_state != ProposalState.Pending, "claim: cannot claim pending proposal");
        require(_state != ProposalState.Active, "claim: cannot claim active proposal");
        _claim(proposalId);
        emit ProposalDepositWithdrawn(proposalId, msg.sender);
    }
    
    function _claim(uint256 proposalId) internal {
        require(proposals[proposalId].withdrawn == false, "claim: already claimed");
        proposals[proposalId].withdrawn = true;
        ERC20(voteToken).transfer(msg.sender, proposals[proposalId].proposalThresholdCount);
    }
    
    function castVoteBySig(uint256 proposalId, bool support, uint256 voteCount, bytes memory signature) public {
        address signatory = verify(
            voteToken,
            msg.sender,
            voteCount,
            proposals[proposalId].blockHeight,
            signature
        );
        require(signatory == signer, "castVoteBySig: invalid signature");
        return _castVote(msg.sender, proposalId, support, voteCount);
    }
    
    function _castVote(address voter, uint256 proposalId, bool support, uint256 voteCount) internal {
        require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is not active");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = receipts[proposalId][voter];
        require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");

        if (support) {
            proposal.forVotes = proposal.forVotes + voteCount;
        } else {
            proposal.againstVotes = proposal.againstVotes + voteCount;
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = voteCount;

        emit VoteCast(voter, proposalId, support, voteCount);
    }
    
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.timestamp <= proposal.startTime) {
            return ProposalState.Pending;
        } else if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || ((proposal.forVotes + proposal.againstVotes) < quorumVoteCount)) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= (proposal.eta + timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }
}