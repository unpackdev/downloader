// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct ItAddressMap {
    // address => index
    mapping(address => uint256) indexs;
    // array of address
    address[] keys;
    // never use it, just for keep compile success.
    uint256 size;
}

library IterableAddressMap {
    /// @notice Insert new address
    function insert(ItAddressMap storage self_, address key_) internal {
        uint256 keyIndex = self_.indexs[key_];
        if (keyIndex > 0) return;
        else {
            self_.keys.push(key_);
            self_.indexs[key_] = self_.keys.length;
        }
    }

    /// @notice Remove address
    function remove(ItAddressMap storage self_, address key_) internal {
        uint256 index = self_.indexs[key_];
        if (index == 0) return;
        address lastKey = self_.keys[self_.keys.length - 1];
        if (key_ != lastKey) {
            self_.keys[index - 1] = lastKey;
            self_.indexs[lastKey] = index;
        }
        delete self_.indexs[key_];
        self_.keys.pop();
    }

    /// @notice Check if the address is contained
    function contains(
        ItAddressMap storage self_,
        address key_
    ) internal view returns (bool) {
        return self_.indexs[key_] > 0;
    }

    /// @notice View the count of addresses added to this struct
    function itemCount(
        ItAddressMap storage self_
    ) internal view returns (uint256) {
        return self_.keys.length;
    }

    /// @notice View addresses added to this struct
    /// @dev This function is paginated for supporting the bulk addresses
    function fetchItems(
        ItAddressMap storage self_,
        uint256 offset_,
        uint256 count_
    ) internal view returns (address[] memory paginatedKeys) {
        address[] memory keys = self_.keys;
        if (offset_ < keys.length) {
            if (offset_ + count_ > keys.length) count_ = keys.length - offset_;
            paginatedKeys = new address[](count_);
            uint256 i;
            for (; i < count_; i++) paginatedKeys[i] = keys[i + offset_];
        }
    }
}
