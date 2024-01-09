// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library MetaDrinksUtils {
    function concatLists(uint256[] memory _list1, uint256[] memory _list2) internal pure returns (uint256[] memory result) {
        result = new uint256[](_list1.length + _list2.length);

        uint i = 0;
        for (; i < _list1.length; i++) {
            result[i] = _list1[i];
        }

        uint j = 0;
        while (j < _list2.length) {
            result[i++] = _list2[j++];
        }
    }

    function excludeFromList(string[] storage _list, uint256[] memory _exclude) internal view returns (string[] memory result) {
        uint256 curr = 0;
        result = new string[](_list.length);
        for (uint256 i = 0; i < _list.length; i++) {
            string memory value = _list[i];
            if (!isUintArrayContains(_exclude, i)) {
                result[curr++] = value;
            }
        }
    }

    function getExcludedArrayLen(string[] memory _list) internal pure returns (uint256) {
        uint256 l = 0;
        for (uint256 i = 0; i < _list.length; i++) {
            if (bytes(_list[i]).length == 0) {
                return l;
            }
            l++;
        }
        return l;
    }

    function isUintArrayContains(uint256[] memory _arr, uint256 _value) internal pure returns (bool) {
        for (uint256 i = 0; i < _arr.length; i++) {
            if (_value == _arr[i]) {
                return true;
            }
        }
        return false;
    }

    // From: https://stackoverflow.com/a/65707309/11969592
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 _len;
        while (j != 0) {
            _len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(_len);
        uint256 k = _len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function len(string memory _base) internal pure returns (uint256 l) {
        l = 0;
        uint256 baseLen = bytes(_base).length;
        uint256 ptr;
        assembly {
            ptr := add(_base, 0x20)
        }
        ptr = ptr - 31;
        uint256 end = ptr + baseLen;
        for (; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upperLetter(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    function _upperLetter(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }
        return _b1;
    }

    function reRollRandomness(uint256 _randomness, string memory _input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(uint2str(_randomness), _input)));
    }
}
