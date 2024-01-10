// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library ArraySort {
    /**
     * Sort an array
     * @param array a bytes32 array
     */
    function sort(bytes32[] memory array) public pure returns (bytes32[] memory) {
        _quickSort(array, 0, array.length);
        return array;
    }

    function _quickSort(
        bytes32[] memory array,
        uint256 i,
        uint256 j
    ) private pure {
        if (j - i < 2) return;

        uint256 p = i;
        for (uint256 k = i + 1; k < j; ++k) {
            if (array[i] > array[k]) {
                _swap(array, ++p, k);
            }
        }
        _swap(array, i, p);
        _quickSort(array, i, p);
        _quickSort(array, p + 1, j);
    }

    function _swap(
        bytes32[] memory array,
        uint256 i,
        uint256 j
    ) private pure {
        (array[i], array[j]) = (array[j], array[i]);
    }
}
