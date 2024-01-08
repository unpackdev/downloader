// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library EnumerableBytesSet {
  struct BytesSet {
    // Storage of set values
    bytes32[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(bytes32 => uint256) _indexes;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(BytesSet storage set, bytes32 value) internal returns (bool) {
    if (!contains(set, value)) {
      set._values.push(value);

      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(BytesSet storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
    return set._indexes[value] != 0;
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(BytesSet storage set) internal view returns (uint256) {
    return set._values.length;
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(BytesSet storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
    require(set._values.length > index, 'EnumerableSet: index out of bounds');
    return set._values[index];
  }
}
