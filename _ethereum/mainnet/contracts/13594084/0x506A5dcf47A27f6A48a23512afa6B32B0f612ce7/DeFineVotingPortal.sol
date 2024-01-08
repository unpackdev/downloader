// SPDX-License-Identifier: NONLINCENSE
pragma solidity ^0.8.0;

import "./Governable.sol";
import "./Signature.sol";
import "./Strings.sol";
import "./SafeERC20Upgradeable.sol";

contract DeFineVotingPortal is Governable, Signature {
    using Strings for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    
    address public voteToken;
    address private signer;
    uint256 private proposalCount;
    
    uint256 public quorumVoteCount;
    uint256 public proposalThresholdCount;
    uint256 public globalPendingTime;
    uint256 public minDuration;
    uint256 public maxDuration;

    function initialize(address _governor) public override initializer {
        super.initialize(_governor);
    }

    function setInitialValue(
        address _voteToken,
        address _signer,
        uint256 _quorumVoteCount,
        uint256 _proposalThresholdCount,
        uint256 _globalPendingTime,
        uint256 _minDuration,
        uint256 _maxDuration) external governance {
            voteToken = _voteToken;
            signer = _signer;
            quorumVoteCount = _quorumVoteCount;
            proposalThresholdCount = _proposalThresholdCount;
            globalPendingTime = _globalPendingTime;
            minDuration = _minDuration;
            maxDuration = _maxDuration;
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
        /// @notice Unique id for looking up a proposal
        uint256 id;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        uint256 createTime;
        uint256 startTime;
        uint256 endTime;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 blockHeight;
        
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;
        
        // @notice Flag marking whether the proposal has been withdrawn
        bool withdrawn;
    }
    
    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;

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
    
    /// @notice The official record of all proposals ever proposed
    mapping (uint256 => Proposal) public proposals;
    
    /// @notice Receipts of ballots for the entire set of voters
    mapping (uint256 => mapping(address => Receipt)) public receipts;
    
    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint256 id, address proposer, uint256 startTime, uint256 endTime, string title, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalDepositWithdrawn(uint256 id, address claimer);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);
    
    function propose(uint256 endTime, string memory title, string memory description) public returns (uint256) {
        uint256 startTime = block.timestamp + globalPendingTime;
        require(startTime < endTime, "purpose:: start time must be earlier than end time");
        require((endTime - startTime > minDuration) && (endTime - startTime < maxDuration), "purpose:: illegal duration");
        IERC20Upgradeable(voteToken).safeTransferFrom(msg.sender, address(this), proposalThresholdCount);
        proposalCount++;
        Proposal memory newProposal = Proposal(
            proposalCount,
            msg.sender,
            0,
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

        emit ProposalCreated(proposalCount, msg.sender, startTime, endTime, title, description);
        return proposalCount;
    }
    
    function setExecute(uint256 proposalId, bool status) public payable governance {
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = status;
        if (status == true) {
            emit ProposalExecuted(proposalId);
        }
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
        IERC20Upgradeable(voteToken).safeTransfer(msg.sender, proposalThresholdCount);
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
        require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
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
        } else if (block.timestamp >= proposal.eta) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }
}