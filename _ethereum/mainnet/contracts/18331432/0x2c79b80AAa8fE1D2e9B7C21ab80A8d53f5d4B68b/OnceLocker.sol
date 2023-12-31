// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title Contract for one time call locker.
 */
contract OnceLocker {
    mapping(bytes4 => bool) private _locked;

    /**
     * @dev Ensure that the underlying method can only be called once.
     * @param method The underlying method selector
     */
    modifier once(bytes4 method) {
        require(!_isLocked(method), "OnceLocker: the method has been called");

        _lock(method);

        _;
    }

    /**
     * @dev Lock the given method.
     * @param method The given method selector
     */
    function _lock(bytes4 method) private {
        _locked[method] = true;
    }

    /**
     * @dev Check if the given method is locked.
     * @param method The given method selector
     * @return bool True if the given method has been called, false otherwise
     */
    function _isLocked(bytes4 method) private view returns (bool) {
        return _locked[method];
    }
}
