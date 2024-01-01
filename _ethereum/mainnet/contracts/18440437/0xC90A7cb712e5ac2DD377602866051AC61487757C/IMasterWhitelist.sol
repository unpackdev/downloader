// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

/// @title Master Whitelist Interface
/// @notice Interface for a contract that manages a whitelist of users.
interface IMasterWhitelist {
    // The whitelisting status.
    enum WhitelistingStatus {
        None,
        Whitelisted,
        Blacklisted
    }

    // --- Events ---

    /// @notice Emits an event when an agent is added.
    /// @param _agent The address of the agent.
    event AgentAdded(address indexed _agent);

    /// @notice Emits an event when an agent is removed.
    /// @param _agent The address of the agent.
    event AgentRemoved(address indexed _agent);

    /// @notice Emitted when a user's whitelist status has changed.
    /// @param _user The address of the user.
    /// @param _oldStatus The status before the change.
    /// @param _newStatus The status after the change.
    event WhitelistingStatusChanged(
        address indexed _user,
        WhitelistingStatus indexed _oldStatus,
        WhitelistingStatus indexed _newStatus
    );

    // --- Errors ---

    /// @notice Error thrown when trying to perform an action reserved for agents.
    error CallerIsNotAnAgent();

    /// @notice Error thrown when trying to whitelist a user that's already whitelisted.
    error UserAlreadyWhitelisted();

    /// @notice Error thrown when trying to blacklist a user that's already blacklisted.
    error UserAlreadyBlacklisted();

    /// @notice Error thrown when trying to clear a user status.
    error WhitelistingStatusAlreadyCleared();

    // --- Functions ---

    /// @notice Checks if a user is in the whitelist.
    /// @param _user The address to check.
    /// @return A value indicating whether this user is whitelisted.
    function isUserWhitelisted(address _user) external view returns (bool);

    /// @notice Checks if a user is in the blacklist.
    /// @param _user The address to check.
    /// @return A value indicating whether this user is blacklisted.
    function isUserBlacklisted(address _user) external view returns (bool);

    /// @notice Checks if this address is an agent.
    /// @param _agent The address to check.
    /// @return A value indicating whether this address is that of an agent.
    function isAgent(address _agent) external view returns (bool);
}
