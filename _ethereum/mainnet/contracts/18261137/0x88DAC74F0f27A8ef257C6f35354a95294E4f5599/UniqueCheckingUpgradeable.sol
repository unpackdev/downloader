// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "./BitMaps.sol";

error AlreadyUsed();

abstract contract UniqueCheckingUpgradeable {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _isUsed;

    function _setUsed(uint256 uid_) internal {
        if (_isUsed.get(uid_)) revert AlreadyUsed();
        _isUsed.set(uid_);
    }

    function _used(uint256 uid_) internal view returns (bool) {
        return _isUsed.get(uid_);
    }

    function isUsed(uint256 uid_) external view returns (bool) {
        return _used(uid_);
    }
}
