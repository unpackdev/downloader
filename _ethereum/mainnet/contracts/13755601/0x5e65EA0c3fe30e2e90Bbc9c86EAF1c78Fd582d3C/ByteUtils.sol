// contracts/Utils.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./console.sol";

library ByteUtils {
    /**
    @dev Write trait roll number to bytes16 hash
    */
    function setTraitRollToHash(bytes16 _hash, uint8 _traitId, uint16 roll) internal pure returns (bytes16) {
        return (_hash & ~(bytes16(0xffff0000000000000000000000000000) >> (16+_traitId * 16))) | (bytes16(bytes2(roll)) >> (16+_traitId * 16));
    }

    /**
    @dev Get trait roll number from bytes16 hash
    */
    function getTraitRollFromHash(bytes16 _hash, uint8 _traitId) internal pure returns (uint16) {
        uint16 number;
        uint8 start_pos=2+_traitId*2;
        number = uint16(uint8(_hash[start_pos])*(2**(8)) + uint8(_hash[start_pos+1]));
        return number;
    }

    /**
    @dev Write byte to bytes9 hash
    */
    function setPackedHashByte(bytes9 _hash, uint _index, bytes1 _byte) internal pure returns (bytes9) {
        return (_hash & ~(bytes9(0xff0000000000000000) >> (_index * 8))) | (bytes9(_byte) >> (_index * 8));
    }

    /**
    @dev Write byte to bytes16 hash
    */
    function setHashByte(bytes16 _hash, uint _index, bytes1 _byte) internal pure returns (bytes16) {
        return (_hash & ~(bytes16(0xff000000000000000000000000000000) >> (_index * 8))) | (bytes16(_byte) >> (_index * 8));
    }
}