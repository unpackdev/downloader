// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct ItLock {
    // unlock time => amount
    mapping(uint64 => uint256) data;
    // unlock time => index
    mapping(uint64 => uint256) indexs;
    // array of unlock time
    uint64[] keys;
    // unlocked amount
    uint256 unlockedAmount;
    // never use it, just for keep compile success.
    uint256 size;
}

library IterableLock {
    error InsufficientAmount();
    error InvalidKey();
    error NotExpired();
    error NothingChanged();
    error OnlyExtendable();
    error OnlyLockable();
    error TooMuchAmount();

    ///@notice Deposit new lock to this struct
    function deposit(
        ItLock storage self_,
        uint64 key_,
        uint256 value_
    ) internal {
        if (value_ == 0) revert NothingChanged();
        if (key_ <= block.timestamp) {
            self_.unlockedAmount += value_;
            return;
        }

        uint256 keyIndex = self_.indexs[key_];
        self_.data[key_] += value_; // value is added to the existing unlock time
        if (keyIndex > 0) return;
        // When the key not exists, add it
        self_.keys.push(key_);
        self_.indexs[key_] = self_.keys.length;
    }

    /// @notice Lock with `key` from the `unlockedAmount`
    function lock(ItLock storage self_, uint64 key_, uint256 value_) internal {
        if (key_ <= block.timestamp) revert OnlyLockable();
        uint256 availableValue = self_.unlockedAmount;
        if (value_ > availableValue) revert TooMuchAmount();

        self_.unlockedAmount -= value_;

        uint256 keyIndex = self_.indexs[key_];
        self_.data[key_] += value_; // value is added to the existing unlock time
        if (keyIndex > 0) return;
        // When the key not exists, add it
        self_.keys.push(key_);
        self_.indexs[key_] = self_.keys.length;
    }

    /// @notice Relock from `key` to `newKey`
    function relock(
        ItLock storage self_,
        uint64 key_,
        uint64 newKey_
    ) internal {
        if (key_ >= newKey_) revert OnlyExtendable();
        uint256 keyIndex = self_.indexs[key_];
        if (keyIndex == 0) revert InvalidKey();

        uint256 lockedAmount = self_.data[key_];

        // To remove the old key, key is swapped with last key in the key array, and then pop the `last key` which is `key` now
        // Update index for the swapped `last key`, and then remove index and data for the `removing key`
        uint64 lastKey = self_.keys[self_.keys.length - 1];
        if (key_ != lastKey) {
            self_.keys[keyIndex - 1] = lastKey;
            self_.indexs[lastKey] = keyIndex;
        }

        delete self_.data[key_];
        delete self_.indexs[key_];
        self_.keys.pop();

        // If new unlock time is before the current time, just add it to the unlocked amount
        if (newKey_ <= block.timestamp) {
            self_.unlockedAmount += lockedAmount;
            return;
        }
        // If new key does not exist in the key array, add it
        uint256 newKeyIndex = self_.indexs[newKey_];
        if (newKeyIndex == 0) {
            self_.keys.push(newKey_);
            self_.indexs[newKey_] = self_.keys.length;
        }
        self_.data[newKey_] += lockedAmount;
    }

    /// @notice Unlock the expired lock
    function unlock(ItLock storage self_, uint64 key_) internal {
        if (key_ > block.timestamp) revert NotExpired();
        uint256 keyIndex = self_.indexs[key_];
        if (keyIndex == 0) revert InvalidKey();
        self_.unlockedAmount += self_.data[key_];

        // To remove this key, key is swapped with last key in the key array, and then pop the `last key` which is `key` now
        // Update index for the swapped `last key`, and then remove index and data for the `removing key`
        uint64 lastKey = self_.keys[self_.keys.length - 1];
        if (key_ != lastKey) {
            self_.keys[keyIndex - 1] = lastKey;
            self_.indexs[lastKey] = keyIndex;
        }

        delete self_.data[key_];
        delete self_.indexs[key_];
        self_.keys.pop();
    }

    /// @notice Withdraw unlocked token
    function withdraw(ItLock storage self_, uint256 amount_) internal {
        if (self_.unlockedAmount < amount_) revert InsufficientAmount();
        self_.unlockedAmount -= amount_;
    }

    /// @notice Check if there is no lock for this token
    function empty(ItLock storage self_) internal view returns (bool) {
        return self_.keys.length == 0 && self_.unlockedAmount == 0;
    }

    /// @notice Get available amount (unlocked)
    function availableAmount(
        ItLock storage self_
    ) internal view returns (uint256) {
        return self_.unlockedAmount;
    }

    /// @notice Fetch locks
    /// @dev This function is pagniated for supporting the bulk locks
    function fetchItems(
        ItLock storage self_,
        uint256 offset_,
        uint256 count_
    )
        internal
        view
        returns (uint64[] memory unlockDates, uint256[] memory amounts)
    {
        uint64[] memory keys = self_.keys;
        if (offset_ < keys.length) {
            if (offset_ + count_ > keys.length) count_ = keys.length - offset_;
            unlockDates = new uint64[](count_);
            amounts = new uint256[](count_);
            uint256 i;
            for (; i < count_; i++) {
                uint64 key = keys[i + offset_];
                unlockDates[i] = key;
                amounts[i] = self_.data[key];
            }
        }
    }

    /// @notice Fetch locked amount from the key (unlock date)
    /// @dev Actually, `key_` is same as `unlockDate`, but we return it again to keep the style
    function fetchItem(
        ItLock storage self_,
        uint64 key_
    ) internal view returns (uint64 unlockDate, uint256 amount) {
        unlockDate = key_;
        uint256 keyIndex = self_.indexs[key_];
        if (keyIndex > 0) amount = self_.data[key_];
    }

    /// @notice Check if the deposited tokens exist for the key
    function exists(
        ItLock storage self_,
        uint64 key_
    ) internal view returns (bool) {
        uint256 keyIndex = self_.indexs[key_];
        if (keyIndex > 0) return self_.data[key_] > 0;
        return false;
    }
}
