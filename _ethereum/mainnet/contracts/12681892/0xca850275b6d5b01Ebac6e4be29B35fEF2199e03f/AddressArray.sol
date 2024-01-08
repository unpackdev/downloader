// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.7.6;

library AddressArray {
    /**
     * Searches for the specified element and returns the one-based index of the first occurrence within the entire array.
     * @param array The array to search.
     * @param element The element to locate in the array.
     * @return The one-based index of the first occurrence of item within the entire arry, if found; otherwise, 0.
     */
    function indexOf(address[] storage array, address element)
        internal
        view
        returns (uint256)
    {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == element) {
                return i + 1;
            }
        }
        return 0;
    }

    /**
     * Determines whether an element is in the array.
     * @param array The array to search.
     * @param element The element to locate in the array.
     * @return true if item is found in the array; otherwise, false.
     */
    function contains(address[] storage array, address element)
        internal
        view
        returns (bool)
    {
        uint256 index = indexOf(array, element);
        return index > 0;
    }

    /**
     * Removes the element at the specified index of the array.
     * @param array The array to search.
     * @param index The one-based index of the element to remove.
     */
    function removeAt(address[] storage array, uint256 index) internal {
        require(index > 0, "AddressArray: index is one-based");

        uint256 length = array.length;
        require(index <= length, "AddressArray: index is greater than length");

        array[index - 1] = array[length - 1];
        array.pop();
    }
}
