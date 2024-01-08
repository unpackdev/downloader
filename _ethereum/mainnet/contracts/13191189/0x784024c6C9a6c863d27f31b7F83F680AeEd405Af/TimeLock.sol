// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

abstract contract TimeLock {
    struct LockedAddress {
        uint64 lockedPeriod;
        uint64 endTime;
    }

    
    mapping(address => LockedAddress) private _lockedList;
    mapping (address => bool) private _isExlcludeFromLock;
    constructor () { }
    function lockAddress(address _lockAddress, uint64 lockTime) internal virtual {
        require(_lockAddress != address(0), "ERR: zero lock address");
        require(lockTime > 0, "ERR: zero lock period");
        if (!_isExlcludeFromLock[_lockAddress]) {
            _lockedList[_lockAddress].lockedPeriod = lockTime;
            _lockedList[_lockAddress].endTime = uint64(block.timestamp) + lockTime;
        }
    }

    function isUnLocked(address _lockAddress) internal view virtual returns (bool) {
        require(_lockAddress != address(0), "ERR: zero lock address");
        if (_isExlcludeFromLock[_lockAddress]) return true;
        return _lockedList[_lockAddress].endTime < uint64(block.timestamp);
    }

    function excludeFromLock(address _lockAddress) internal virtual {
        require(_lockAddress != address(0), "ERR: zero lock address");
        if (_isExlcludeFromLock[_lockAddress]) return;
        _isExlcludeFromLock[_lockAddress] = true;
    }
}