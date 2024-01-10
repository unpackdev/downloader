// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./ICPOOL.sol";
import "./IMembershipStaking.sol";
import "./IFlashGovernor.sol";

contract FlashGovernor is IFlashGovernor, OwnableUpgradeable {
    struct Receipt {
        bool hasVoted;
        bool support;
    }

    struct Proposal {
        bool executed;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => Receipt) receipts;
    }

    /// @notice Mapping of IDs to proposals
    mapping(uint256 => Proposal) public proposals;

    /// @notice Mapping from addresses to flags if they are allowed to propose (no direct proposals from users to FlashGovernor)
    mapping(address => bool) public allowedProposers;

    /// @notice Minimal number of votes to reach quorum
    uint256 public quorumVotes;

    /// @notice Period of voting for proposal (in blocks)
    uint256 public votingPeriod;

    /// @notice CPOOL token contract (as primary votes source)
    ICPOOL public cpool;

    /// @notice Membership staking contract (as staked votes source)
    IMembershipStaking public staking;

    /// @notice ID of last created proposal
    uint32 public lastProposalId;

    // EVENTS

    /// @notice Event emitted when new proposal is created
    event ProposalCreated(uint32 indexed proposalId);

    /// @notice Event emitted when vote is case for some proposal
    event VoteCast(uint32 indexed proposalId, address voter, bool support);

    /// @notice Event emitted when proposal is executed
    event ProposalExecuted(uint32 indexed proposalId);

    /// @notice Event emitted when new quorum votes value is set
    event QuorumVotesSet(uint256 votes);

    /// @notice Event emitted when new voting period is set
    event VotingPeriodSet(uint256 period);

    /// @notice Event emitted when state of address as allowed proposer is changed
    event AllowedProposerSet(address proposer, bool allowed);

    // CONSTRUCTOR

    /**
     * @notice Upgradeable contract constructor
     * @param cpool_ The address of the CPOOL contract
     * @param staking_ The address of the MembershipStaking contract
     * @param quorumVotes_ Minimal number of votes to reach quorum
     * @param votingPeriod_ Period of voting for proposal (in blocks)
     */
    function initialize(
        address cpool_,
        address staking_,
        uint256 quorumVotes_,
        uint256 votingPeriod_
    ) public initializer {
        __Ownable_init();
        cpool = ICPOOL(cpool_);
        staking = IMembershipStaking(staking_);
        quorumVotes = quorumVotes_;
        votingPeriod = votingPeriod_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @notice Function is called by allowed proposer to create new proposal
     * @return ID of the created proposal
     */
    function propose() external returns (uint32) {
        require(allowedProposers[msg.sender], "PNA");

        lastProposalId++;
        proposals[lastProposalId].startBlock = block.number + 1;
        proposals[lastProposalId].endBlock = block.number + votingPeriod;

        emit ProposalCreated(lastProposalId);
        return lastProposalId;
    }

    /**
     * @notice Function is called by CPOOL delegate to vote for some proposal
     * @param proposalId ID of the proposal to vote for
     * @param support Support of the proposal (true to support, false to reject)
     */
    function vote(uint32 proposalId, bool support) external virtual {
        require(state(proposalId) == ProposalState.Active, "PWS");
        require(!proposals[proposalId].receipts[msg.sender].hasVoted, "HWA");

        proposals[proposalId].receipts[msg.sender].hasVoted = true;
        proposals[proposalId].receipts[msg.sender].support = support;
        uint256 votes = getVotesAtBlock(
            msg.sender,
            proposals[proposalId].startBlock
        );
        if (support) {
            proposals[proposalId].forVotes += votes;
        } else {
            proposals[proposalId].againstVotes += votes;
        }

        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @notice Function is called by allowed proposer to mark succeeded proposal as executed
     * @param proposalId ID of the proposal to mark
     */
    function execute(uint32 proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "PWS");
        require(allowedProposers[msg.sender], "APE");

        proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);
    }

    // RESTRICTED FUNCTIONS

    /**
     * @notice Function is called by contract owner to set quorum votes
     * @param quorumVotes_ New value for quorum votes
     */
    function setQuorumVotes(uint256 quorumVotes_) external onlyOwner {
        quorumVotes = quorumVotes_;
        emit QuorumVotesSet(quorumVotes_);
    }

    /**
     * @notice Function is called by contract owner to set voting period
     * @param votingPeriod_ New value for voting period
     */
    function setVotingPeriod(uint256 votingPeriod_) external onlyOwner {
        require(votingPeriod_ > 0, "VPZ");
        votingPeriod = votingPeriod_;
        emit VotingPeriodSet(votingPeriod_);
    }

    /**
     * @notice Function is called by contract owner to allow or forbid some proposer
     * @param proposer Address of the proposer to allow or forbid
     * @param allowed Allowance (true to allow, false to forbid)
     */
    function setAllowedProposer(address proposer, bool allowed)
        external
        onlyOwner
    {
        allowedProposers[proposer] = allowed;
        emit AllowedProposerSet(proposer, allowed);
    }

    // VIEW FUNCTIONS

    /**
     * @notice Function to get state of some proposal
     * @param proposalId ID of the proposal
     * @return Current proposal's state (as ProposalState enum)
     */
    function state(uint32 proposalId)
        public
        view
        virtual
        returns (ProposalState)
    {
        if (block.number <= proposals[proposalId].startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposals[proposalId].endBlock) {
            return ProposalState.Active;
        } else if (
            proposals[proposalId].forVotes <=
            proposals[proposalId].againstVotes ||
            proposals[proposalId].forVotes +
                proposals[proposalId].againstVotes <
            quorumVotes
        ) {
            return ProposalState.Defeated;
        } else if (!proposals[proposalId].executed) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Executed;
        }
    }

    /**
     * @notice Function to get voting end block of some proposal
     * @param proposalId ID of the proposal
     * @return Proposal's voting end block
     */
    function proposalEndBlock(uint32 proposalId)
        external
        view
        returns (uint256)
    {
        return proposals[proposalId].endBlock;
    }

    /**
     * @notice Function returns given account votes at given block
     * @param account Account to get votes for
     * @param blockNumber Block number to get votes at
     * @return Number of votes
     */
    function getVotesAtBlock(address account, uint256 blockNumber)
        public
        view
        returns (uint256)
    {
        return (uint256(cpool.getPriorVotes(account, blockNumber)) +
            staking.getPriorVotes(account, blockNumber));
    }

    /**
     * @notice Function to determine if sender has voted for given proposal
     * @param proposalId ID of the proposal
     * @return Receipt struct with voting information
     */
    function hasVoted(uint32 proposalId)
        external
        view
        returns (Receipt memory)
    {
        return proposals[proposalId].receipts[msg.sender];
    }
}
