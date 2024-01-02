// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import "./Module.sol";
import "./MotivatorV2.sol";
import "./AddressAliasHelper.sol";
import "./Ownable.sol";

/**
 * @title Governor
 * @author Federation - https://x.com/FederationWTF
 */
abstract contract Governor is Module, Ownable, MotivatorV2 {
    /// The proposal has already ended
    error ProposalEnded();

    /// The proposal either does not exist or hasn't been synced yet
    error ProposalNotFound();

    /// The voter already voted
    error AlreadyVoted();

    /// The voter does not have any voting power
    error NoVotingPower();

    // The caller is not a delegate
    error CallerIsNotDelegate();

    /// The support type is not valid
    error InvalidSupport();

    /// The proof provided does not represent a valid voter
    error VoteInvalidProof(string);

    /// The proof provided was not a valid proposal
    error SyncProposalInvalidProof();

    /// The proposal outcome was cast too early or too late
    error CastNotInWindow();

    /// The prover is not a valid version
    error InvalidProverVersion(string);

    /// The caller account is not authorized to perform an operation
    error OwnableUnauthorizedAccount(address);

    /// The proposal has not been proven yet and the proof is missing
    error MissingProposalCreatedProof();

    /// The voter proof batch needs to be divisible by 2, [balance, delegate, balance, delegate, ...]
    error InvalidProofBatchLength();

    /// There should be one account for every balance and delegate proof pair
    error ProofBatchAndAccountMismatch();

    /**
     * @notice A vote has been cast
     * @param proposal The proposal id
     * @param support The vote support
     * @param votes The number of votes cast
     * @param reason The reason for the vote
     * @param metadata Metadata for the vote reason
    */
    event VoteCast(
        uint256 indexed proposal,
        address indexed voter,
        uint8 indexed support,
        uint256 votes,
        string reason,
        string metadata
    );

    /**
     * @notice A proposal has been synced
     * @param proposal The proposal id
     * @param endBlock When the proposal ends
    */
    event ProposalSynced(
        uint256 indexed proposal, 
        uint256 endBlock
    );

    /**
     * @notice The proposal has been settled to the relayer
     * @param proposal The proposal id
     * @param forVotes The proposal for votes
     * @param againstVotes The proposal against votes
     * @param abstainVotes The proposal abstain votes
    */
    event VotesSettled(
        uint256 indexed proposal,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 abstainVotes
    );

    /**
     * @notice The governor config has changed
     * @param config The new config
    */
    event ConfigChanged(Config config);

    /// Overrides the original implementation of onlyOwner to account for L1 -> L2 transactions
    modifier onlyMainnetOwner() {
        address owner = owner();

        if (msg.sender != owner) {
            if (AddressAliasHelper.undoL1ToL2Alias(msg.sender) != owner) {
                revert OwnableUnauthorizedAccount(msg.sender);
            }
        }

        _;
    }

    struct Config {
        /// The address of the Relic reliquary
        address reliquary;
        /// The address of the native governance token
        address nativeToken;
        /// The address of the DAO
        address externalDAO;
        /// The address of the Relic storage prover
        address storageProver;
        /// The address of the Relic log prover
        address logProver;
        /// The address of the Relic transaction prover
        address transactionProver;
        /// The address of the fact validator
        address factValidator;
        /// The address of the zkSync messenger
        address messenger;
        /// The storage slot index for token delegates
        uint256 tokenDelegateSlot;
        /// The storage slot index for token balance
        uint256 tokenBalanceSlot;
        /// The maximum prover version allowed
        uint256 maxProverVersion;
        /// The window of time in which a vote can be cast
        uint256 castWindow;
        /// The number of blocks to wait for zkSync finality
        uint256 finalityBlocks;
    }

    struct Receipt {
        /// Whether or not the account has voted
        bool hasVoted;
        /// The vote support
        uint8 support;
        /// The number of votes
        uint256 votes;
    }

    struct Proposal {
        /// The proposal id
        uint256 id;
        /// When the proposal starts
        uint256 startBlock;
        /// When the proposal ends
        uint256 endBlock;
        /// The proposal for votes
        uint256 forVotes;
        /// The proposal against votes
        uint256 againstVotes;
        /// The proposal abstain votes
        uint256 abstainVotes;
    }
    
    struct Message {
        /// The proposal id
        uint256 proposal;
        /// THe proposal for votes
        uint256 forVotes;
        /// The proposal against votes
        uint256 againstVotes;
        /// The proposal abstain votes
        uint256 abstainVotes;
    }

    /// The config for the contract
    Config public config;

    /**
     * @notice Change the contract config
     * @param _config The new contract config
     */
    function setConfig(Config calldata _config) external onlyMainnetOwner {
        config = _config;
        emit ConfigChanged(_config);
    }

    /**
     * @notice Changes the motivator config
     * @param _motivatorConfig The new config
    */
    function setMotivatorConfig(MotivatorConfig calldata _motivatorConfig) external onlyMainnetOwner  {
        _setMotivatorConfig(_motivatorConfig);
    }

    /**
     * @notice Withdraw funds stored in the contract
     * @param _amount The amount to withdraw
     * @param _to The address to withdraw to
    */
    function withdraw(uint256 _amount, address _to) external onlyMainnetOwner {
        _withdraw(_amount, _to);
    }

    /// Satisfies the Module interface
    function init(bytes calldata) external payable {}
}
