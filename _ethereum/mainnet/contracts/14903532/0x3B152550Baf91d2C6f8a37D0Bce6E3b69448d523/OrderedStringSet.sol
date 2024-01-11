// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OrderedStringSets {
    struct OrderedStringSet {
        // Storage of set values
        string[] _values;
        // Position of the hashed value in the `_values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns index of string in set.
     */
    function add(OrderedStringSet storage set, string memory value) internal returns (uint256) {
        bytes32 hashedValue = keccak256(abi.encode(value));
        uint256 valueIndex = set._indexes[hashedValue];

        if (valueIndex != 0) {
            return valueIndex - 1;
        } else {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[hashedValue] = set._values.length;
            return set._values.length - 1;
        }
    }

    /**
     * @dev Returns (true, index) if the value is in the set, (false, 0) otherwise. O(1).
     */
    function indexOf(OrderedStringSet storage set, string memory value) internal view returns (bool, uint256) {
        bytes32 hashedValue = keccak256(abi.encode(value));
        uint256 index = set._indexes[hashedValue];
        return index != 0 ? (true, index - 1) : (false, 0);
    }

    /**
     * @dev Returns index > 0 if the value is in the set, 0 otherwise. O(1).
     */
    function contains(OrderedStringSet storage set, string memory value) internal view returns (bool) {
        bytes32 hashedValue = keccak256(abi.encode(value));
        return set._indexes[hashedValue] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(OrderedStringSet storage set) internal view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(OrderedStringSet storage set, uint256 index) internal view returns (string memory) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(OrderedStringSet storage set) internal view returns (string[] memory) {
        return set._values;
    }
}
