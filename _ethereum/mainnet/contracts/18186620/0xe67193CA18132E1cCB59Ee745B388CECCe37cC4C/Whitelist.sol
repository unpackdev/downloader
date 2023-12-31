// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./AccessControlEnumerable.sol";

contract Whitelist is AccessControlEnumerable {
    bytes32 public constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");

    mapping(address => bool) public whitelist;

    bool public isWhitelistEnabled;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    constructor() {
        isWhitelistEnabled = true;
        _grantRole(WHITELIST_ADMIN_ROLE, msg.sender);
    }

    function addWhitelisted(address account) external onlyRole(WHITELIST_ADMIN_ROLE) {
        whitelist[account] = true;
        emit WhitelistedAdded(account);
    }

    function removeWhitelisted(address account) external onlyRole(WHITELIST_ADMIN_ROLE) {
        whitelist[account] = false;
        emit WhitelistedRemoved(account);
    }

    function setWhitelistEnabled(bool enabled) external onlyRole(WHITELIST_ADMIN_ROLE) {
        isWhitelistEnabled = enabled;
    }

    modifier onlyWhitelisted(address account) {
        require(!isWhitelistEnabled || whitelist[account], "Whitelist: caller is not whitelisted");
        _;
    }
}
