// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Governor.sol";
import "./GovernorCompatibilityBravo.sol";
import "./GovernorVotesComp.sol";
import "./GovernorTimelockCompound.sol";

contract MyGovernor is Governor, GovernorCompatibilityBravo, GovernorVotesComp, GovernorTimelockCompound {
    constructor(ERC20VotesComp _token, ICompoundTimelock _timelock)
        Governor("MyGovernor")
        GovernorVotesComp(_token)
        GovernorTimelockCompound(_timelock)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 11520; // 2 days in blocks
    }

    function votingPeriod() public pure override returns (uint256) {
        return 23040; // 4 days in blocks
    }

    function quorum(uint256 blockNumber) public pure override returns (uint256) {
        return 320; // 4% of total NFT supply
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 1; // 1 Metamatician NFT
    }

    // The following functions are overrides required by Solidity.

    function getVotes(address account, uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesComp)
        returns (uint256)
    {
        return super.getVotes(account, blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, IGovernor, GovernorTimelockCompound)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, GovernorCompatibilityBravo, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockCompound) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockCompound) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockCompound) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, IERC165, GovernorTimelockCompound)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
