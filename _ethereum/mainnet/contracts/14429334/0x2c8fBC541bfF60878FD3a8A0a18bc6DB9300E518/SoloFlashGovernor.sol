// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./FlashGovernor.sol";

contract SoloFlashGovernor is FlashGovernor {
    /**
     * @notice Upgradeable contract constructor
     * @dev Can be used instead of base governor initializer with many arguments
     */
    function soloInitialize() external initializer {
        initialize(address(0), address(0), 0, 0);
    }

    /**
     * @notice Function is called by owner to vote for some proposal
     * @param proposalId ID of the proposal to vote for
     * @param support Support of the proposal (true to support, false to reject)
     */
    function vote(uint32 proposalId, bool support) external override onlyOwner {
        if (support) {
            proposals[proposalId].forVotes++;
        } else {
            proposals[proposalId].againstVotes++;
        }
        emit VoteCast(proposalId, msg.sender, support);
    }

    /**
     * @notice Function to get state of some proposal
     * @param proposalId ID of the proposal
     * @return Current proposal's state (as ProposalState enum)
     */
    function state(uint32 proposalId)
        public
        view
        override
        returns (ProposalState)
    {
        if (
            proposals[proposalId].forVotes == proposals[proposalId].againstVotes
        ) {
            return ProposalState.Active;
        } else if (
            proposals[proposalId].forVotes < proposals[proposalId].againstVotes
        ) {
            return ProposalState.Defeated;
        } else if (!proposals[proposalId].executed) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Executed;
        }
    }
}
