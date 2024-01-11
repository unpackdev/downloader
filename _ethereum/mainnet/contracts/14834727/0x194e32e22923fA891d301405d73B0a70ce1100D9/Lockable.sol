// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Context.sol";

abstract contract Lockable is Context {
    event Locked(address account);
    event Unlocked(address account);

    bool private _locked;

    constructor() {
        _locked = false;
    }

    function locked() public view virtual returns (bool) {
        return _locked;
    }

    modifier whenNotLocked() {
        require(!locked(), "Lockable: locked");
        _;
    }

    modifier whenLocked() {
        require(locked(), "Lockable: not locked");
        _;
    }

    function _lock() internal virtual whenNotLocked {
        _locked = true;
        emit Locked(_msgSender());
    }

    function _unlock() internal virtual whenLocked {
        _locked = false;
        emit Unlocked(_msgSender());
    }
}