// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./UUPSUpgradeable.sol";
import "./Initializable.sol";

import "./ERC20Upgradeable.sol";

import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./EIP712DomainVoting.sol";


contract BlocksportDaoV2 is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    EIP712DomainVoting
{
    enum ProposalStatus {Inactive, Active, Executed, Cancelled}

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    ERC20Upgradeable public token;

    uint256 public tokenTotalSupply;

    string public name;
    uint256 public proposalIndex;
    uint256 public votingDelay;
    uint256 public votingPeriod;
    uint256 public proposalThreshold;
    uint256 public quorumFraction;
    string private _baseProposalURI;

    struct Proposal {
        uint256 id;
        address author;
        uint40 dateProposed;
        uint40 dateVotingEnds;
        uint256 _yesVotesTotalWeight; // total weight of yes votes (in $BSPT)
        ProposalStatus proposalStatus;
    }

    struct Vote {
        uint256 proposalId;
        uint40 timestamp;
        address voter;
        uint256 nonce;
        bytes signature;
    }

    // proposalId => Proposal
    mapping(uint256 => Proposal) private proposals;

    // proposalId => proposalURI
    mapping(uint256 => string) private _proposalURIs;

    // voter => nonce
    mapping(address => uint256) private nonces;

    // proposalId => voter => weight
    mapping(uint256 => mapping(address => uint256)) public votes;

    event ProposalCreated(uint256 indexed proposalId, address author);
    event VoteRecorded(address indexed voter, uint256 indexed proposalId, uint256 weight);
    event ProposalFinalized(uint256 indexed proposalId, ProposalStatus status, uint256 yesVotes, uint256 quorum);
    event ProposalCancelled(uint256 indexed proposalId, string reason);

    event AlreadyVoted(address indexed voter, uint256 indexed proposalId);
    event InvalidTimestamp(address indexed voter, uint256 indexed proposalId, uint256 timestamp);
    event InvalidSignature(address indexed voter, uint256 indexed proposalId, uint256 timestamp, uint256 nonce, bytes signature);
    event InvalidWeight(address indexed voter, uint256 indexed proposalId);

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
        address _operator,
        string memory baseProposalURI
    ) initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __EIP712DomainVoting_init(_name, _chainId);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);

        name = _name;

        quorumFraction = _quorumFraction;
        votingDelay = _initialVotingDelay;
        votingPeriod = _initialVotingPeriod;
        proposalThreshold = _initialProposalThreshold;

        token = ERC20Upgradeable(_token);
        tokenTotalSupply = token.totalSupply();
        _baseProposalURI = baseProposalURI;
    }

    function createProposal(string calldata _proposalURI) public {
        require(token.balanceOf(msg.sender) >= proposalThreshold, "Insufficient tokens to create proposal");

        uint256 _proposalId = proposalIndex++;
        Proposal memory newProposal = Proposal({
            id: _proposalId,
            author: msg.sender,
            dateProposed: uint40(block.timestamp),
            dateVotingEnds: uint40(block.timestamp + votingPeriod),
            _yesVotesTotalWeight: 0,
            proposalStatus: ProposalStatus.Active
        });
        proposals[_proposalId] = newProposal;
        _proposalURIs[_proposalId] = _proposalURI;

        emit ProposalCreated(_proposalId, msg.sender);
    }

    function recordVote(uint256 proposalId, Vote calldata voteRecord) internal {

        Proposal storage _proposal = proposals[proposalId];
        require(_proposal.proposalStatus == ProposalStatus.Active, "Proposal not active");

        address voter = voteRecord.voter;
        uint256 weight = token.balanceOf(voter);

        if (votes[proposalId][voter] != 0) {
            emit AlreadyVoted(voter, proposalId);
            return;
        }

        if (voteRecord.timestamp < _proposal.dateProposed || voteRecord.timestamp > _proposal.dateVotingEnds) {
            emit InvalidTimestamp(voter, proposalId, voteRecord.timestamp);
            return;
        }

        if (!verify(voter, proposalId, voteRecord.timestamp, voteRecord.nonce, voteRecord.signature)) {
            emit InvalidSignature(voter, proposalId, voteRecord.timestamp, voteRecord.nonce, voteRecord.signature);
            return;
        }

        if (weight == 0) {
            emit InvalidWeight(voter, proposalId);
            return;
        }

        votes[proposalId][voter] = weight;
        _proposal._yesVotesTotalWeight += weight;

        nonces[voter] = voteRecord.nonce;
        emit VoteRecorded(voter, proposalId, weight);
    }

    function recordVotes(uint256 proposalId, Vote[] calldata votesArray) public onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < votesArray.length; i++) {
            recordVote(proposalId, votesArray[i]);
        }
    }

    function finalizeVoting(uint256 proposalId) public onlyRole(OPERATOR_ROLE) {
        Proposal storage _proposal = proposals[proposalId];

        require(_proposal.proposalStatus == ProposalStatus.Active, "finalizeVoting: Proposal not active");

        uint256 quorum = (tokenTotalSupply * quorumFraction) / 100;
        uint256 yesVotes = _proposal._yesVotesTotalWeight;

        if (yesVotes >= quorum) {
            _proposal.proposalStatus = ProposalStatus.Executed;
        } else if (uint40(block.timestamp) > _proposal.dateVotingEnds) {
            _proposal.proposalStatus = ProposalStatus.Cancelled;
        } else {
            return;
        }

        emit ProposalFinalized(proposalId, _proposal.proposalStatus, yesVotes, quorum);
    }

    function recordVotesAndCloseProposal(uint256 proposalId, Vote[] calldata votesArray) public onlyRole(OPERATOR_ROLE) {
        recordVotes(proposalId, votesArray);
        finalizeVoting(proposalId);
    }

    function setQuorumFraction(uint256 _quorumFraction) public onlyRole(DEFAULT_ADMIN_ROLE) {
        quorumFraction = _quorumFraction;
    }

    function setVotingDelay(uint256 _votingDelay) public onlyRole(DEFAULT_ADMIN_ROLE) {
        votingDelay = _votingDelay;
    }

    function setVotingPeriod(uint256 _votingPeriod) public onlyRole(DEFAULT_ADMIN_ROLE) {
        votingPeriod = _votingPeriod;
    }

    function setProposalThreshold(uint256 _proposalThreshold) public onlyRole(DEFAULT_ADMIN_ROLE) {
        proposalThreshold = _proposalThreshold;
    }

    function cancelProposal(uint256 proposalId, string calldata reason) public onlyRole(DEFAULT_ADMIN_ROLE) {
        proposals[proposalId].proposalStatus = ProposalStatus.Cancelled;
        emit ProposalCancelled(proposalId, reason);
    }

    function setBaseProposaURI(string calldata baseProposalURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseProposalURI = baseProposalURI;
    }

    function getBaseProposaURI() public view returns (string memory) {
        return _baseProposalURI;
    }

    function proposal(uint256 proposalId) public view returns (Proposal memory) {
        return proposals[proposalId];
    }

    function proposalURI(uint256 id) public view returns (string memory) {
        return string(abi.encodePacked(_baseProposalURI, _proposalURIs[id]));
    }

    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

}