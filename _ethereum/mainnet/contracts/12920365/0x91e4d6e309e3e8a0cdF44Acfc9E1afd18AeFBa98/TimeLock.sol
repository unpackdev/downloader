// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./Ownable.sol";

abstract contract TimeLock is Ownable {
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

    function lockedRelease(address _lockAddress) internal virtual {
        require(_lockAddress != address(0), "ERR: zero lock address");
        if (_isExlcludeFromLock[_lockAddress]) return;

        delete _lockedList[_lockAddress];
    }

    function checkRemainTime(address _lockAddress) internal view virtual returns (uint) {
        require(_lockAddress != address(0), "ERR: zero lock address");
        if (_isExlcludeFromLock[_lockAddress]) return 0;
        if (_lockedList[_lockAddress].endTime == 0) return 0;
        if(_lockedList[_lockAddress].endTime > uint64(block.timestamp)) {
            return _lockedList[_lockAddress].endTime - uint64(block.timestamp);
        }
        return 0;
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