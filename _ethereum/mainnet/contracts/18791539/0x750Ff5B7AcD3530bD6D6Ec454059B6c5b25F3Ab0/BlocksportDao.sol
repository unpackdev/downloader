// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

import "./ERC20Upgradeable.sol";

import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./EIP712DomainVoting.sol";


contract BlocksportDao is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    EIP712DomainVoting
{
    enum ProposalStatus {Inactive, Active, Executed, Cancelled}

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    ERC20Upgradeable public token;

    struct Proposal {
        uint256 id;
        string title;
        string description;
        address author;
        uint256 dateProposed;
        uint256 dateVotingEnds;
        uint256 _yesVotesTotalWeight; // total weight of yes votes (in $BSPT)
        // address[] voters;
        ProposalStatus proposalStatus;
    }

    struct Vote {
        uint256 proposalId;
        uint256 timestamp;
        address voter;
        uint256 nonce;
        bytes signature;
    }

    string public name;
    uint256 public proposalIndex;
    uint256 public votingDelay;
    uint256 public votingPeriod;
    uint256 public proposalThreshold;
    uint256 public quorumFraction;

    // proposalId => Proposal
    mapping(uint256 => Proposal) public proposals;

    // voter => nonce
    mapping(address => uint256) public nonces;

    // proposalId => voter => weight
    mapping(uint256 => mapping(address => uint256)) public votes;

    event ProposalCreated(uint256 indexed proposalId, address author);
    event VoteRecorded(address indexed voter, uint256 indexed proposalId, uint256 weight, uint256 timestamp, uint256 nonce, bytes signature);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus status, uint256 yesVotes, uint256 quorum);
    event ProposalCancelled(uint256 indexed proposalId, string reason);

    event AlreadyVoted(address indexed voter, uint256 indexed proposalId, uint256 timestamp, uint256 nonce, uint256 weight);
    event InvalidTimestamp(address indexed voter, uint256 indexed proposalId, uint256 timestamp, uint256 nonce, bytes signature);
    event InvalidSignature(address indexed voter, uint256 indexed proposalId, uint256 timestamp, uint256 nonce, bytes signature);
    event InvalidWeight(address indexed voter, uint256 indexed proposalId, uint256 timestamp, uint256 nonce, uint256 weight);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        string memory _name,
        uint256 _chainId,
        address _token,
        uint256 _quorumFraction,
        uint48 _initialVotingDelay,
        uint32 _initialVotingPeriod,
        uint256 _initialProposalThreshold,
        address _operator
    ) initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __EIP712DomainVoting_init(_name, _chainId);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);

        name = _name;
        token = ERC20Upgradeable(_token);
        quorumFraction = _quorumFraction;
        votingDelay = _initialVotingDelay;
        votingPeriod = _initialVotingPeriod;
        proposalThreshold = _initialProposalThreshold;
    }

    function createProposal(string memory title, string memory description) public {
        require(token.balanceOf(msg.sender) >= proposalThreshold, "Insufficient tokens to create proposal");

        uint256 proposalId = proposalIndex++;
        Proposal memory newProposal = Proposal({
            id: proposalId,
            title: title,
            description: description,
            author: msg.sender,
            dateProposed: block.timestamp,
            dateVotingEnds: block.timestamp + votingPeriod,
            _yesVotesTotalWeight: 0,
            proposalStatus: ProposalStatus.Active
        });
        proposals[proposalId] = newProposal;
        emit ProposalCreated(proposalId, msg.sender);
    }

    function recordVotesAndCloseProposal(uint256 proposalId, Vote[] memory votesArray) public {
        require(hasRole(OPERATOR_ROLE, msg.sender), "Caller is not an operator");

        uint256 dateVotingEnds = proposals[proposalId].dateVotingEnds;
        require(dateVotingEnds <= block.timestamp, "Voting period not end");

        require(proposals[proposalId].proposalStatus == ProposalStatus.Active, "Proposal not active");

        for (uint256 i = 0; i < votesArray.length; i++) {
            Vote memory vote = votesArray[i];
            address voter = vote.voter;
            uint256 weight = token.balanceOf(voter);
            uint256 timestamp = vote.timestamp;
            bytes memory signature = vote.signature;
            uint256 nonce = vote.nonce;
            nonces[voter] = nonce;

            if (votes[proposalId][voter] != 0) {
                emit AlreadyVoted(voter, proposalId, block.timestamp, nonces[voter], weight);
                continue;
            }

            if (timestamp < proposals[proposalId].dateProposed || timestamp > dateVotingEnds) {
                emit InvalidTimestamp(voter, proposalId, timestamp, nonce, signature);
                continue;
            }


            if (!verify(voter, proposalId, timestamp, nonce, signature)) {
                emit InvalidSignature(voter, proposalId, timestamp, nonce, signature);
                continue;
            }

            if (weight == 0) {
                emit InvalidWeight(voter, proposalId, block.timestamp, nonces[voter], weight);
                continue;
            }

            // proposals[proposalId].voters.push(voter);
            votes[proposalId][voter] = weight;
            proposals[proposalId]._yesVotesTotalWeight += weight;

            nonces[voter]++;
            emit VoteRecorded(voter, proposalId, weight, timestamp, nonce, signature);
        }

        _finalizeVoting(proposalId);
    }

    function _finalizeVoting(uint256 proposalId) internal {
        Proposal storage proposal = proposals[proposalId];
        uint256 totalSupply = token.totalSupply();
        uint256 quorum = (totalSupply * quorumFraction) / 100;
        uint256 yesVotes = proposal._yesVotesTotalWeight;

        if (yesVotes >= quorum) {
            proposal.proposalStatus = ProposalStatus.Executed;
        } else {
            proposal.proposalStatus = ProposalStatus.Cancelled;
        }

        emit ProposalFinalized(proposalId, proposal.proposalStatus, yesVotes, quorum);
    }

    function setQuorumFraction(uint256 _quorumFraction) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an operator");
        quorumFraction = _quorumFraction;
    }

    function setVotingDelay(uint256 _votingDelay) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an operator");
        votingDelay = _votingDelay;
    }

    function setVotingPeriod(uint256 _votingPeriod) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an operator");
        votingPeriod = _votingPeriod;
    }

    function setProposalThreshold(uint256 _proposalThreshold) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an operator");
        proposalThreshold = _proposalThreshold;
    }

    function cancelProposal(uint256 proposalId, string memory reason) public {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an operator");
        proposals[proposalId].proposalStatus = ProposalStatus.Cancelled;
        emit ProposalCancelled(proposalId, reason);
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

}