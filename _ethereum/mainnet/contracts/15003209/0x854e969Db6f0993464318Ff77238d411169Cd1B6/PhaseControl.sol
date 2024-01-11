// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./AccessLock.sol";

/// @title Access Lock
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice Provides Phases
contract PhaseControl is AccessLock {
    enum Phases {
        CLOSED,
        PUBLIC
    }
    Phases public phase = Phases.CLOSED;

    event PhaseSet(address indexed owner, Phases _phase);

    /// @notice Set Phase
    /// @param _phase - closed/public
    function setPhase(Phases _phase) external onlyOwner {
        phase = _phase;
        emit PhaseSet(msg.sender, _phase);
    }

    /// @notice reverts based on phase and caller access
    modifier restrictForPhase() {
        require(
            msg.sender == owner() ||
                (phase == Phases.PUBLIC),
            "Unavailable for current phase"
        );
        _;
    }
}
