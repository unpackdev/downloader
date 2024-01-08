// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Governor.sol";
import "./GovernorProposalThreshold.sol";
import "./GovernorCountingSimple.sol";
import "./GovernorVotes.sol";
import "./GovernorVotesQuorumFraction.sol";

contract AdventureDAO is Governor, GovernorProposalThreshold, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
    // 5% of holders have to showup for a vote to be valid
    constructor(ERC20Votes _token)
        Governor("GoldDAO")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(5)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 45818; // 1 week
    }

    // Requires 200000 votes to create a proposal
    function proposalThreshold() public pure override returns (uint256) {
        return 200000e18;
    }

    // The following functions are overrides required by Solidity.

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotes)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        override(Governor, GovernorProposalThreshold)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }
}
