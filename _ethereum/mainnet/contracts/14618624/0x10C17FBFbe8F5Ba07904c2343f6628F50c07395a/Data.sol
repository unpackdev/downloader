// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Data {
    struct Reader {
        uint256 _pos;
    }

    function set(Reader memory reader, uint256 pos)
        internal
        pure
        returns (Reader memory)
    {
        reader._pos = pos;
        return reader;
    }

    function skip(Reader memory reader, uint256 count)
        internal
        pure
        returns (Reader memory)
    {
        reader._pos += count;
        return reader;
    }

    function rewind(Reader memory reader, uint256 count)
        internal
        pure
        returns (Reader memory)
    {
        reader._pos -= count;
        return reader;
    }

    function next(Reader memory reader, bytes memory data)
        internal
        pure
        returns (bytes1)
    {
        return data[reader._pos++];
    }

    function nextUint8(Reader memory reader, bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 num;

        assembly {
            let pos := add(mload(reader), 1)
            num := and(mload(add(data, pos)), 0xFF)
            mstore(reader, pos)
        }

        return num;
    }

    function nextUint16(Reader memory reader, bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 num;

        assembly {
            let pos := add(mload(reader), 2)
            num := and(mload(add(data, pos)), 0xFFFF)
            mstore(reader, pos)
        }

        return num;
    }

    function nextUint24(Reader memory reader, bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 num;

        assembly {
            let pos := add(mload(reader), 3)
            num := and(mload(add(data, pos)), 0xFFFFFF)
            mstore(reader, pos)
        }

        return num;
    }

    function nextUint56(Reader memory reader, bytes memory data)
        internal
        pure
        returns (uint256)
    {
        uint256 num;

        assembly {
            let pos := add(mload(reader), 7)
            num := and(mload(add(data, pos)), 0xFFFFFFFFFFFFFF)
            mstore(reader, pos)
        }

        return num;
    }

    function nextString32(
        Reader memory reader,
        bytes memory data,
        uint256 length
    ) internal pure returns (string memory) {
        string memory res = new string(32);

        assembly {
            mstore(add(res, 0x20), mload(add(add(data, mload(reader)), 0x20)))
            mstore(res, length)
        }

        skip(reader, length);

        return res;
    }

    function nextUintArray(
        Reader memory reader,
        uint256 bitSize,
        bytes memory data,
        uint256 length
    ) internal pure returns (uint256[] memory) {
        uint256 byteLength = (bitSize * length + 7) >> 3;
        uint256[] memory res = new uint256[](length + 7);

        assembly {
            let resPtr := add(res, 0x20)
            let filter := shr(sub(8, bitSize), 0xFF)

            for {
                let dataPtr := add(data, mload(reader))
                let endPtr := add(dataPtr, length)
            } lt(dataPtr, endPtr) {
                resPtr := add(resPtr, 0x100)
            } {
                dataPtr := add(dataPtr, bitSize)
                let input := mload(dataPtr)
                mstore(add(resPtr, 0xE0), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0xC0), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0xA0), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x80), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x60), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x40), and(input, filter))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x20), and(input, filter))
                input := shr(bitSize, input)
                mstore(resPtr, and(input, filter))
            }

            mstore(res, length)
        }

        skip(reader, byteLength);

        return res;
    }

    function nextUintArray(
        Reader memory reader,
        uint256 bitSize,
        bytes memory data,
        uint256 length,
        uint256 offset
    ) internal pure returns (uint256[] memory) {
        uint256 byteLength = (bitSize * length + 7) >> 3;
        uint256[] memory res = new uint256[](length + 7);

        assembly {
            let resPtr := add(res, 0x20)
            let filter := shr(sub(8, bitSize), 0xFF)

            for {
                let dataPtr := add(data, mload(reader))
                let endPtr := add(dataPtr, length)
            } lt(dataPtr, endPtr) {
                resPtr := add(resPtr, 0x100)
            } {
                dataPtr := add(dataPtr, bitSize)
                let input := mload(dataPtr)
                mstore(add(resPtr, 0xE0), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0xC0), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0xA0), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x80), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x60), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x40), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(add(resPtr, 0x20), add(offset, and(input, filter)))
                input := shr(bitSize, input)
                mstore(resPtr, add(offset, and(input, filter)))
            }

            mstore(res, length)
        }

        skip(reader, byteLength);

        return res;
    }

    function nextUint3Array(
        Reader memory reader,
        bytes memory data,
        uint256 length
    ) internal pure returns (uint256[] memory) {
        uint256 byteLength = (3 * length + 7) >> 3;
        uint256[] memory res = new uint256[](length + 7);

        assembly {
            let resPtr := add(res, 0x20)

            for {
                let dataPtr := add(data, mload(reader))
                let endPtr := add(dataPtr, byteLength)
            } lt(dataPtr, endPtr) {
                resPtr := add(resPtr, 0x100)
            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resPtr, and(shr(21, input), 0x7))
                mstore(add(resPtr, 0x20), and(shr(18, input), 0x7))
                mstore(add(resPtr, 0x40), and(shr(15, input), 0x7))
                mstore(add(resPtr, 0x60), and(shr(12, input), 0x7))
                mstore(add(resPtr, 0x80), and(shr(9, input), 0x7))
                mstore(add(resPtr, 0xA0), and(shr(6, input), 0x7))
                mstore(add(resPtr, 0xC0), and(shr(3, input), 0x7))
                mstore(add(resPtr, 0xE0), and(input, 0x7))
            }

            mstore(res, length)
        }

        skip(reader, byteLength);

        return res;
    }

    function nextUint8Array(
        Reader memory reader,
        bytes memory data,
        uint256 length
    ) internal pure returns (uint256[] memory) {
        uint256[] memory res = new uint256[](length);

        assembly {
            let resPtr := add(res, 0x20)

            for {
                let dataPtr := add(data, mload(reader))
                let endPtr := add(dataPtr, length)
            } lt(dataPtr, endPtr) {
                resPtr := add(resPtr, 0x20)
            } {
                dataPtr := add(dataPtr, 1)
                mstore(resPtr, and(mload(dataPtr), 0xFF))
            }
        }

        skip(reader, length);

        return res;
    }
}
