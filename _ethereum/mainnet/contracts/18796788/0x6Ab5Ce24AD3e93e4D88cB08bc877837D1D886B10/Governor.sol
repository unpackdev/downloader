// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./SafeERC20Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./ExceptionsLibrary.sol";
import "./IService.sol";
import "./IPool.sol";
import "./IGovernor.sol";
import "./IRegistry.sol";

/**
* @title Governor Contract
* @notice This contract extends the functionality of the pool contract. If the pool has been granted DAO status, Governance tokens can be used as votes during the voting process for proposals created for the pool. With this architecture, the pool can invoke methods on behalf of itself provided by this module to execute transactions prescribed by proposals.
* @dev This module provides additional methods for creating proposals, participating and observing the voting process, as well as safely and securely counting votes and executing decisions that have undergone voting.
*/
abstract contract Governor {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;

    // CONSTANTS

    /** 
    * @notice Denominator for shares (such as thresholds)
    * @dev The constant Service.sol:DENOM is used to work with percentage values of QuorumThreshold and DecisionThreshold thresholds, as well as for calculating the ProtocolTokenFee. In this version, it is equal to 1,000,000, for clarity stored as 100 * 10 ^ 4.
    10^4 corresponds to one percent, and 100 * 10^4 corresponds to one hundred percent.
    The value of 12.3456% will be written as 123,456, and 78.9% as 789,000.
    This notation allows specifying ratios with an accuracy of up to four decimal places in percentage notation (six decimal places in decimal notation).
    When working with the CompanyDAO frontend, the application scripts automatically convert the familiar percentage notation into the required format. When using the contracts independently, this feature of value notation should be taken into account.
    */
    uint256 private constant DENOM = 100 * 10**4;

    // STORAGE

    /**
    * @notice Proposal state codes.
    * @dev Additional data type used only in this extension.
    "0" / "None" - the proposal does not exist
    "1" / "Active" - the proposal has been launched and is being voted on
    "2" / "Failed" - the voting is complete, and the result is negative
    "3" / "Delayed" - the voting is complete, the result is positive, and the system is waiting for a security timeout to complete, during which the service administrator can cancel the execution
    "4" / "AwaitingExecution" - the voting is complete, the result is positive, and the executeProposal method must be called by an account with the appropriate role
    "5" / "Executed" - the voting is complete, the result is positive, and the transaction provided by the proposal has been executed
    "6" / "Cancelled" - the voting is complete with a positive result, or it has been prematurely cancelled, and the proposal has been cancelled by the administrator
    */
    enum ProposalState {
        None,
        Active,
        Failed,
        Delayed,
        AwaitingExecution,
        Executed,
        Cancelled
    }

    /**
    * @notice This structure is used for a complete description of the proposal state.
     * @dev Each proposal has a field represented by this structure, which stores information on the progress of the voting. Note that 
    - endBlock may differ from the calculated value (currentBlock + votingDuration), since at the time of creating the proposal, it will be increased by votingStartDelay, and if the required number and ratio of votes is reached to recognize this vote as completed early with some result, this field is overwritten
    - startBlock may differ from the calculated value (currentBlock), since at the time of creating the proposal, it will be increased by votingStartDelay  
     * @param startBlock The true block start of the voting
     * @param endBlock The true block end of the voting
     * @param availableVotes The total number of available votes calculated at the time of creating the proposal
     * @param forVotes The number of votes "for" cast
     * @param againstVotes The number of votes "against" cast
     * @param executionState The digital code of the proposal state
     */
    struct ProposalVotingData {
        uint256 startBlock;
        uint256 endBlock;
        uint256 availableVotes;
        uint256 forVotes;
        uint256 againstVotes;
        ProposalState executionState;
    }

    /**
    * @notice The structure that includes all the nested structures describing the subject, state, and metadata of the voting.
     * @dev This is the format in which information about each individual proposal is stored in the contract. Since the Pool contract inherits from Governor, all proposals for an individual pool are stored separately in the public mapping(uint256 => Proposal) proposals, where the mapping key is the internal proposal identifier (which is subsequently stored in the array of records of the Registry contract).
     * @param core Data on the voting settings that were applied to this proposal
     * @param vote Cumulative information on the progress of voting on this proposal
     * @param meta Metadata on the subject of the vote
     */
    struct Proposal {
        IGovernor.ProposalCoreData core;
        ProposalVotingData vote;
        IGovernor.ProposalMetaData meta;
    }

    //// @notice Mapping that contains all the proposals launched for this pool.
    /// @dev In this mapping, the local identifier (specific to the pool's scope) is used as the key. The proposal is also registered in the Registry contract, where it is assigned a global number.
    mapping(uint256 => Proposal) public proposals;

    /// @notice These numerical codes determine which side an account took during the voting process.
    /// @dev "0" - not voted, "1" - voted "against", "2" - voted "for".
    enum Ballot {
        None,
        Against,
        For
    }

    /// @notice Mapping with the voting history.
    /// @dev The account address is used as the first key, and the proposal number is used as the second key. The stored value for these keys is described by the Ballot type.
    mapping(address => mapping(uint256 => Ballot)) public ballots;

    /// @dev Last proposal ID
    uint256 public lastProposalId;

    // EVENTS

    /**
     * @dev Event emitted on proposal creation
     * @param proposalId Proposal ID
     * @param core Proposal core data
     * @param meta Proposal meta data
     */
    event ProposalCreated(
        uint256 proposalId,
        IGovernor.ProposalCoreData core,
        IGovernor.ProposalMetaData meta
    );

    /**
     * @dev Event emitted on proposal vote cast
     * @param voter Voter address
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param ballot Ballot (against or for)
     */
    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        Ballot ballot
    );

    /**
     * @dev Event emitted on proposal execution
     * @param proposalId Proposal ID
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Event emitted on proposal cancellation
     * @param proposalId Proposal ID
     */
    event ProposalCancelled(uint256 proposalId);

    // PUBLIC VIEW FUNCTIONS

    /**
    * @notice This method returns the state of the specified proposal.
     * @dev Among the Governance Settings, there is a parameter called votingDuration, which contains the number of blocks for the duration of the vote, and a parameter called votingStartDelay, which contains the number of blocks for the delay of the vote's start relative to the block of the proposal's creation.
    The start and end blocks of the vote are placed in the Pool:proposals[proposalId] entry as vote.startBlock and vote.endBlock.
        vote.startBlock = block.number + votingStartDelay
        vote.endBlock = block.number + votingStartDelay + votingDuration
    The proposal status can be obtained from the Pool:proposalState(proposalId) method. It is formed by comparing the current block with the end block, as well as from proposals[proposalId].vote.executionState, which can store irreversible state flags "Canceled" or "Executed". This value is a numerical code for one of the proposal states, with all possible state types listed in Governor.sol:ProposalState.
    Before the endBlock occurs, the proposal has an Active status, but the ability to vote (using the castVote method in the Pool contract) only appears from the startBlock. This status means that the QuorumThreshold and/or DecisionThreshold have not yet been reached, and there is still a sufficient number of unused votes, the application of which can lead to either of the two results.
    When the endBlock occurs, the proposal is no longer Active. New votes are not accepted, and the state changes to:
    - Failed if the QuorumThreshold and/or DecisionThreshold were not met by the voters
    - Delayed if both thresholds were met.
    The Failed state is irreversible and means that the decision "for" was not made, i.e., the transactions prescribed by the proposal cannot be executed.
    The Delayed state means that the necessary number of votes has been cast "for" the proposal, but the transactions prescribed by the proposal can be executed only after proposals[proposalId].core.executionDelay blocks have passed.
    The AwaitingExecution state means that the necessary number of votes has been cast "for" the proposal, the delay has ended, and the transactions prescribed by the proposal can be executed right now.
    The Canceled state means that the address assigned the ADMIN role in the Service contract used the cancelProposal method of the Service contract and canceled the execution of the proposal. This method could work only if the proposal had an Active, Delayed, or AwaitingExecution state at the time of cancellation. This state is irreversible; the proposal permanently loses the ability to accept votes, and its transactions will not be executed.
    The Executed state means that the address assigned the SERVICE_MANAGER role in the Service contract, or the address assigned the Executor role in the Pool contract, or any address if no address was assigned the Executor role in the pool, used the executeProposal method in the Pool contract. This state means that all transactions prescribed by the proposal have been successfully executed.
    * @param proposalId Идентификатор Proposal.
    * @return The state code using the ProposalState type.
     */
    function proposalState(uint256 proposalId)
        public
        view
        returns (ProposalState)
    {
        Proposal memory proposal = proposals[proposalId];

        if (proposal.vote.startBlock == 0) {
            return ProposalState.None;
        }

        // If proposal executed, cancelled or simply not started, return immediately
        if (
            proposal.vote.executionState == ProposalState.Executed ||
            proposal.vote.executionState == ProposalState.Cancelled
        ) {
            return proposal.vote.executionState;
        }
        if (
            proposal.vote.startBlock > 0 &&
            block.number < proposal.vote.startBlock
        ) {
            return ProposalState.Active;
        }
        uint256 availableVotesForStartBlock = _getBlockTotalVotes(
            proposal.vote.startBlock - 1
        );
        uint256 castVotes = proposal.vote.forVotes + proposal.vote.againstVotes;

        if (block.number >= proposal.vote.endBlock) {
            // Proposal fails if quorum threshold is not reached
            if (
                !shareReached(
                    castVotes,
                    availableVotesForStartBlock,
                    proposal.core.quorumThreshold
                )
            ) {
                return ProposalState.Failed;
            }
            // Proposal fails if decision threshold is not reched
            if (
                !shareReached(
                    proposal.vote.forVotes,
                    castVotes,
                    proposal.core.decisionThreshold
                )
            ) {
                return ProposalState.Failed;
            }
            // Otherwise succeeds, check for delay
            if (
                block.number >=
                proposal.vote.endBlock + proposal.core.executionDelay
            ) {
                return ProposalState.AwaitingExecution;
            } else {
                return ProposalState.Delayed;
            }
        } else {
            return ProposalState.Active;
        }
    }

    /**
    * @dev This method is used to work with the voting history and returns the vote code according to the Ballot type made by the specified account in the specified proposal. Additionally, using the pastVotes snapshots, it provides information about the number of votes this account had during the specified voting.
    * @param account Account address.
    * @param proposalId Proposal identifier.
    * @return ballot Vote type.
    * @return votes Number of votes cast.
    */
    function getBallot(address account, uint256 proposalId)
        public
        view
        returns (Ballot ballot, uint256 votes)
    {
        if (proposals[proposalId].vote.startBlock - 1 < block.number)
            return (
                ballots[account][proposalId],
                _getPastVotes(
                    account,
                    proposals[proposalId].vote.startBlock - 1
                )
            );
        else
            return (
                ballots[account][proposalId],
                _getPastVotes(account, block.number - 1)
            );
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Creating a proposal and assigning it a unique identifier to store in the list of proposals in the Governor contract.
     * @param core Proposal core data
     * @param meta Proposal meta data
     * @param votingDuration Voting duration in blocks
     */
    function _propose(
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta,
        uint256 votingDuration,
        uint256 votingStartDelay
    ) internal returns (uint256 proposalId) {
        // Increment ID counter
        proposalId = ++lastProposalId;

        // Create new proposal
        proposals[proposalId] = Proposal({
            core: core,
            vote: ProposalVotingData({
                startBlock: block.number + votingStartDelay,
                endBlock: block.number + votingStartDelay + votingDuration,
                availableVotes: 0,
                forVotes: 0,
                againstVotes: 0,
                executionState: ProposalState.None
            }),
            meta: meta
        });

        // Call creation hook
        _afterProposalCreated(proposalId);

        // Emit event
        emit ProposalCreated(proposalId, core, meta);
    }

    /**
    * @notice Implementation of the voting method for the pool contract.
    * @dev This method includes a check that the proposal is still in the "Active" state and eligible for the user to cast their vote. Additionally, each invocation of this method results in an additional check for the conditions to prematurely end the voting.
    * @param account Voting account
    * @param proposalId Proposal ID.
    * @param support "True" for a vote "in favor/for," "False" otherwise.
    */
    function _castVote(address account, uint256 proposalId, bool support) internal {
        // Check that voting exists, is started and not finished
        require(
            proposals[proposalId].vote.startBlock != 0,
            ExceptionsLibrary.NOT_LAUNCHED
        );
        require(
            proposals[proposalId].vote.startBlock <= block.number,
            ExceptionsLibrary.NOT_LAUNCHED
        );
        require(
            proposals[proposalId].vote.endBlock > block.number,
            ExceptionsLibrary.VOTING_FINISHED
        );
        require(
            ballots[account][proposalId] == Ballot.None,
            ExceptionsLibrary.ALREADY_VOTED
        );

        // Get number of votes
        uint256 votes = _getPastVotes(
            account,
            proposals[proposalId].vote.startBlock - 1
        );

        require(votes > 0, ExceptionsLibrary.ZERO_VOTES);

        // Account votes
        if (support) {
            proposals[proposalId].vote.forVotes += votes;
            ballots[account][proposalId] = Ballot.For;
        } else {
            proposals[proposalId].vote.againstVotes += votes;
            ballots[account][proposalId] = Ballot.Against;
        }

        // Check for voting early end
        _checkProposalVotingEarlyEnd(proposalId);

        // Emit event
        // emit VoteCast(
        //     account,
        //     proposalId,
        //     votes,
        //     support ? Ballot.For : Ballot.Against
        // );
    }

    /**
     * @dev Performance of the proposal with checking its status. Only the Awaiting Execution of the proposals can be executed.
     * @param proposalId Proposal ID
     * @param service Service address
     */
    function _executeProposal(uint256 proposalId, IService service) internal {
        // Check state
        require(
            proposalState(proposalId) == ProposalState.AwaitingExecution,
            ExceptionsLibrary.WRONG_STATE
        );

        // Mark as executed
        proposals[proposalId].vote.executionState = ProposalState.Executed;

        // Execute actions
        Proposal memory proposal = proposals[proposalId];
        for (uint256 i = 0; i < proposal.core.targets.length; i++) {
            if (proposal.core.callDatas[i].length == 0) {
                payable(proposal.core.targets[i]).sendValue(
                    proposal.core.values[i]
                );
            } else {
                proposal.core.targets[i].functionCallWithValue(
                    proposal.core.callDatas[i],
                    proposal.core.values[i]
                );
            }
        }

        // Add event to service
        service.addEvent(
            proposal.meta.proposalType,
            proposalId,
            proposal.meta.metaHash
        );

        // Emit contract event
        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev The substitution of proposals, both active and those that have a positive voting result, but have not yet been executed.
     * @param proposalId Proposal ID
     */
    // function _cancelProposal(uint256 proposalId) internal {
    //     // Check proposal state
    //     ProposalState state = proposalState(proposalId);
    //     require(
    //         state == ProposalState.Active ||
    //             state == ProposalState.Delayed ||
    //             state == ProposalState.AwaitingExecution,
    //         ExceptionsLibrary.WRONG_STATE
    //     );

    //     // Mark proposal as cancelled
    //     proposals[proposalId].vote.executionState = ProposalState.Cancelled;

    //     // Emit event
    //     emit ProposalCancelled(proposalId);
    // }

    /**
     * @notice The method checks whether it is possible to end the voting early with the result fixed. If a quorum was reached and so many votes were cast in favor that even if all other available votes were cast against, or if so many votes were cast against that it could not affect the result of the vote, this function will change set the end block of the proposal to the current block
     * @dev During the voting process, a situation may arise when such a number of votes have been cast "for" or "against" a proposal that no matter how the remaining votes are distributed, the outcome of the proposal will not change.
    This can occur in the following situations:
    - The sum of "for" votes and unused votes does not exceed the DecisionThreshold of the total number of votes allowed in the voting process (occurs when there are so many "against" votes that even using the remaining votes in favor of the proposal will not allow overcoming the DecisionThreshold).
    - The number of "for" votes is no less than the DecisionThreshold of the total number of votes allowed in the voting process (occurs when there are so many "for" votes that even if all the remaining unused votes are cast "against", the proposal will still be considered accepted).
    Both of these conditions trigger ONLY when the QuorumThreshold is reached simultaneously.
    In such cases, further voting and waiting become pointless and meaningless. No subsequent vote can influence the outcome of the voting to change.
    Therefore, an additional check for triggering the conditions described above has been added to the Pool:castVote method. If the vote can be safely terminated early, the proposals[proposalId].vote.endBlock is changed to the current one during the method's execution.
    This means that the state of the proposal ceases to be Active and should change to Failed or Delayed.
     * @param proposalId Proposal ID
     */
    function _checkProposalVotingEarlyEnd(uint256 proposalId) internal {
        // Get values
        Proposal memory proposal = proposals[proposalId];
        uint256 availableVotesForStartBlock = _getBlockTotalVotes(
            proposal.vote.startBlock - 1
        );
        uint256 castVotes = proposal.vote.forVotes + proposal.vote.againstVotes;
        uint256 extraVotes = availableVotesForStartBlock - castVotes;

        // Check if quorum is reached
        if (
            !shareReached(
                castVotes,
                availableVotesForStartBlock,
                proposal.core.quorumThreshold
            )
        ) {
            return;
        }

        // Check for early guaranteed result
        if (
            !shareOvercome(
                proposal.vote.forVotes + extraVotes,
                availableVotesForStartBlock,
                proposal.core.decisionThreshold
            ) ||
            shareReached(
                proposal.vote.forVotes,
                availableVotesForStartBlock,
                proposal.core.decisionThreshold
            )
        ) {
            // Mark voting as finished
            proposals[proposalId].vote.endBlock = block.number;
        }
    }

    // INTERNAL PURE FUNCTIONS

    /**
     * @dev Checks if `amount` divided by `total` exceeds `share`
     * @param amount Amount numerator
     * @param total Amount denominator
     * @param share Share numerator
     */
    function shareReached(
        uint256 amount,
        uint256 total,
        uint256 share
    ) internal pure returns (bool) {
        return amount * DENOM >= share * total;
    }

    /**
     * @dev Checks if `amount` divided by `total` overcomes `share`
     * @param amount Amount numerator
     * @param total Amount denominator
     * @param share Share numerator
     */
    function shareOvercome(
        uint256 amount,
        uint256 total,
        uint256 share
    ) internal pure returns (bool) {
        return amount * DENOM > share * total;
    }

    // ABSTRACT FUNCTIONS

    /**
     * @dev Hook called after a proposal is created
     * @param proposalId Proposal ID
     */
    function _afterProposalCreated(uint256 proposalId) internal virtual;

    /**
     * @dev Function that returns the total amount of votes in the pool in block
     * @param blocknumber block number
     * @return Total amount of votes
     */
    function _getBlockTotalVotes(uint256 blocknumber)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev Function that returns the amount of votes for a client adrress at any given block
     * @param account Account's address
     * @param blockNumber Block number
     * @return Account's votes at given block
     */
    function _getPastVotes(address account, uint256 blockNumber)
        internal
        view
        virtual
        returns (uint256);

    /**
     * @dev Function that set last ProposalId for a client address
     * @param proposer Proposer's address
     * @param proposalId Proposal id
     */
    function _setLastProposalIdForAddress(address proposer, uint256 proposalId)
        internal
        virtual;
}
