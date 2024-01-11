// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IERC20.sol";
import "./AccessLock.sol";

/// @title Access Lock
/// @author 0xhohenheim <contact@0xhohenheim.com>
/// @notice Provides Whitelist Access
contract Whitelist is AccessLock {
    enum Phases {
        CLOSED,
        WHITELIST,
        PUBLIC
    }
    Phases public phase = Phases.CLOSED;
    mapping(address => bool) public isWhitelisted; // user => isWhitelisted? mapping

    /// @notice emitted when user is whitelisted or blacklisted
    event WhitelistSet(address indexed user, bool isWhitelisted);
    event PhaseSet(address indexed owner, Phases _phase);

    /// @notice Whitelist/Blacklist
    /// @param user - Address of User
    /// @param _isWhitelisted - Whitelist?
    function setWhitelist(address user, bool _isWhitelisted) public onlyAdmin {
        isWhitelisted[user] = _isWhitelisted;
        // emit WhitelistSet(user, _isWhitelisted);
    }

    /// @notice Batch - Whitelist/Blacklist
    /// @param users - Addresses of User
    /// @param _isWhitelisted - Whitelist?
    function batchSetWhitelist(
        address[] memory users,
        bool[] memory _isWhitelisted
    ) external onlyAdmin {
        require(users.length == _isWhitelisted.length, "Length not equal");
        for (uint256 i = 0; i < users.length; i++) {
            setWhitelist(users[i], _isWhitelisted[i]);
        }
    }

    /// @notice Set Phase
    /// @param _phase - closed/public/whitelist
    function setPhase(Phases _phase) external onlyOwner {
        phase = _phase;
        emit PhaseSet(msg.sender, _phase);
    }

    /// @notice reverts based on phase and caller access
    modifier restrictForPhase() {
        require(
            msg.sender == owner() ||
                (phase == Phases.WHITELIST && isWhitelisted[msg.sender]) ||
                (phase == Phases.PUBLIC),
            "Unavailable for current phase"
        );
        _;
    }
}
