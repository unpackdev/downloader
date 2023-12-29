/*
 * Capital DEX
 *
 * Copyright ©️ 2023 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2023 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./AccessControl.sol";

interface IBlacklist {
    event BlacklistedEth(address account);
    event BlacklistedSub(bytes32 account);
    event RemovedFromBlacklistEth(address account);
    event RemovedFromBlacklistSub(bytes32 account);

    error BlacklistedAccountEth(address account);
    error BlacklistedAccountSub(bytes32 account);
    error AlreadyBlacklistedEth(address account);
    error AlreadyBlacklistedSub(bytes32 account);
    error NotInBlacklistEth(address account);
    error NotInBlacklistSub(bytes32 account);

    function setBlacklistEth(address account, bool blacklisted) external;
    function setBlacklistSub(bytes32 account, bool blacklisted) external;
    function isBlacklistedEth(address account) external view returns(bool);
    function isBlacklistedSub(bytes32 account) external view returns(bool);
}

contract Blacklist is IBlacklist, AccessControl {
    
    bytes32 public immutable blacklistManagerRole;

    mapping(address => bool) public ethBlacklisted;
    mapping(bytes32 => bool) public subBlacklisted;

    modifier NotBlacklistedEth(address account) {
        if(ethBlacklisted[account]) {
            revert BlacklistedAccountEth(account);
        }
        _;
    }

    modifier NotBlacklistedSub(bytes32 account) {
        if(subBlacklisted[account]) {
            revert BlacklistedAccountSub(account);
        }
        _;
    }

    constructor(address admin, bytes32 managerRole) {
        blacklistManagerRole = managerRole;
        AccessControl._grantRole(AccessControl.DEFAULT_ADMIN_ROLE, admin);
    }

    function setBlacklistEth(address account, bool blacklisted) external AccessControl.onlyRole(blacklistManagerRole) {
        if(blacklisted) {
            _blacklistEth(account);
        } else {
            _unblacklistEth(account);
        }
    }

    function setBlacklistSub(bytes32 account, bool blacklisted) external AccessControl.onlyRole(blacklistManagerRole) {
        if(blacklisted) {
            _blacklistSub(account);
        } else {
            _unblacklistSub(account);
        }
    }

    function isBlacklistedEth(address account) external view returns(bool) {
        return ethBlacklisted[account];
    }

    function isBlacklistedSub(bytes32 account) external view returns(bool) {
        return subBlacklisted[account];
    }

    function _blacklistEth(address account) private {
        if(!ethBlacklisted[account]) {
            ethBlacklisted[account] = true;
            emit BlacklistedEth(account);
        } else {
            revert AlreadyBlacklistedEth(account);
        }
    }

    function _blacklistSub(bytes32 account) private {
        if(!subBlacklisted[account]) {
            subBlacklisted[account] = true;
            emit BlacklistedSub(account);
        } else {
            revert AlreadyBlacklistedSub(account);
        }
    }

    function _unblacklistEth(address account) private {
        if(ethBlacklisted[account]) {
            ethBlacklisted[account] = false;
            emit RemovedFromBlacklistEth(account);
        } else {
            revert NotInBlacklistEth(account);
        }
    }

    function _unblacklistSub(bytes32 account) private {
        if(subBlacklisted[account]) {
            subBlacklisted[account] = false;
            emit RemovedFromBlacklistSub(account);
        } else {
            revert NotInBlacklistSub(account);
        }
    }
} 