// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Base64 {
    bytes private constant base64stdchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory bs) internal pure returns (string memory) {
        uint256 rem = bs.length % 3;

        uint256 res_length = ((bs.length + 2) / 3) * 4;
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= bs.length; i += 3) {
            (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(
                uint8(bs[i]),
                uint8(bs[i + 1]),
                uint8(bs[i + 2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(bs[bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(bs[bs.length - 1]);
            }

            (bytes1 b0, bytes1 b1, bytes1 b2, ) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j + 1] = b1;
            if (rem == 2) {
                res[j + 2] = b2;
            }
        }

        for (uint256 k = j + rem + 1; k < res_length; k++) {
            res[k] = "=";
        }

        return string(res);
    }

    function encode3(
        uint256 a0,
        uint256 a1,
        uint256 a2
    )
        private
        pure
        returns (
            bytes1 b0,
            bytes1 b1,
            bytes1 b2,
            bytes1 b3
        )
    {
        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >> 6) & 63;
        uint256 c3 = (n) & 63;

        b0 = base64stdchars[c0];
        b1 = base64stdchars[c1];
        b2 = base64stdchars[c2];
        b3 = base64stdchars[c3];
    }
}
