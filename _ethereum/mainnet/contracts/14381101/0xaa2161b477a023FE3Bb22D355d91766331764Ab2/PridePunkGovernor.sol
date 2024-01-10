// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Governor.sol";
import "./GovernorSettings.sol";
import "./GovernorCountingSimple.sol";
import "./GovernorVotes.sol";
import "./GovernorVotesQuorumFraction.sol";
import "./IERC721Receiver.sol";

/// @custom:security-contact dennison@dennisonbertram.com
contract PridePunkGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    IERC721Receiver
{
    constructor(IVotes _token)
        Governor("Pride Punk Governor")
        GovernorSettings(
            1, /* 1 block */
            19636, /* 3 days */
            1e18
        )
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {}

    // Enable reciving ERC721s
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
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

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotes)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }
}
