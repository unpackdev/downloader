// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

library StringsUtils {
    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        uint256 bStrLen = bStr.length;
        for (uint256 i; i < bStrLen; ) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
            unchecked {
                ++i;
            }
        }
        return string(bLower);
    }
}
