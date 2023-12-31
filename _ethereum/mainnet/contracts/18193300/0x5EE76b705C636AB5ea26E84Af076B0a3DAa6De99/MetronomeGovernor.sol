// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./GovernorSettings.sol";
import "./GovernorVotes.sol";
import "./GovernorCountingSimple.sol";
import "./IVotes.sol";
import "./GovernorTimelockControl.sol";
import "./IEsMet.sol";

contract MetronomeGovernor is GovernorVotes, GovernorSettings, GovernorCountingSimple, GovernorTimelockControl {
    uint256 public constant MAX_BPS = 10000;
    uint256 public constant QUORUM_VOTES_PERCENT = 400; // 4%
    IVotes internal immutable met;

    constructor(
        IVotes esMET_,
        uint256 votingDelay_,
        uint256 votingPeriod_,
        uint256 proposalThreshold_,
        TimelockController timelock_
    )
        Governor("MetronomeGovernor")
        GovernorVotes(esMET_)
        GovernorSettings(votingDelay_, votingPeriod_, proposalThreshold_)
        GovernorTimelockControl(timelock_)
    {
        met = IEsMet(address(esMET_)).MET();
    }

    function quorum(uint256 blockNumber_) public view override returns (uint256) {
        // To avoid double counting MET tokens that are locked into esMET contract, we subtract its balance from the overall supply
        // In summary: Total voting power = MET supply + esMET boost supply
        return
            ((met.getPastTotalSupply(blockNumber_) +
                token.getPastTotalSupply(blockNumber_) -
                met.getPastVotes(address(token), blockNumber_)) * QUORUM_VOTES_PERCENT) / MAX_BPS;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function state(
        uint256 proposalId_
    ) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(proposalId_);
    }

    function propose(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        string memory description_
    ) public override(Governor, IGovernor) returns (uint256) {
        return super.propose(targets_, values_, calldatas_, description_);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId_,
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        bytes32 descriptionHash_
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId_, targets_, values_, calldatas_, descriptionHash_);
    }

    function _cancel(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        bytes32 descriptionHash_
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets_, values_, calldatas_, descriptionHash_);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(
        bytes4 interfaceId_
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.supportsInterface(interfaceId_);
    }
}
