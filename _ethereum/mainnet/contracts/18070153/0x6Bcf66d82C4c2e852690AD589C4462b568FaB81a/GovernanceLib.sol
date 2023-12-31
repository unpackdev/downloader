// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Errors.sol";
import "./Ownable.sol";
import "./IConfigurator.sol";
import "./IGovernance.sol";
import "./IVoteStrategy.sol";

struct Vote {
    uint power;
    bool support;
}

struct Proposal { 
    ProposalMeta meta;
    IVoteStrategy strategy;   // the address of the strategy to determine voting power of an account
    mapping(address => Vote) votes;
}


library GovernanceLib {

    uint constant HUNDRED_PERCENT = 10000;

    function isValid(Proposal storage p) internal view returns(bool) {
        return p.meta.proposalId > 0 && address(p.strategy) != address(0);
    }

    function totalVotePower(Proposal storage p) internal view returns(uint) {
        return p.strategy.totalVotePower(p.meta.target, p.meta.blockNo);
    }

    function votePower(Proposal storage p, address account) internal view returns(uint) {
        return p.strategy.votePower(p.meta.target, p.meta.blockNo, account);
    }

    function state(Proposal storage p) internal view returns(ProposalState) {
        uint64 current = uint64(block.timestamp);
        if (current < p.meta.startedAt)
            return ProposalState.Pending;
        if (p.meta.state != ProposalState.Auto)
            return p.meta.state;
        if (current < p.meta.endedBy)
            return ProposalState.Voting;
        return ProposalState.Failed;
    }

    function validQuorum(Proposal storage p) internal view returns(bool) {
        return validQuorum(p, p.strategy.totalVotePower(p.meta.target, p.meta.blockNo));
    }

    function validQuorum(Proposal storage p, uint totalVotes) internal view returns(bool) {
        return p.meta.forVotes * HUNDRED_PERCENT / totalVotes >= p.strategy.minQuorum(p.meta.target);
    }

    function validVoteDifferential(Proposal storage p) internal view returns(bool) {
        return validVoteDifferential(p, p.strategy.totalVotePower(p.meta.target, p.meta.blockNo));
    }

    function validVoteDifferential(Proposal storage p, uint totalVotes) internal view returns(bool) {
        uint forPercent = p.meta.forVotes * HUNDRED_PERCENT / totalVotes;
        uint againstPercent = p.meta.againstVotes * HUNDRED_PERCENT / totalVotes;
        return forPercent >= againstPercent + p.strategy.voteDifferential(p.meta.target);
    }

    function isPassedProposal(Proposal storage p) internal view returns(bool) {
        uint totalVotes = p.strategy.totalVotePower(p.meta.target, p.meta.blockNo);
        return validQuorum(p, totalVotes) && validVoteDifferential(p, totalVotes);
    }

    function isOffchainProposal(Proposal storage p) internal view returns(bool) {
        return p.meta.targets.length == 0;
    }
}