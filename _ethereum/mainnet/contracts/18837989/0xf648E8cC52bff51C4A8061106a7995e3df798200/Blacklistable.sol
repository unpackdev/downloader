// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./Controllable.sol";

contract Blacklistable is Controllable {
    uint8 private constant _BLACKLIST_STATUS = 1;

    event Blacklisted(address indexed account);
    event Unblacklisted(address indexed account);

    /**
     * @dev Return `true` if the account is blacklisted
     */
    function isBlacklisted(address account) public view virtual returns (bool) {
        return _accountStatus[account] == _BLACKLIST_STATUS;
    }

    /**
     * @dev Internal function to add or remove an account to the blacklist
     */
    function _setBlacklist(address account, uint8 accountStatus) private {
        _accountStatus[account] = accountStatus;
    }

    /**
     * @dev Add an account to the blacklist
     */
    function blacklist(
        address account
    ) external virtual onlyOperator returns (bool) {
        _setBlacklist(account, _BLACKLIST_STATUS);
        emit Blacklisted(account);
        return true;
    }

    /**
     * @dev Remove an account to the blacklist
     */
    function unblacklist(
        address account
    ) external virtual onlyOperator returns (bool) {
        _setBlacklist(account, 0);
        emit Unblacklisted(account);
        return true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
