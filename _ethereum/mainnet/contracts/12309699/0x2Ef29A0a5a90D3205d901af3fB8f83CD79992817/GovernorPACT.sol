// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./AbstractGovernor.sol";
import "./GovernanceOwnable.sol";
import "./SafeMath.sol";

contract GovernorPACT is AbstractGovernor, GovernanceOwnable {
    enum VotingSettingsKeys {
        DefaultPropose,
        FastPropose,
        MultiExecutable
    }

    // etherium - block_generation_frequency_ ~ 15s
    // binance smart chain - block_generation_frequency_ ~ 4s
    constructor(
        address pact_,
        uint256 block_generation_frequency_
    ) AbstractGovernor("Governor PACT", pact_) GovernanceOwnable(address(this)) public {
        _addAllowedTarget(address(this));
        _addAllowedTarget(pact_);

        _setVotingSettings(
            uint(VotingSettingsKeys.DefaultPropose), // votingSettingsId
            SafeMath.div(3 days, block_generation_frequency_),// votingPeriod
            SafeMath.div(15 days, block_generation_frequency_),// expirationPeriod
            10,// proposalMaxOperations
            25,// quorumVotesDelimiter 4% of total PACTs
            100// proposalThresholdDelimiter 1% of total PACTs
        );
        _setVotingSettings(
            uint(VotingSettingsKeys.FastPropose), // votingSettingsId
            SafeMath.div(1 hours, block_generation_frequency_),// votingPeriod
            SafeMath.div(2 hours, block_generation_frequency_),// expirationPeriod
            40,// proposalMaxOperations
            5,// quorumVotesDelimiter 20% of total PACTs
            20// proposalThresholdDelimiter 5% of total PACTs
        );
        _setVotingSettings(
            uint(VotingSettingsKeys.MultiExecutable), // votingSettingsId
            SafeMath.div(1 hours, block_generation_frequency_),// votingPeriod
            SafeMath.div(365 days, block_generation_frequency_),// expirationPeriod
            2,// proposalMaxOperations
            5,// quorumVotesDelimiter 20% of total PACTs
            20// proposalThresholdDelimiter 5% of total PACTs
        );
    }

    function createDefaultPropose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint) {
        for (uint i = 0; i < targets.length; i++) {
            require(allowedTargets[targets[i]], "GovernorPACT::createFastPropose: targets - supports only allowedTargets");
        }
        return _propose(
            uint(VotingSettingsKeys.DefaultPropose),
            targets,
            values,
            signatures,
            calldatas,
            description,
            false
        );
    }

    function createFastPropose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint) {
        for (uint i = 0; i < targets.length; i++) {
            require(allowedTargets[targets[i]], "GovernorPACT::createFastPropose: targets - supports only allowedTargets");
        }
        return _propose(
            uint(VotingSettingsKeys.FastPropose),
            targets,
            values,
            signatures,
            calldatas,
            description,
            false
        );
    }

    function createMultiExecutablePropose(
        address[] memory targets,
        uint[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint) {
        for (uint i = 0; i < targets.length; i++) {
            require(allowedTargets[targets[i]], "GovernorPACT::createMultiExecutablePropose: targets - supports only allowedTargets");
        }
        return _propose(
            uint(VotingSettingsKeys.MultiExecutable),
            targets,
            values,
            signatures,
            calldatas,
            description,
            true
        );
    }

    address[] internal allowedTargetsList;
    mapping (address => bool) public allowedTargets;

    function addAllowedTarget(address target) public onlyGovernance {
        _addAllowedTarget(target);
    }
    function _addAllowedTarget(address target) internal {
        if (allowedTargets[target] == false) {
            allowedTargets[target] = true;
            allowedTargetsList.push(target);
        }
    }

    function getAllowedTargets() public view returns(address[] memory) {
        return allowedTargetsList;
    }

}