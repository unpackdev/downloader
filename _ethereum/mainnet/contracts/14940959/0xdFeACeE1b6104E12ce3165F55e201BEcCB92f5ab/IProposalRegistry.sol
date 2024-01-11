// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IProposalRegistry {
    enum VotingType {
        Single,
        Weighted
    }

    struct Proposal {
        uint256 deadline;
        uint256 maxIndex;
        VotingType _type;
    }

    function proposalInfo(bytes32 proposalHash)
        external
        returns (Proposal memory ProposalInfo);
}