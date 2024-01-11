// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.15;

import "./BytesLib.sol";

/** @author https://github.com/gregdhill **/

library Bech32 {
    using BytesLib for bytes;

    bytes constant CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";

    function polymod(uint256[] memory values) internal pure returns (uint256) {
        uint32[5] memory GENERATOR = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
        uint256 chk = 1;
        for (uint256 p = 0; p < values.length; p++) {
            uint256 top = chk >> 25;
            chk = ((chk & 0x1ffffff) << 5) ^ values[p];
            for (uint256 i = 0; i < 5; i++) {
                if ((top >> i) & 1 == 1) {
                    chk ^= GENERATOR[i];
                }
            }
        }
        return chk;
    }

    function hrpExpand(uint256[] memory hrp) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](hrp.length + hrp.length + 1);
        for (uint256 p = 0; p < hrp.length; p++) {
            ret[p] = hrp[p] >> 5;
        }
        ret[hrp.length] = 0;
        for (uint256 p = 0; p < hrp.length; p++) {
            ret[p + hrp.length + 1] = hrp[p] & 31;
        }
        return ret;
    }

    function concat(uint256[] memory left, uint256[] memory right) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](left.length + right.length);

        uint256 i = 0;
        for (; i < left.length; i++) {
            ret[i] = left[i];
        }

        uint256 j = 0;
        while (j < right.length) {
            ret[i++] = right[j++];
        }

        return ret;
    }

    function extend(
        uint256[] memory array,
        uint256 val,
        uint256 num
    ) internal pure returns (uint256[] memory) {
        uint256[] memory ret = new uint256[](array.length + num);

        uint256 i = 0;
        for (; i < array.length; i++) {
            ret[i] = array[i];
        }

        uint256 j = 0;
        while (j < num) {
            ret[i++] = val;
            j++;
        }

        return ret;
    }

    function createChecksum(uint256[] memory hrp, uint256[] memory data) internal pure returns (uint256[] memory) {
        uint256[] memory values = extend(concat(hrpExpand(hrp), data), 0, 6);
        uint256 mod = polymod(values) ^ 1;
        uint256[] memory ret = new uint256[](6);
        for (uint256 p = 0; p < 6; p++) {
            ret[p] = (mod >> (5 * (5 - p))) & 31;
        }
        return ret;
    }

    function encode(uint256[] memory hrp, uint256[] memory data) internal pure returns (bytes memory) {
        uint256[] memory combined = concat(data, createChecksum(hrp, data));

        bytes memory ret = new bytes(combined.length);
        for (uint256 p = 0; p < combined.length; p++) {
            ret[p] = CHARSET[combined[p]];
        }

        return ret;
    }

    function convert(
        uint256[] memory data,
        uint256 inBits,
        uint256 outBits
    ) internal pure returns (uint256[] memory) {
        uint256 value = 0;
        uint256 bits = 0;
        uint256 maxV = (1 << outBits) - 1;

        uint256[] memory ret = new uint256[](32);
        uint256 j = 0;
        for (uint256 i = 0; i < data.length; ++i) {
            value = (value << inBits) | data[i];
            bits += inBits;

            while (bits >= outBits) {
                bits -= outBits;
                ret[j] = (value >> bits) & maxV;
                j += 1;
            }
        }

        return ret;
    }
}
