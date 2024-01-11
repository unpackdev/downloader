// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

import "./SafeMath.sol";
import "./ITokenTimelock.sol";
import "./GovernorEvents.sol";
import "./GovernorStorage.sol";


/// @title Governor logic smart contract
/// @author D-ETF.com
/// @notice Logical implementation of the Governor smart contract (used by proxy).
/// @dev Governor is the governance module of the protocol; it allows addresses with more than required DETF to propose changes to the protocol.
/// Addresses that held voting weight, at the start of the proposal, invoked through the getpriorvotes function, can submit their votes during a 3 day voting period.
/// If a majority are cast for the proposal, it is queued in the Timelock, and can be implemented after 2 days.
contract Governor is GovernorStorage, GovernorEvents {
    using SafeMath for uint256;

    /// @notice The name of this contract
    string public constant name = "DETF Governor";

    /// @notice The minimum setable proposal threshold
    uint256 public constant MIN_PROPOSAL_THRESHOLD = 10000e18; // 10,000 DETF

    /// @notice The maximum setable proposal threshold
    uint256 public constant MAX_PROPOSAL_THRESHOLD = 500000e18; //500,000 DETF

    /// @notice The minimum setable voting period
    // uint256 public constant MIN_VOTING_PERIOD = 5760; // About 24 hours [5760 x 15 = 86400]
    uint256 public constant MIN_VOTING_PERIOD = 240;     // About 1 hour [240 x 15 = 3600]

    /// @notice The max setable voting period
    uint256 public constant MAX_VOTING_PERIOD = 161280; // About 4 weeks

    /// @notice The min setable voting delay
    uint256 public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint256 public constant MAX_VOTING_DELAY = 40320; // About 1 week

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint256 public constant quorumVotes = 4000000e18; // 4,000,000

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant proposalMaxOperations = 10; // 10 actions

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract).");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support).");

    bool public isInitiate = false;

    //  --------------------
    //  SETTERS
    //  --------------------


    /**
      * @notice Used to initialize the contract during delegator contructor
      * @param timelock_ The address of the Timelock
      * @param detf_ The address of the DETF token
      * @param votingPeriod_ The initial voting period
      * @param votingDelay_ The initial voting delay
      * @param proposalThreshold_ The initial proposal threshold
      */
    function initialize(address timelock_, address detf_, uint256 votingPeriod_, uint256 votingDelay_, uint256 proposalThreshold_) public {
        require(address(timelock) == address(0), "initialize: can only initialize once.");
        require(msg.sender == admin, "initialize: admin only.");
        require(timelock_ != address(0), "initialize: invalid timelock address.");
        require(detf_ != address(0), "initialize: invalid Detf address.");
        require(votingPeriod_ >= MIN_VOTING_PERIOD && votingPeriod_ <= MAX_VOTING_PERIOD, "initialize: invalid voting period.");
        require(votingDelay_ >= MIN_VOTING_DELAY && votingDelay_ <= MAX_VOTING_DELAY, "initialize: invalid voting delay.");
        require(proposalThreshold_ >= MIN_PROPOSAL_THRESHOLD && proposalThreshold_ <= MAX_PROPOSAL_THRESHOLD, "initialize: invalid proposal threshold.");

        timelock = ITokenTimelock(timelock_);
        detf = IDetf(detf_);
        votingPeriod = votingPeriod_;
        votingDelay = votingDelay_;
        proposalThreshold = proposalThreshold_;
    }

    /**
      * @notice Initiate the Governor contract
      * @dev Admin only. Sets initial proposal id which initiates the contract, ensuring a continuous proposal id count
      */
    function initiate() public {
        require(msg.sender == admin, "initiate: admin only.");
        require(initialProposalId == 0, "initiate: can only initiate once.");
        initialProposalId = 0;
        timelock.acceptAdmin();

        require(!isInitiate, "initiate: really can only initiate once.");
        isInitiate = true;
    }

    /**
      * @notice Function used to propose a new proposal. Sender must have delegates above the proposal threshold
      * @param targets Target addresses for proposal calls
      * @param values Eth values for proposal calls
      * @param signatures Function signatures for proposal calls
      * @param calldatas Calldatas for proposal calls
      * @param description String description of the proposal
      * @return Proposal id of new proposal
      */
    function propose(address[] memory targets, uint256[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) public returns (uint) {
        // Reject proposals before initiating as Governor
        // require(initialProposalId != 0, "propose: Governor not active.");
        require(isInitiate, "propose: Governor is really not active.");
        require(detf.getPriorVotes(msg.sender, block.number - 1) >= proposalThreshold, "propose: proposer votes below proposal threshold.");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "propose: proposal function information arity mismatch.");
        require(targets.length != 0, "propose: must provide actions.");
        require(targets.length <= proposalMaxOperations, "propose: too many actions.");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "propose: one live proposal per proposer, found an already active proposal.");
          require(proposersLatestProposalState != ProposalState.Pending, "propose: one live proposal per proposer, found an already pending proposal.");
        }

        uint256 startBlock = block.number.add(votingDelay);
        uint256 endBlock = startBlock.add(votingPeriod);

        proposalCount++;
        proposals[proposalCount].id = proposalCount;
        proposals[proposalCount].proposer = msg.sender;
        proposals[proposalCount].eta = 0;
        proposals[proposalCount].targets = targets;
        proposals[proposalCount].values = values;
        proposals[proposalCount].signatures = signatures;
        proposals[proposalCount].calldatas = calldatas;
        proposals[proposalCount].startBlock = startBlock;
        proposals[proposalCount].endBlock = endBlock;
        proposals[proposalCount].forVotes = 0;
        proposals[proposalCount].againstVotes = 0;
        proposals[proposalCount].canceled = false;
        proposals[proposalCount].executed = false;

        latestProposalIds[proposals[proposalCount].proposer] = proposals[proposalCount].id;

        emit ProposalCreated(proposals[proposalCount].id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return proposals[proposalCount].id;
    }

    /**
      * @notice Queues a proposal of state succeeded
      * @param proposalId The id of the proposal to queue
      */
    function queue(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "queue: proposal can only be queued if it is succeeded.");
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp.add(timelock.delay());
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevertInternal(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    /**
      * @notice Executes a queued proposal if eta has passed
      * @param proposalId The id of the proposal to execute
      */
    function execute(uint256 proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "execute: proposal can only be executed if it is queued.");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction{value: proposal.values[i]}(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    /**
      * @notice Cancels a proposal only if sender is the proposer, or proposer delegates dropped below proposal threshold
      * @param proposalId The id of the proposal to cancel
      */
    function cancel(uint256 proposalId) public {
        require(state(proposalId) != ProposalState.Executed, "cancel: cannot cancel executed proposal.");

        Proposal storage proposal = proposals[proposalId];
        require(msg.sender == proposal.proposer || detf.getPriorVotes(proposal.proposer, block.number - 1) < proposalThreshold, "cancel: proposer above threshold.");

        proposal.canceled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    /**
      * @notice Cast a vote for a proposal
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      */
    function castVote(uint256 proposalId, uint8 support) public {
        emit VoteCast(msg.sender, proposalId, support, _castVoteInternal(msg.sender, proposalId, support), ".");
    }

    /**
      * @notice Cast a vote for a proposal with a reason
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      * @param reason The reason given for the vote by the voter
      */
    function castVoteWithReason(uint256 proposalId, uint8 support, string calldata reason) public {
        emit VoteCast(msg.sender, proposalId, support, _castVoteInternal(msg.sender, proposalId, support), reason);
    }

    /**
      * @notice Cast a vote for a proposal by signature
      * @dev public function that accepts EIP-712 signatures for voting on proposals.
      */
    function castVoteBySig(uint256 proposalId, uint8 support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), block.chainid, address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "castVoteBySig: invalid signature.");
        emit VoteCast(signatory, proposalId, support, _castVoteInternal(signatory, proposalId, support), ".");
    }

    /**
      * @notice Admin function for setting the voting delay
      * @param newVotingDelay new voting delay, in blocks
      */
    function setVotingDelay(uint256 newVotingDelay) public {
        require(msg.sender == admin, "setVotingDelay: admin only.");
        require(newVotingDelay >= MIN_VOTING_DELAY && newVotingDelay <= MAX_VOTING_DELAY, "_setVotingDelay: invalid voting delay.");
        uint256 oldVotingDelay = votingDelay;
        votingDelay = newVotingDelay;

        emit VotingDelaySet(oldVotingDelay,votingDelay);
    }

    /**
      * @notice Admin function for setting the voting period
      * @param newVotingPeriod new voting period, in blocks
      */
    function setVotingPeriod(uint256 newVotingPeriod) public {
        require(msg.sender == admin, "setVotingPeriod: admin only.");
        require(newVotingPeriod >= MIN_VOTING_PERIOD && newVotingPeriod <= MAX_VOTING_PERIOD, "_setVotingPeriod: invalid voting period.");
        uint256 oldVotingPeriod = votingPeriod;
        votingPeriod = newVotingPeriod;

        emit VotingPeriodSet(oldVotingPeriod, votingPeriod);
    }

    /**
      * @notice Admin function for setting the proposal threshold
      * @dev newProposalThreshold must be greater than the hardcoded min
      * @param newProposalThreshold new proposal threshold
      */
    function setProposalThreshold(uint256 newProposalThreshold) public {
        require(msg.sender == admin, "setProposalThreshold: admin only.");
        require(newProposalThreshold >= MIN_PROPOSAL_THRESHOLD && newProposalThreshold <= MAX_PROPOSAL_THRESHOLD, "_setProposalThreshold: invalid proposal threshold.");
        uint256 oldProposalThreshold = proposalThreshold;
        proposalThreshold = newProposalThreshold;

        emit ProposalThresholdSet(oldProposalThreshold, proposalThreshold);
    }

    /**
      * @notice Begins transfer of admin rights. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @dev Admin function to begin change of admin. The newPendingAdmin must call `_acceptAdmin` to finalize the transfer.
      * @param newPendingAdmin New pending admin.
      */
    function setPendingAdmin(address newPendingAdmin) public {
        // Check caller = admin
        require(msg.sender == admin, "setPendingAdmin: admin only.");

        // Save current value, if any, for inclusion in log
        address oldPendingAdmin = pendingAdmin;

        // Store pendingAdmin with value newPendingAdmin
        pendingAdmin = newPendingAdmin;

        // Emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin)
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }

    /**
      * @notice Accepts transfer of admin rights. msg.sender must be pendingAdmin
      * @dev Admin function for pending admin to accept role and update admin
      */
    function acceptAdmin() public {
        // Check caller is pendingAdmin and pendingAdmin ≠ address(0)
        require(msg.sender == pendingAdmin && msg.sender != address(0), "acceptAdmin: pending admin only.");

        // Save current values for inclusion in log
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;

        // Store admin with value pendingAdmin
        admin = pendingAdmin;

        // Clear the pending value
        pendingAdmin = address(0);

        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }


    //  --------------------
    //  GETTERS
    //  --------------------


    function getActions(uint256 proposalId) public view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[proposalId];
        return (
            p.targets,
            p.values,
            p.signatures,
            p.calldatas
        );
    }

    /**
      * @notice Gets the receipt for a voter on a given proposal
      * @param proposalId the id of proposal
      * @param voter The address of the voter
      * @return The voting receipt
      */
    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    /**
      * @notice Gets the state of a proposal
      * @param proposalId The id of the proposal
      * @return Proposal state
      */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > initialProposalId, "state: invalid proposal id.");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta.add(timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }


    //  --------------------
    //  INTERNAL
    //  --------------------


    /**
      * @notice Internal function that caries out voting logic
      * @param voter The voter that is casting their vote
      * @param proposalId The id of the proposal to vote on
      * @param support The support value for the vote. 0=against, 1=for, 2=abstain
      * @return The number of votes cast
      */
    function _castVoteInternal(address voter, uint256 proposalId, uint8 support) internal returns (uint256) {
        require(state(proposalId) == ProposalState.Active, "_castVoteInternal: voting is closed.");
        require(support <= 2, "_castVoteInternal: invalid vote type.");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "_castVoteInternal: voter already voted.");
        uint256 votes = detf.getPriorVotes(voter, proposal.startBlock);

        if (support == 0) {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        } else if (support == 1) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else if (support == 2) {
            proposal.abstainVotes = proposal.abstainVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        return votes;
    }

    function _queueOrRevertInternal(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "_queueOrRevertInternal: identical proposal action already queued at eta.");
        timelock.queueTransaction(target, value, signature, data, eta);
    }
}