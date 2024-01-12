// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@                  @@@@@@                  @@@@@@@                  @@@@@@@@@@@@@          
// @@@@@@@@@@@@@                  @@@@@@                  @@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@                  @@@@@@      @@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@            @@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@            @@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@        @@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@      @@@@@@@@@@@@      @@@@@@@@@@@@@@@@@@@                  @@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Governor.sol";
import "./GovernorSettings.sol";
import "./GovernorCountingSimple.sol";
import "./GovernorVotes.sol";
import "./GovernorVotesQuorumFraction.sol";

contract TechnoFeudalDAO is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction {
    constructor(IVotes _token)
        Governor("TechnoFeudalDAO")
        GovernorSettings(1 /* 1 block */, 45818 /* 1 week */, 0)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {}

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }
}
