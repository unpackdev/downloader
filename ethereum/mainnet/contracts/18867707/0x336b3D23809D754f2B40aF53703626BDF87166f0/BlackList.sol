// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract BlackList {
    mapping (address => bool) private _isBlackListed;

    /**
     * @dev Emitted when the `_account` blocked.
     */
    event BlockedAccount(address indexed _account);

    /**
     * @dev Emitted when the `_account` unblocked.
     */
    event UnblockedAccount(address indexed _account);

    function isAccountBlocked(address _account) public view returns (bool) {
        return _isBlackListed[_account];
    }

    /**
     * @dev Add account to black list.
     *
     * WARNING: it allows everyone to set the address. Access controls MUST be defined in derived contracts.
     *
     * @param _account The address to be blocked
     */
    function _blockAccount (address _account) internal virtual {
        require(!_isBlackListed[_account], "Blacklist: Account is already blocked");
        _isBlackListed[_account] = true;

        emit BlockedAccount(_account);
    }

    function _unblockAccount (address _account) internal virtual {
        require(_isBlackListed[_account], "Blacklist: Account is already unblocked");
        _isBlackListed[_account] = false;

        emit UnblockedAccount(_account);
    }
}