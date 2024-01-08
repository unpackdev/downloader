// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Governor.sol";
import "./GovernorProposalThreshold.sol";
import "./GovernorCountingSimple.sol";
import "./GovernorVotes.sol";

contract PaperGov is Governor, GovernorProposalThreshold, GovernorCountingSimple, GovernorVotes {
    constructor(ERC20Votes _token) Governor("PaperGov") GovernorVotes(_token) {}

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    function votingPeriod() public pure override returns (uint256) {
        return 45818; // 1 week
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 2500000e18;
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 20000e18;
    }

    // The following functions are overrides required by Solidity.

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
