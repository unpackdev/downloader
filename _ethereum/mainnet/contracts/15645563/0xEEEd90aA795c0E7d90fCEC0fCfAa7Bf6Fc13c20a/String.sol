// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

library String {
    function append(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

     function stringToBytes32(string memory source)
        internal
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    function trim(string memory symbol)
        internal
        pure
        returns (string memory, uint256)
    {
        bytes memory _s = bytes(symbol);
        uint256 a = _s.length;
        for (uint256 i = 0; i < a; i++) {
            if (
                keccak256(abi.encodePacked(_s[0])) ==
                keccak256(abi.encodePacked(" "))
            ) {
                symbol = _substring(symbol, _s.length - 1, 1);
                _s = bytes(symbol);
            } else {
                break;
            }
        }
        a = _s.length - 1;
        for (uint256 i = a; i > 0; i--) {
            if (
                keccak256(abi.encodePacked(_s[i])) ==
                keccak256(abi.encodePacked(" "))
            ) {
                symbol = _substring(symbol, i, 0);
                _s = bytes(symbol);
            } else {
                break;
            }
        }
        return (symbol, _s.length);
    }

    function _substring(
        string memory _base,
        uint256 _length,
        uint256 _offset
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint256(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint256(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint256 j = 0;
        for (
            uint256 i = uint256(_offset);
            i < uint256(_offset + _length);
            i++
        ) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }
}
