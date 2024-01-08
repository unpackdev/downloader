// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;


library Array {
    function indexOf(address[] storage values, address value) internal view returns(uint) {
        uint i = 0;

        while (values[i] != value && i <= values.length) {
            i++;
        }

        return i;
    }

    /** Removes the given value in an array. */
    function removeByValue(address[] storage values, address value) internal {
        uint i = indexOf(values, value);

        removeByIndex(values, i);
    }

    /** Removes the value at the given index in an array. */
    function removeByIndex(address[] storage values, uint i) internal {
        while (i<values.length-1) {
            values[i] = values[i+1];
            i++;
        }

        values.pop();
    }
}
