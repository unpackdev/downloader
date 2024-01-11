// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";

/**
 * @title AdminController
 * AdminController -This contract manages the admin.
 */
abstract contract AdminController is Context, Ownable {
    mapping(address => bool) private _admins;

    event AdminSet(address indexed account, bool indexed status);

    constructor(address account) {
        _setAdmin(account, true);
    }

    modifier onlyAdmin() {
        address sender = _msgSender();
        (bool isValid, string memory errorMessage) = _validateAdmin(sender);
        require(isValid, errorMessage);
        _;
    }

    modifier onlyAdminOrOwner() {
        address sender = _msgSender();
        (bool isValid, string memory errorMessage) = _validateAdminOrOwner(
            sender
        );
        require(isValid, errorMessage);
        _;
    }

    function addAdmin(address account) external onlyOwner {
        _setAdmin(account, true);
    }

    function removeAdmin(address account) external onlyAdminOrOwner {
        _setAdmin(account, false);
    }

    function isAdmin(address account) external view returns (bool) {
        return _isAdmin(account);
    }

    function _setAdmin(address account, bool status) internal {
        _admins[account] = status;
        emit AdminSet(account, status);
    }

    function _isAdmin(address account) internal view returns (bool) {
        return _admins[account];
    }

    function _isAdminOrOwner(address account) internal view returns (bool) {
        return owner() == account || _isAdmin(account);
    }

    function _validateAdmin(address account)
        internal
        view
        returns (bool, string memory)
    {
        if (!_isAdmin(account)) {
            return (false, "AdminController: admin verification failed");
        }
        return (true, "");
    }

    function _validateAdminOrOwner(address account)
        internal
        view
        returns (bool, string memory)
    {
        if (!_isAdminOrOwner(account)) {
            return (
                false,
                "AdminController: admin or owner verification failed"
            );
        }
        return (true, "");
    }
}
