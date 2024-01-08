// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

import "./SafeMath.sol";

abstract contract LockLiquidity {
    using SafeMath for uint256;

    modifier afterLockUnsubscribe(uint256 yangId, uint256 chiId) {
        require(
            _isUnLocked[chiId] ||
                (!_isUnLocked[chiId] &&
                    block.timestamp > _locks[yangId][chiId]),
            "locks"
        );
        _;
    }

    function _updateLockSeconds(uint256 __locksInSeconds) internal {
        _lockInSeconds = __locksInSeconds;

        emit LockSeconds(_lockInSeconds);
    }

    function _updateLockState(uint256 chiId, bool state) internal {
        emit LockState(chiId, _isUnLocked[chiId], state);

        _isUnLocked[chiId] = state;
    }

    function _updateAccountLockDurations(
        uint256 yangId,
        uint256 chiId,
        uint256 currentTime
    ) internal {
        if (!_isUnLocked[chiId]) {
            uint256 durationTime = currentTime.add(_lockInSeconds);
            _locks[yangId][chiId] = durationTime > _locks[yangId][chiId]
                ? durationTime
                : _locks[yangId][chiId];
            emit LockAccount(yangId, chiId, _locks[yangId][chiId]);
        }
    }

    function durations(uint256 yangId, uint256 chiId)
        external
        view
        returns (uint256)
    {
        return _locks[yangId][chiId];
    }

    function __LockLiquidity__init() internal {
        _lockInSeconds = 3600 * 24 * 7;
    }

    uint256 private _lockInSeconds;
    mapping(uint256 => bool) private _isUnLocked;
    mapping(uint256 => mapping(uint256 => uint256)) private _locks;

    event LockSeconds(uint256);
    event LockState(uint256, bool, bool);
    event LockAccount(uint256, uint256, uint256);
}
