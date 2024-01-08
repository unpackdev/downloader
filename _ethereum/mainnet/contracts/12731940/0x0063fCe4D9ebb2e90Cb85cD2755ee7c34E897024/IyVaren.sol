pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./IERC20.sol";

interface IyVaren {
    // Event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address indexed proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    // Event emitted when a vote has been cast on a proposal
    event VoteCast(
        address indexed voter,
        uint256 proposalId,
        bool support,
        uint256 votes
    );
    // Event emitted when a proposal has been executed
    // Success=true if all actions were executed successfully
    // Success=false if not all actions were executed successfully (executeProposal will not revert)
    event ProposalExecuted(uint256 id, bool success);

    // Maximum number of actions that can be included in a proposal
    function MAX_OPERATIONS() external pure returns (uint256);

    // https://etherscan.io/token/0x72377f31e30a405282b522d588aebbea202b4f23
    function VAREN() external pure returns (IERC20);

    struct Proposal {
        // Address that created the proposal
        address proposer;
        // Number of votes in support of the proposal by a particular address
        mapping(address => uint256) forVotes;
        // Number of votes against the proposal by a particular address
        mapping(address => uint256) againstVotes;
        // Total number of votes in support of the proposal
        uint256 totalForVotes;
        // Total number of votes against the proposal
        uint256 totalAgainstVotes;
        // Number of votes in support of a proposal required for a quorum to be reached and for a vote to succeed
        uint256 quorumVotes;
        // Block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        // Ordered list of target addresses for calls to be made on
        address[] targets;
        // Ordered list of ETH values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        // Ordered list of function signatures to be called
        string[] signatures;
        // Ordered list of calldata to be passed to each call
        bytes[] calldatas;
        // Flag marking whether the proposal has been executed
        bool executed;
    }

    // Number of blocks after staking when the early withdrawal fee stops applying
    function blocksForNoWithdrawalFee() external view returns (uint256);

    // Fee for withdrawing before blocksForNoWithdrawalFee have passed, divide by 1,000,000 to get decimal form
    function earlyWithdrawalFeePercent() external view returns (uint256);

    function earlyWithdrawalFeeExpiry(address) external view returns (uint256);

    function treasury() external view returns (address);

    // Share of early withdrawal fee that goes to treasury (remainder goes to governance),
    // divide by 1,000,000 to get decimal form
    function treasuryEarlyWithdrawalFeeShare() external view returns (uint256);

    // Amount of an address's stake that is locked for voting
    function voteLockAmount(address) external view returns (uint256);

    // Block number when an address's vote-locked amount will be unlock
    function voteLockExpiry(address) external view returns (uint256);

    function hasActiveProposal(address) external view returns (bool);

    function proposals(uint256 id)
        external
        view
        returns (
            address proposer,
            uint256 totalForVotes,
            uint256 totalAgainstVotes,
            uint256 quorumVotes,
            uint256 endBlock,
            bool executed
        );

    // Number of proposals created, used as the id for the next proposal
    function proposalCount() external view returns (uint256);

    // Length of voting period in blocks
    function votingPeriodBlocks() external view returns (uint256);

    function minVarenForProposal() external view returns (uint256);

    // Need to divide by 1,000,000
    function quorumPercent() external view returns (uint256);

    // Need to divide by 1,000,000
    function voteThresholdPercent() external view returns (uint256);

    // Number of blocks after voting ends where proposals are allowed to be executed
    function executionPeriodBlocks() external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 shares) external;

    function getPricePerFullShare() external view returns (uint256);

    function getStakeVarenValue(address staker) external view returns (uint256);

    function propose(
        address[] calldata targets,
        uint256[] calldata values,
        string[] calldata signatures,
        bytes[] calldata calldatas,
        string calldata description
    ) external returns (uint256 id);

    function vote(
        uint256 id,
        bool support,
        uint256 voteAmount
    ) external;

    function executeProposal(uint256 id) external payable;

    function getVotes(uint256 proposalId, address voter)
        external
        view
        returns (bool support, uint256 voteAmount);

    function getProposalCalls(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        );

    function setTreasury(address) external;

    function setTreasuryEarlyWithdrawalFeeShare(uint256) external;

    function setBlocksForNoWithdrawalFee(uint256) external;

    function setEarlyWithdrawalFeePercent(uint256) external;

    function setVotingPeriodBlocks(uint256) external;

    function setMinVarenForProposal(uint256) external;

    function setQuorumPercent(uint256) external;

    function setVoteThresholdPercent(uint256) external;

    function setExecutionPeriodBlocks(uint256) external;
}
