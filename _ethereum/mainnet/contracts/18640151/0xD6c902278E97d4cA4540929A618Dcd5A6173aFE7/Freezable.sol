// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract Freezable {
    /* solhint-disable custom-errors */
    event Freeze(address indexed account);
    event Unfreeze(address indexed account);

    mapping(address => bool) private _isFrozen;

    modifier whenNotFrozen(address account) {
        require(!_isFrozen[account], "Freezable: frozen");
        _;
    }

    function isFrozen(
        address account
    ) public view virtual returns (bool frozen) {
        return _isFrozen[account];
    }

    function _freeze(address account) internal virtual returns (bool success) {
        require(!isFrozen(account), "Freezable: frozen");
        _isFrozen[account] = true;
        emit Freeze(account);
        success = true;
    }

    function _unfreeze(
        address account
    ) internal virtual returns (bool success) {
        require(isFrozen(account), "Freezable: not be frozen");
        _isFrozen[account] = false;
        emit Unfreeze(account);
        success = true;
    }
}
