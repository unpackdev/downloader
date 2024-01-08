// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title OrderedSet
 * @dev Ordered data structure. It has the properties of a mapping of uint256, but members are ordered
 * and can be enumerated. Values can be inserted and removed from anywhere. Add, append, remove and
 * contains are O(1). Enumerate is O(N).
 */
library OrderedAddressSet {

    struct Set {
        uint256 count;
        mapping (address => address) _next;
        mapping (address => address) _prev;
    }

    /**
     * @dev Insert a value between two values
     */
    function insert(Set storage set, address prev_, address value, address next_) internal {
        set._next[prev_] = value;
        set._next[value] = next_;
        set._prev[next_] = value;
        set._prev[value] = prev_;
        set.count += 1;
    }

    /**
     * @dev Insert a value as the new head
     */
    function add(Set storage set, address value) internal {
        insert(set, address(0), value, set._next[address(0)]);
    }

    /**
     * @dev Insert a value as the new tail
     */
    function append(Set storage set, address value) internal {
        insert(set, set._prev[address(0)], value, address(0));
    }

    /**
     * @dev Remove a value
     */
    function remove(Set storage set, address value) internal {
        set._next[set._prev[value]] = set._next[value];
        set._prev[set._next[value]] = set._prev[value];
        delete set._next[value];
        delete set._prev[value];
        if (set.count > 0) {
            set.count -= 1;
        }
    }

    /**
     * @dev Returns the head
     */
    function head(Set storage set) internal view returns (address) {
        return set._next[address(0)];
    }

    /**
     * @dev Returns the tail
     */
    function tail(Set storage set) internal view returns (address) {
        return set._prev[address(0)];
    }

    /**
     * @dev Returns the length
     */
    function length(Set storage set) internal view returns (uint256) {
        return set.count;
    }

    /**
     * @dev Returns the next value
     */
    function next(Set storage set, address _value) internal view returns (address) {
        return set._next[_value];
    }

    /**
     * @dev Returns the previous value
     */
    function prev(Set storage set, address _value) internal view returns (address) {
        return set._prev[_value];
    }

    /**
     * @dev Returns true if the value is in the set
     */
    function contains(Set storage set, address value) internal view returns (bool) {
        return set._next[address(0)] == value ||
               set._next[value] != address(0) ||
               set._prev[value] != address(0);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Set storage set) internal view returns (address[] memory) {
        address[] memory _values = new address[](set.count);
        address value = set._next[address(0)];
        uint256 i = 0;
        while (value != address(0)) {
            _values[i] = value;
            value = set._next[value];
            i += 1;
        }
        return _values;
    }

    /**
     * @dev Return an array with n values in the set, starting after "from"
     */
    function valuesFromN(Set storage set, address from, uint256 n) internal view returns (address[] memory) {
        address[] memory _values = new address[](n);
        address value = set._next[from];
        uint256 i = 0;
        while (i < n) {
            _values[i] = value;
            value = set._next[value];
            i += 1;
        }
        return _values;
    }
}
