// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library StringUtils {
    function uint2str(uint _i) internal pure returns (string memory str) {
        unchecked {
            if (_i == 0) {
                return "0";
            }

            uint j = _i;
            uint length;
            while (j != 0) {
                length++;
                j /= 10;
            }

            bytes memory bstr = new bytes(length);
            uint k = length;
            j = _i;
            while (j != 0) {
                bstr[--k] = bytes1(uint8(48 + j % 10));
                j /= 10;
            }
            
            str = string(bstr);
        }
    }

    // ONLY TO BE USED FOR 8 BIT INTS! Not specifying type to save gas
    function smallUintToString(uint _i) internal pure returns (string memory) {
        require(_i < 256, "input to big");
        unchecked {
            if (_i == 0) {
                return "0";
            }

            bytes memory bstr;

            if (_i < 10) {
                // 1 byte
                bstr = new bytes(1);

                bstr[0] = bytes1(uint8(48 + _i % 10));

            } else if (_i < 100) {
                // 2 bytes
                bstr = new bytes(2);
                bstr[1] = bytes1(uint8(48 + _i % 10));
                bstr[0] = bytes1(uint8(48 + (_i / 10) % 10));
            } else {
                // greater than 100
                bstr = new bytes(3);
                bstr[2] = bytes1(uint8(48 + _i % 10));
                bstr[1] = bytes1(uint8(48 + (_i / 10) % 10));
                bstr[0] = bytes1(uint8(48 + (_i / 100) % 10));
            }
        return string(bstr);
        }
    }


}