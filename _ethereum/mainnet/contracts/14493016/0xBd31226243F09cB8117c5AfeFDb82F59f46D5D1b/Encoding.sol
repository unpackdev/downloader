// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Base64.sol";

library Encoding {

    function encode(int32[] memory prices) internal pure returns (string memory) {
        uint256 encodedLen = prices.length * 3;

        // Round up to the nearest length divisible by 4. Otherwise it's not a valid base64 string
        if (encodedLen % 4 > 0) {
            encodedLen += (4 - (encodedLen % 4));
        }
        bytes memory data = new bytes(encodedLen);
        uint80 i;

        for (i = 0; i < prices.length; i++) {
            int32 price = prices[i];
            
            int32 lgByte = (price >> 12) % 64;
            int32 medByte = (price >> 6) % 64;
            int32 smByte = price % 64;

            data[3*i] = Base64.TABLE[uint32(lgByte)];
            data[3*i + 1] = Base64.TABLE[uint32(medByte)];
            data[3*i + 2] = Base64.TABLE[uint32(smByte)];
        }  
        for (i = uint80(3*prices.length); i < encodedLen; i++) {
            data[i] = '='; // ASCII '='
        }
        return string(data);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}