// SPDX-License-Identifier: MIT

pragma solidity =0.8.19;

import "./OwnableUpgradeable.sol";
import "./IMasterWhitelist.sol";

/// @title Master Whitelist
/// @notice Contract that manages a whitelist of users.
contract MasterWhitelist is OwnableUpgradeable, IMasterWhitelist {
    /// @notice List of agents, who are in charge of managing the users whitelist.
    mapping(address => bool) public agents;

    /// @notice Whitelist for users.
    mapping(address => WhitelistingStatus) public users;

    /// @notice Gap for upgradeability.
    uint256[50] private __gap;

    // No storage variables should be removed or modified since this is an upgradeable contract.
    // It is safe to add new ones as long as they are declared after the existing ones.

    /// @notice Requires that the transaction sender is an agent.
    modifier onlyAgent() {
        if (!isAgent(msg.sender)) {
            revert CallerIsNotAnAgent();
        }
        _;
    }

    /// @dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Initializable-_disableInitializers--
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializer for the whitelist.
    function initialize() external initializer {
        __Ownable_init();
    }

    /// @notice Adds an agent to the list of agents.
    /// @param _agent The address of the agent.
    function addAgent(address _agent) external onlyAgent {
        agents[_agent] = true;

        emit AgentAdded(_agent);
    }

    /// @notice Removes an agent from the list of agents.
    /// @param _agent The address of the agent.
    function removeAgent(address _agent) external onlyAgent {
        delete agents[_agent];

        emit AgentRemoved(_agent);
    }

    /// @notice Whitelists a user.
    /// @param _user The address of the user.
    function whitelistUser(address _user) external onlyAgent {
        if (users[_user] == WhitelistingStatus.Whitelisted) {
            revert UserAlreadyWhitelisted();
        }

        emit WhitelistingStatusChanged(_user, users[_user], WhitelistingStatus.Whitelisted);

        users[_user] = WhitelistingStatus.Whitelisted;
    }

    /// @notice Blacklists a user.
    /// @param _user The address of the user.
    function blacklistUser(address _user) external onlyAgent {
        if (users[_user] == WhitelistingStatus.Blacklisted) {
            revert UserAlreadyBlacklisted();
        }

        emit WhitelistingStatusChanged(_user, users[_user], WhitelistingStatus.Blacklisted);

        users[_user] = WhitelistingStatus.Blacklisted;
    }

    /// @notice Clear the whitelist status for the user.
    /// @param _user The address of the user.
    function clearWhitelistStatus(address _user) external onlyAgent {
        if (users[_user] == WhitelistingStatus.None) {
            revert WhitelistingStatusAlreadyCleared();
        }

        emit WhitelistingStatusChanged(_user, users[_user], WhitelistingStatus.None);

        users[_user] = WhitelistingStatus.None;
    }

    /// @notice Checks if a user is whitelisted.
    /// @param _user The address to check.
    /// @return A value indicating whether this user is whitelisted.
    function isUserWhitelisted(address _user) external view returns (bool) {
        return users[_user] == WhitelistingStatus.Whitelisted;
    }

    /// @notice Checks if a user is blacklisted.
    /// @param _user The address to check.
    /// @return A value indicating whether this user is blacklisted.
    function isUserBlacklisted(address _user) public view returns (bool) {
        return users[_user] == WhitelistingStatus.Blacklisted;
    }

    /// @notice Checks if this address is an agent.
    /// @param _agent The address to check.
    /// @dev The owner is always an agent.
    /// @return A value indicating whether this address is that of an agent.
    function isAgent(address _agent) public view returns (bool) {
        return _agent == owner() || agents[_agent];
    }
}
