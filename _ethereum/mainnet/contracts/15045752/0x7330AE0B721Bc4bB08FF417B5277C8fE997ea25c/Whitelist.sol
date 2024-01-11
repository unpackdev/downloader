// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./AccessProtected.sol";

abstract contract Whitelist is AccessProtected {
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blacklisted;

    bool public checkForWhitelist;

    event Whitelisted(address indexed _addr, bool enabled);
    event Blacklisted(address indexed _addr, bool enabled);
    event SetWhitelistEnabled(bool enabled);

    function setWhitelistEnabled(bool enabled) public onlyAdmin {
        checkForWhitelist = enabled;
        emit SetWhitelistEnabled(enabled);
    }

    function _whitelist(address user, bool enabled) internal {
        whitelisted[user] = enabled;
        emit Whitelisted(user, enabled);
    }

    function whitelist(address user, bool enabled) external onlyAdmin {
        _whitelist(user, enabled);
    }

    function whitelistBatch(address[] memory users, bool[] memory enabled)
        external
        onlyAdmin
    {
        require(
            users.length == enabled.length,
            "Length of users and enabled must match"
        );
        for (uint256 i = 0; i < users.length; i++) {
            _whitelist(users[i], enabled[i]);
        }
    }

    function _blacklist(address user, bool enabled) internal {
        blacklisted[user] = enabled;
        emit Blacklisted(user, enabled);
    }

    function blacklist(address user, bool enabled) external onlyAdmin {
        _blacklist(user, enabled);
    }

    function blacklistBatch(address[] memory users, bool[] memory enabled)
        external
        onlyAdmin
    {
        require(
            users.length == enabled.length,
            "Length of users and enabled must match"
        );
        for (uint256 index = 0; index < users.length; index++) {
            _blacklist(users[index], enabled[index]);
        }
    }

    modifier onlyWhitelisted() {
        require(
            checkForWhitelist == false || whitelisted[msg.sender] == true,
            "User is not whitelisted"
        );
        require(blacklisted[msg.sender] == false, "User is blacklisted");
        _;
    }
}
