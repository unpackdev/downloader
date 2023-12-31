// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Context.sol";

interface BlacklistEvents {
    /// @dev Emitted when `account` is blacklisted
    event Blacklisted(address indexed account);

    /// @dev Emitted when `account` is removed from the blacklist
    event Unblacklisted(address indexed account);
}

abstract contract Blacklist is BlacklistEvents, Context {
    /// @dev maps if an address has been blacklisted
    mapping(address => bool) private _blacklist;

    constructor() {}

    /// @dev only allows non-blacklisted addresses to call a function
    modifier onlyNotBlacklisted() {
        require(!isBlacklisted(_msgSender()), "Blacklist: caller is blacklisted");
        _;
    }

    /// @dev add address to blacklist
    function _addBlacklist(address account) internal virtual {
        _blacklist[account] = true;
        emit Blacklisted(account);
    }

    /// @dev remove address from blacklist
    function _removeBlacklist(address account) internal virtual {
        _blacklist[account] = false;
        emit Unblacklisted(account);
    }

    /// @dev checks if address is blacklisted
    function isBlacklisted(address account) public view virtual returns (bool) {
        return _blacklist[account];
    }
}
