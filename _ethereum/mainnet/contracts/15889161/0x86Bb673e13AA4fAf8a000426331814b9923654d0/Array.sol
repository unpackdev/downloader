// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

library Array {
    function removeEmpty(uint8[] memory b) internal pure returns (uint8[] memory) {
        uint256 count;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] != uint8(0)) {
                count++;
            }
        }
        uint8[] memory a = new uint8[](count);
        uint256 j;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] == uint8(0)) {
                continue;
            }
            a[j] = b[i];
            j++;
        }
        return a;
    }
}
