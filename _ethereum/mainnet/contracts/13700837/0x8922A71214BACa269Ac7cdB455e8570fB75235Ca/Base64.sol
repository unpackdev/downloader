//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Helper library for base64-encoding bytes
 */
library Base64 {

    uint256 internal constant ALPHA1 = 0x4142434445464748494a4b4c4d4e4f505152535455565758595a616263646566;
    uint256 internal constant ALPHA2 = 0x6768696a6b6c6d6e6f707172737475767778797a303132333435363738392b2f;

    /**
     * @dev Encodes the given bytearray to base64
     * @param input The input data
     * @return the output data
     */
    function encode(bytes memory input) internal pure returns (bytes memory) {
        if (input.length == 0) {
            return input;
        }

        bytes memory output = new bytes(_encodedLength(input.length));

        uint remaining = input.length;

        assembly {
            let src := add(input, 0x20)
            let dst := add(output, 0x20)

            // chunk loop
            for {} gt(remaining, 0) {} {
                let chunk := shr(16, mload(src))
                let processing := 30
                let sixtetCounter := 240 // 30 * 8

                if lt(remaining, 30) {
                    processing := remaining

                    // slide right by 30–#remaining bytes (shl by 3 to get bits)
                    chunk := shr(shl(3, sub(30, remaining)), chunk)

                    // but now it needs to be nudge to the left by a few bits,
                    // to make sure total number of bits is multiple of 6
                    // 0 mod 3: nudge 0 bits
                    // 1 mod 3: nudge 4 bits
                    // 2 mod 3: nudge 2 bits
                    // we take advantage that this is the same as
                    // (v * 4) % 6
                    // this is empirically true, though I don't remember the number theory proving it
                    let nudgeBits := mulmod(remaining, 4, 6)
                    chunk := shl(nudgeBits, chunk)

                    // initial sixtet (remaining * 8 + nudge)
                    sixtetCounter := add(shl(3, remaining), nudgeBits)
                }

                remaining := sub(remaining, processing)
                src := add(src, processing)

                // byte loop
                for {} gt(sixtetCounter, 0) {} {
                    sixtetCounter := sub(sixtetCounter, 6)
                    let val := shr(sixtetCounter, and(shl(sixtetCounter, 0x3F), chunk))

                    let alpha := ALPHA1
                    if gt(val, 0x1F) {
                        alpha := ALPHA2
                        val := sub(val, 0x20)
                    }
                    let char := byte(val, alpha)
                    mstore8(dst, char)
                    dst := add(dst, 1)
                }
            }

            // padding depending on input length % 3
            switch mod(mload(input), 3)
            case 1 {
                // two pads
                mstore8(dst, 0x3D) // 0x3d is =
                mstore8(add(1, dst), 0x3D) // 0x3d is =
            }
            case 2 {
                // one pad
                mstore8(dst, 0x3D)
            }
        }

        return output;
    }

    /**
     * @dev Helper to get the length of the output data
     * 
     * Implements Ceil(inputLength / 3) * 4
     */
    function _encodedLength(uint inputLength) internal pure returns (uint) {
        return ((inputLength + 2) / 3) * 4;
    }
}
