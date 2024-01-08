//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Library encapsulating logic to generate the header + palette for a bitmap.
 * 
 * Uses the "40-byte" header format, as described at
 * http://www.ece.ualberta.ca/~elliott/ee552/studentAppNotes/2003_w/misc/bmp_file_format/bmp_file_format.htm
 * 
 * Note that certain details (width, height, palette size, file size) are hardcoded
 * based off the DBN-specific assumptions of 101x101 with 101 shades of grey.
 * 
 */
library BitmapHeader {

    bytes32 internal constant HEADER1 = 0x424dd22a000000000000ca010000280000006500000065000000010008000000;
    bytes22 internal constant HEADER2 = 0x00000000000000000000000000006500000000000000;

    /**
     * @dev Writes a 458 byte bitmap header + palette to the given array
     * @param output The destination array. Gets mutated!
     */
    function writeTo(bytes memory output) internal pure {

        assembly {
            mstore(add(output, 0x20), HEADER1)
            mstore(add(output, 0x40), HEADER2)
        }

        // palette index is "DBN" color : [0, 100]
        // map that to [0, 255] via:
        // 255 - ((255 * c) / 100)
        for (uint i = 0; i < 101; i++) {
            bytes1 c = bytes1(uint8(255 - ((255 * i) / 100)));
            uint o = i*4 + 54; // after the header
            output[o] = c;
            output[o + 1] = c;
            output[o + 2] = c;
        }

        
    }
}
