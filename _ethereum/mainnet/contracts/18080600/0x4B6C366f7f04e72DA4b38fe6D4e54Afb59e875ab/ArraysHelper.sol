// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./console.sol";

library ArraysHelper {
    function sort(address[] memory array) public pure returns (address[] memory) {
        for (uint256 i = 1; i < array.length; ++i) {
            address current = array[i];

            uint256 j = i;
            while (j > 0 && array[j - 1] > current) {
                array[j] = array[j - 1];
                --j;
            }

            array[j] = current;
        }

        return array;
    }

    function test_mock() external pure {}
}
