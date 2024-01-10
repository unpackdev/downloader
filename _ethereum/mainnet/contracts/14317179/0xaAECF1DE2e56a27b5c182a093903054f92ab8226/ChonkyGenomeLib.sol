// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ChonkyGenomeLib {
    function parseGenome(uint256 _genome)
        internal
        pure
        returns (uint256[12] memory result)
    {
        assembly {
            mstore(result, sub(_genome, shl(5, shr(5, _genome))))

            mstore(
                add(result, 0x20),
                sub(shr(5, _genome), shl(3, shr(8, _genome)))
            )

            mstore(
                add(result, 0x40),
                sub(shr(8, _genome), shl(4, shr(12, _genome)))
            )

            mstore(
                add(result, 0x60),
                sub(shr(12, _genome), shl(5, shr(17, _genome)))
            )

            mstore(
                add(result, 0x80),
                sub(shr(17, _genome), shl(4, shr(21, _genome)))
            )

            mstore(
                add(result, 0xA0),
                sub(shr(21, _genome), shl(4, shr(25, _genome)))
            )

            mstore(
                add(result, 0xC0),
                sub(shr(25, _genome), shl(7, shr(32, _genome)))
            )

            mstore(
                add(result, 0xE0),
                sub(shr(32, _genome), shl(6, shr(38, _genome)))
            )

            mstore(
                add(result, 0x100),
                sub(shr(38, _genome), shl(6, shr(44, _genome)))
            )

            mstore(
                add(result, 0x120),
                sub(shr(44, _genome), shl(7, shr(51, _genome)))
            )

            mstore(
                add(result, 0x140),
                sub(shr(51, _genome), shl(3, shr(54, _genome)))
            )

            mstore(add(result, 0x160), shr(54, _genome))
        }
    }

    function formatGenome(uint256[12] memory _attributes)
        internal
        pure
        returns (uint256 genome)
    {
        genome =
            (_attributes[0]) +
            (_attributes[1] << 5) +
            (_attributes[2] << 8) +
            (_attributes[3] << 12) +
            (_attributes[4] << 17) +
            (_attributes[5] << 21) +
            (_attributes[6] << 25) +
            (_attributes[7] << 32) +
            (_attributes[8] << 38) +
            (_attributes[9] << 44) +
            (_attributes[10] << 51) +
            (_attributes[11] << 54);
    }
}
