// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Ownable.sol";

/// @title Token Access
/// @notice Provides Admin, Blacklisting & Violator Access Control
contract TokenAccess is Ownable {
    mapping(address => bool) public isAdmin; // user => isAdmin? mapping
    mapping(address => bool) public isBlacklisted; // user => isBlacklisted? mapping
    mapping(address => bool) public isViolator; // user => isViolator? mapping

    /// @notice emitted when admin role is granted or revoked
    event AdminSet(address indexed user, bool isEnabled);
    /// @notice emitted when user is blacklisted or whitelisted
    event BlacklistSet(address indexed user, bool isBlacklisted);
    /// @notice emitted when user is set or unset as a violator
    event ViolatorSet(address wallet, bool isViolator);

    /// @notice Grant or Revoke Admin Access
    /// @param user - Address of User
    /// @param isEnabled - Grant or Revoke?
    function setAdmin(address user, bool isEnabled) external onlyOwner {
        isAdmin[user] = isEnabled;
        emit AdminSet(user, isEnabled);
    }

    /// @notice Blacklist or Whitelist a user
    /// @param user - Address of User
    /// @param blacklist - Blacklist user?
    function setBlacklist(address user, bool blacklist) external onlyAdmin {
        isBlacklisted[user] = blacklist;
        emit BlacklistSet(user, blacklist);
    }

    /// @notice Set/Unset user as Violator
    /// @param user - Address of User
    /// @param _isViolator - isViolator user?
    function setViolator(address user, bool _isViolator) external onlyAdmin {
        isViolator[user] = _isViolator;
        emit ViolatorSet(user, _isViolator);
    }

    /// @notice reverts if caller is not admin or owner
    modifier onlyAdmin() {
        require(
            isAdmin[msg.sender] || msg.sender == owner(),
            "TokenAccess: Callable only by admin/owner"
        );
        _;
    }
}
