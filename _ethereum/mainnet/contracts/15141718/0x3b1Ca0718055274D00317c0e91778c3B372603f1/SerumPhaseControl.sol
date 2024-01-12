// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./AccessLock.sol";

/// @title Serum Phase Control
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice Provides Phases
contract SerumPhaseControl is AccessLock {
    enum Phases {
        CLOSED,
        PRIVATE,
        PUBLIC
    }
    enum Action {
        CLAIM,
        PURCHASE
    }
    Phases public phase = Phases.CLOSED;

    event PhaseSet(address indexed owner, Phases _phase);

    /// @notice Set Phase
    /// @param _phase - closed/private/public
    function setPhase(Phases _phase) external onlyOwner {
        phase = _phase;
        emit PhaseSet(msg.sender, _phase);
    }

    /// @notice reverts based on phase and caller access
    modifier restrictForPhase(Action action) {
        require(
            msg.sender == owner() ||
                (phase == Phases.PRIVATE && action == Action.CLAIM) ||
                (phase == Phases.PUBLIC && action == Action.CLAIM) ||
                (phase == Phases.PUBLIC && action == Action.PURCHASE),
            "Unavailable for current phase"
        );
        _;
    }
}
