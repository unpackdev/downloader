// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using IterableLoanMap for IterableLoanMap.RateToLoanMap;
 *
 *     // Declare a set state variable
 *     IterableLoanMap.RateToLoanMap private myMap;
 * }
 * ```
 *
 * Only maps of type `uint256 -> Loan` (`RateToLoanMap`) are
 * supported.
 */
library IterableLoanMap {
    struct Loan {
        uint256 _principalOnly;
        uint256 _principalWithInterest;
        uint256 _lastAccrualTimestamp;
    }

    struct LoanMapEntry {
        uint256 _key;
        Loan _value;
    }

    struct RateToLoanMap {
        // Storage of map keys and values
        LoanMapEntry[] _entries;
        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(uint256 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        RateToLoanMap storage self,
        uint256 key,
        Loan memory value
    ) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = self._indexes[key];

        if (keyIndex == 0) {
            // Equivalent to !contains(map, key)
            self._entries.push(LoanMapEntry({_key: key, _value: value}));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            self._indexes[key] = self._entries.length;
            return true;
        } else {
            self._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(RateToLoanMap storage self, uint256 key)
        internal
        returns (bool)
    {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = self._indexes[key];

        if (keyIndex != 0) {
            // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = self._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            LoanMapEntry storage lastEntry = self._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            self._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            self._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            self._entries.pop();

            // Delete the index for the deleted slot
            delete self._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function contains(RateToLoanMap storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(RateToLoanMap storage self)
        internal
        view
        returns (uint256)
    {
        return self._entries.length;
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(RateToLoanMap storage self, uint256 index)
        internal
        view
        returns (uint256, Loan memory)
    {
        require(
            self._entries.length > index,
            "IterableLoanMap: index out of bounds"
        );

        LoanMapEntry storage entry = self._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to return the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(RateToLoanMap storage self, uint256 key)
        internal
        view
        returns (bool, Loan memory)
    {
        uint256 keyIndex = self._indexes[key];
        if (keyIndex == 0)
            return (
                false,
                Loan({
                    _principalOnly: 0,
                    _principalWithInterest: 0,
                    _lastAccrualTimestamp: 0
                })
            ); // Equivalent to contains(map, key)
        return (true, self._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function get(RateToLoanMap storage self, uint256 key)
        internal
        view
        returns (Loan memory)
    {
        uint256 keyIndex = self._indexes[key];
        require(keyIndex != 0, "IterableLoanMap: nonexistent key"); // Equivalent to contains(map, key)
        return self._entries[keyIndex - 1]._value; // All indexes are 1-based
    }
}
