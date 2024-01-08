//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

/// @title QuickSort
/// @notice basic quickSort function from https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f#file-quicksort-sol
library QuickSort {
    struct Layer {
        uint256 value;
        uint256 index;
    }

    function sort(
        Layer[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].index;
        while (i <= j) {
            while (arr[uint256(i)].index < pivot) i += 1;
            while (pivot < arr[uint256(j)].index) j -= 1;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i += 1;
                j -= 1;
            }
        }
        if (left < j) sort(arr, left, j);
        if (i < right) sort(arr, i, right);
    }
}
