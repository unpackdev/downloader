// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./OwnableUpgradeable.sol";
import "./IERC721Upgradeable.sol";
import "./IAddressContract.sol";
import "./IBARAC.sol";

abstract contract DaoEvents {
    event NewProposal(uint256 indexed proposalId);

    event Vote(uint256 indexed proposalId, address indexed voter, bool voteFor);

    event ProposalExecuted(uint256 indexed proposalId);
    event ProposalCancelled(uint256 indexed proposalId);
    event Refund(uint256 indexed proposalId, uint amount);
    event ProposalSettled(uint256 indexed proposalId, uint refundAmound);

    event JudgmentProposed(
        uint256 indexed callerNftId,
        uint256 indexed deityNftId,
        uint256 indexed proposalId
    );
    event explainJudgement(uint indexed proposalId);
    event JudgmentVoted(
        uint256 indexed proposalId,
        address indexed voter,
        bool favourJudment,
        uint votes
    );
    event JudgmentProcessed(uint indexed proposalId);

    event UnlockBlacklistDeity(uint indexed deityId, address indexed caller);

    event AdminChanged(address oldAdmin, address newAdmin);
}

abstract contract DaoStructs {
    struct Proposal {
        uint256 id;
        uint256 deityId;
        address payable recipient;
        uint256 value;
        uint256 refundTime;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 expectedsettlementTime;
        bool executed;
        bool cancelled;
        mapping(address => Receipt) receipts;
        ProposalDetails proposalDetails;
        RefundDetials refundDetails;
    }

    struct ProposalDetails {
        string title;
        string description;
        string socialLink;
        string docLink;
    }

    struct RefundDetials {
        uint amount;
        uint lastrefundTime;
        bool settled;
    }

    struct Receipt {
        bool hasVoted;
        bool support;
        uint256 votes;
    }

    enum ProposalState {
        Canceled,
        Pending,
        Active,
        Executed,
        Expired
    }

    struct Judgement {
        uint author; // who proposed this judgement
        uint proposalId;
        uint256 value; // fraud amount
        uint256 votesForJudgement; // counter track which support this judgement
        uint256 votesAgainstJudgement; // counter track which are against this judgement
        uint256 startTimestamp; // timestamp for when the voting will live on this judgement
        uint256 endTimestamp; // timestamp for when the voting will end on this judgement
        bool isDeityPunished; // is deity convicted
        bool isJudgementProcessed; // whether the judgement is processed or not
        bool isSuspected; // whether the deity is suspected of proposal malpractice
        // mapping(address => bool) judgementVoters; // keep track of which deity vote on this judgement
        mapping(address => Receipt) receipts; // keep track of which deity vote on this judgement
        JudgementDetails judgementDetails;
    }

    struct JudgementDetails {
        string allegation;
        string allegationDocLink;
        string explanation;       
        string explanationLink;
    }
}

/**
 * @title Storage for Dao
 * @notice For future upgrades, do not change DaoStorageV1. Create a new
 * contract which implements DaoStorageV1 and following the naming convention
 * DaoStorageVX.
 */
contract DaoStorageV1 is DaoStructs {
    IBARAC public barac;
    IERC721Upgradeable public nft;
    address public admin;
    address public treasury;
    uint256 public proposalCount;
    uint256 public minVotingTime;
    uint256 public maxVotingTime;
    uint256 public minProposalThreshold;
    uint256 public maxProposalThreshold;
    uint256 public maxRefundTime; 
    uint256 public unlockTime;
    uint public maxLengthTitle;
    uint public maxLengthLink;
    uint public maxLengthDesc;

    string public name;
    bytes32 public DOMAIN_TYPEHASH;
    bytes32 public VOTE_PROPOSAL_TYPEHASH;
    bytes32 public VOTE_JUDGEMENT_TYPEHASH;
}