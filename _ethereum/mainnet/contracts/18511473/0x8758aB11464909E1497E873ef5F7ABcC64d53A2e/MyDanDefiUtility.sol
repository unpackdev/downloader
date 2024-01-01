// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyDanDefiUtility {
    function toLowerCase(string memory str) public pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character ASCII range: 65 to 90
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // Convert to lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }

        return string(bLower);
    }

    function max(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        if (a > b) {
            if (a > c) {
                return a;
            }
            return c;
        }
        if (b > c) {
            return b;
        }
        return c;
    }

    function min(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        if (a < b) {
            if (a < c) {
                return a;
            }
            return c;
        }
        if (b < c) {
            return b;
        }
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        }
        return b;
    }
}
