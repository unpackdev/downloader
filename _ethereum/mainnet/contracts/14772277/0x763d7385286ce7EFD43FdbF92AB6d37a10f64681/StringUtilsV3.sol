// SPDX-License-Identifier: MIT
/// @title StringUtilsV3
/// @notice StringUtilsV3
/// @author CyberPnk <cyberpnk@cyberpnk.win>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.13;

import "./StringUtilsV2.sol";
import "./strings.sol";
// import "./console.sol";

contract StringUtilsV3 is StringUtilsV2 {
    using strings for *;

    function base64Char(uint8 a) public pure returns(uint8) {
        if (a >= 65 && a <= 90) {
            return a - 65;
        } else if (a >= 97 && a <= 122) {
            return a - 97 + 26;
        } else if (a >= 48 && a <= 57) {
            return a - 48 + 52;
        } else if (a == 43) {
            return 62;
        } else if (a == 47) {
            return 63;
        } else {
            return 0;
        }
    }

    function base64Decode(bytes memory data) public pure returns (bytes memory) {
        uint len = data.length;
        uint resultLength = len * 3 / 4;
        if (len > 0 && data[len - 1] == "=") {
            resultLength--;
        }
        if (len > 1 && data[len - 2] == "=") {
            resultLength--;
        }
        bytes memory result = new bytes(resultLength);

        uint resultIndex = 0;
        for (uint i = 0; i<len; i+=4) {
            uint24 first = uint24(base64Char(uint8(data[i]))) * 2**18;
            uint24 second = uint24(base64Char(uint8(data[i + 1]))) * 2**12;
            uint24 third = uint24(base64Char(uint8(data[i + 2]))) * 2**6;
            uint24 fourth = uint24(base64Char(uint8(data[i + 3])));
            uint24 biggie = first | second | third | fourth;
            bytes1 firstCh = bytes1(uint8(biggie / 2**16));
            bytes1 secondCh = bytes1(uint8(biggie / 2**8 % 2**16));
            bytes1 thirdCh = bytes1(uint8(biggie % 2**8));
            result[resultIndex++] = firstCh;
            if (resultIndex < resultLength) {
                result[resultIndex++] = secondCh;
            }
            if (resultIndex < resultLength) {
                result[resultIndex++] = thirdCh;
            }
        }
        return result;
    }

    function extractFromTo(string memory str, string memory needleStart, string memory needleEnd) external pure returns(string memory) {
        strings.slice memory needleStartSlice = needleStart.toSlice();
        strings.slice memory strSlice = str.toSlice();
        strings.slice memory needleEndSlice = needleEnd.toSlice();
        strings.slice memory withoutStartSlice = strSlice
            .find(needleStartSlice)
            .beyond(needleStartSlice);

        strings.slice memory extractedSlice = withoutStartSlice
            .until(withoutStartSlice.copy().find(needleEndSlice));
        
        return extractedSlice.toString();
    }

    function extractFrom(string memory str, string memory needleStart) external pure returns(string memory) {
        strings.slice memory needleStartSlice = needleStart.toSlice();
        strings.slice memory strSlice = str.toSlice();
        strings.slice memory withoutStartSlice = strSlice
            .find(needleStartSlice)
            .beyond(needleStartSlice);
        return withoutStartSlice.toString();
    }

    function removeSuffix(string memory str, string memory suffix) external pure returns(string memory) {
        strings.slice memory strSlice = str.toSlice();
        return strSlice.until(suffix.toSlice()).toString();
    }

    function removePrefix(string memory str, string memory prefix) external pure returns(string memory) {
        strings.slice memory strSlice = str.toSlice();
        return strSlice.beyond(prefix.toSlice()).toString();
    }

}
