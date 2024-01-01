// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./GovernorSettingsUpgradeable.sol";
import "./GovernorVotesUpgradeable.sol";
import "./GovernorCountingSimpleUpgradeable.sol";
import "./IVotesUpgradeable.sol";
import "./GovernorTimelockControlUpgradeable.sol";
import "./Initializable.sol";
import "./IEsVsp.sol";
import "./IVsp.sol";

abstract contract VesperGovernorStorage {
    IVsp internal vsp;
}

contract VesperGovernor is
    Initializable,
    GovernorVotesUpgradeable,
    GovernorSettingsUpgradeable,
    GovernorCountingSimpleUpgradeable,
    GovernorTimelockControlUpgradeable,
    VesperGovernorStorage
{
    uint256 public constant MAX_BPS = 10000;
    uint256 public constant QUORUM_VOTES_PERCENT = 400; // 4%

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IVotesUpgradeable esVSP_,
        uint256 votingDelay_,
        uint256 votingPeriod_,
        uint256 proposalThreshold_,
        TimelockControllerUpgradeable timelock_
    ) external initializer {
        __Governor_init("VesperGovernor");
        __GovernorVotes_init(esVSP_);
        __GovernorSettings_init(votingDelay_, votingPeriod_, proposalThreshold_);
        __GovernorTimelockControl_init(timelock_);

        vsp = IEsVsp(address(esVSP_)).VSP();
    }

    function quorum(uint256 blockNumber_) public view override returns (uint256) {
        // To avoid double counting VSP tokens that are locked into esVSP contract, we subtract its balance from the overall supply
        // In summary: Total voting power = VSP supply + esVSP boost supply
        return
            ((vsp.totalSupply() +
                token.getPastTotalSupply(blockNumber_) -
                vsp.getPriorVotes(address(token), blockNumber_)) * QUORUM_VOTES_PERCENT) / MAX_BPS;
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernorUpgradeable, GovernorSettingsUpgradeable) returns (uint256) {
        return super.votingPeriod();
    }

    function state(
        uint256 proposalId_
    ) public view override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (ProposalState) {
        return super.state(proposalId_);
    }

    function propose(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        string memory description_
    ) public override(GovernorUpgradeable, IGovernorUpgradeable) returns (uint256) {
        return super.propose(targets_, values_, calldatas_, description_);
    }

    function proposalThreshold()
        public
        view
        override(GovernorUpgradeable, GovernorSettingsUpgradeable)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(
        uint256 proposalId_,
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        bytes32 descriptionHash_
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) {
        super._execute(proposalId_, targets_, values_, calldatas_, descriptionHash_);
    }

    function _cancel(
        address[] memory targets_,
        uint256[] memory values_,
        bytes[] memory calldatas_,
        bytes32 descriptionHash_
    ) internal override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (uint256) {
        return super._cancel(targets_, values_, calldatas_, descriptionHash_);
    }

    function _executor()
        internal
        view
        override(GovernorUpgradeable, GovernorTimelockControlUpgradeable)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(
        bytes4 interfaceId_
    ) public view override(GovernorUpgradeable, GovernorTimelockControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId_);
    }
}
