// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "EnumerableSet.sol";
import "Strings.sol";
import "Pausable.sol";

import "IGnosisSafe.sol";
import "IProposalRegistry.sol";

/*
 * @title   VoteProcessorModule
 * @author  BadgerDAO @ petrovska
 * @notice  Allows whitelisted proposers to vote on a proposal 
 * and validators to approve it, then the tx can get exec signing the vote on-chain
 directly thru the safe, where this module had being enabled.
 Hashing vote on-chain methods were taken from Aura finance repository @contracts/mocks/MockVoteStorage.sol
 */
contract VoteProcessorModule is Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* ========== STRUCT ========== */
    struct Vote {
        uint256 timestamp;
        uint256 choice;
        string version;
        string space;
        string voteType;
        bool approved;
    }

    /* ========== ADDRESS CONSTANT, VERSION & ONCHAIN NAMING ========== */
    string public constant NAME = "Vote Processor Module";
    string public constant VERSION = "0.1.0";
    // https://etherscan.io/address/0xA65387F16B013cf2Af4605Ad8aA5ec25a2cbA3a2#code#F17#L20
    address public constant signMessageLib =
        0xA65387F16B013cf2Af4605Ad8aA5ec25a2cbA3a2;

    IProposalRegistry public proposalRegistry;

    /* ========== STATE VARIABLES ========== */
    address public governance;

    mapping(string => Vote) public proposals;

    EnumerableSet.AddressSet internal _proposers;
    EnumerableSet.AddressSet internal _validators;

    /* ========== EVENT ========== */
    event VoteApproved(address approver, string proposal);

    /// @param _governance Governance allowed to add/remove proposers & validators
    constructor(address _governance, address _proposalRegistry) {
        governance = _governance;
        proposalRegistry = IProposalRegistry(_proposalRegistry);
    }

    /***************************************
                    MODIFIERS
    ****************************************/
    modifier onlyVoteProposers() {
        require(_proposers.contains(msg.sender), "not-proposer!");
        _;
    }

    modifier onlyVoteValidators() {
        require(_validators.contains(msg.sender), "not-validator!");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "not-governance!");
        _;
    }

    /***************************************
               ADMIN - GOVERNANCE
    ****************************************/

    function addProposer(address _proposer) external onlyGovernance {
        require(_proposer != address(0), "zero-address!");
        _proposers.add(_proposer);
    }

    function removeProposer(address _proposer) external onlyGovernance {
        require(_proposer != address(0), "zero-address!");
        _proposers.remove(_proposer);
    }

    function addValidator(address _validator) external onlyGovernance {
        require(_validator != address(0), "zero-address!");
        _validators.add(_validator);
    }

    function removeValidator(address _validator) external onlyGovernance {
        require(_validator != address(0), "zero-address!");
        _validators.remove(_validator);
    }

    function pause() external onlyGovernance {
        _pause();
    }

    function unpause() external onlyGovernance {
        _unpause();
    }

    /***************************************
       VOTE PROPOSAL, VALIDATION & EXEC
    ****************************************/

    /// @dev Allows to WL addresses propose a vote
    /// @param choice Choices selected
    /// @param timestamp Time when the voting proposal was generated
    /// @param version Snapshot version
    /// @param proposal Proposal hash
    /// @param space Space where voting occurs
    /// @param voteType Type of vote (single-choice...etc)
    function setProposalVote(
        uint256 choice,
        uint256 timestamp,
        string memory version,
        string memory proposal,
        string memory space,
        string memory voteType
    ) external onlyVoteProposers {
        bytes32 proposalHash = keccak256(abi.encodePacked(proposal));
        IProposalRegistry.Proposal memory proposalInfo = proposalRegistry
            .proposalInfo(proposalHash);

        require(proposalInfo.deadline > block.timestamp, "deadline!");

        if (IProposalRegistry.VotingType.Single == proposalInfo._type) {
            require(proposalInfo.maxIndex >= choice, "invalid choice");
        } else {
            // here if passed a stringiy json, we will need to loop somehow to check
            // that non of the choices are above `maxIndex`
        }

        Vote memory vote = Vote(
            timestamp,
            choice,
            version,
            space,
            voteType,
            false
        );
        proposals[proposal] = vote;
    }

    /// @dev Allows to WL addresses to verify a vote to be exec
    /// @param proposal Proposal being approved
    function verifyVote(string memory proposal) external onlyVoteValidators {
        Vote storage vote = proposals[proposal];
        vote.approved = true;
        emit VoteApproved(msg.sender, proposal);
    }

    /// @dev Triggers tx on-chain to sign a specific proposal. It will not be permissionless as needs to notify relayers
    /// @param safe Safe from where this tx will be exec and this module is enabled
    /// @param proposal Proposal being signed on the vote preference
    function sign(IGnosisSafe safe, string memory proposal)
        external
        whenNotPaused
    {
        require(proposals[proposal].approved, "not-approved!");

        bytes memory data = abi.encodeWithSignature(
            "signMessage(bytes32)",
            hash(proposal)
        );

        require(
            safe.execTransactionFromModule(
                signMessageLib,
                0,
                data,
                IGnosisSafe.Operation.DelegateCall
            ),
            "sign-error!"
        );
    }

    /***************************************
       HASH GENERATION ON-CHAIN FOR SIGNING
    ****************************************/

    function hash(string memory proposal) public view returns (bytes32) {
        Vote memory vote = proposals[proposal];

        return
            hashStr(
                string(
                    abi.encodePacked(
                        "{",
                        '"version":"',
                        vote.version,
                        '",',
                        '"timestamp":"',
                        Strings.toString(vote.timestamp),
                        '",',
                        '"space":"',
                        vote.space,
                        '",',
                        '"type":"',
                        vote.voteType,
                        '",',
                        payloadStr(proposal, vote.choice),
                        "}"
                    )
                )
            );
    }

    function payloadStr(string memory proposal, uint256 choice)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '"payload":',
                    "{",
                    '"proposal":',
                    '"',
                    proposal,
                    '",',
                    '"choice":',
                    Strings.toString(choice),
                    ","
                    '"metadata":',
                    '"{}"',
                    "}"
                )
            );
    }

    function hashStr(string memory str) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(bytes(str).length),
                    str
                )
            );
    }
}