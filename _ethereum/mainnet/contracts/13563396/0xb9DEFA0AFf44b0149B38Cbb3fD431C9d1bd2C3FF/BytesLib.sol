// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
    
    function toUint256(bytes memory _bytes, uint _start) internal pure returns (uint) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toTuple128(bytes memory _bytes, uint256 _start) internal pure returns (uint, uint) {
        require(_bytes.length >= _start + 32, "toTuple16_outOfBounds");
        uint tempUint;
        uint n1;
        uint n2;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
            n1 := and(shr(0x80, tempUint), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            n2 := and(tempUint, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }

        return (n1, n2);
    }
}