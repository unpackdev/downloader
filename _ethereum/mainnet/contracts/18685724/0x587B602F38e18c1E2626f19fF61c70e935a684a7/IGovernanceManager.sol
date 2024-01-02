// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "DataTypes.sol";

interface IGovernanceManager {
    function createProposal(
        DataTypes.ProposalAction[] calldata actions
    ) external;

    function vote(uint16 proposalId, DataTypes.Ballot ballot) external;

    function getVoteTotals(
        uint16 proposalId
    ) external view returns (DataTypes.VoteTotals memory);

    function tallyVote(uint16 proposalId) external;

    function getCurrentPercentages(
        uint16 proposalId
    ) external view returns (uint256 for_, uint256 against, uint256 abstain);

    function executeProposal(uint16 proposalId) external;

    function getBallot(
        address voter,
        uint16 proposalId
    ) external view returns (DataTypes.Ballot);

    function getProposal(
        uint16 proposalId
    ) external view returns (DataTypes.Proposal memory);

    function listActiveProposals()
        external
        view
        returns (DataTypes.Proposal[] memory);

    function listTimelockedProposals()
        external
        view
        returns (DataTypes.Proposal[] memory);

    function multisig() external view returns (address);
}
