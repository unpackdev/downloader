// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title String Buffer Library
 * @author lukasz-glen
 * @dev String Buffer for Solidity.
 * Allocates a single buffer and writes data with appending functions.
 * It works well with large strings/bytes/amount of data/multiple appending.
 * Multiple appends are more gas efficient than multiple abi.encodePacked().
 * StringBuffer struct is fly weight because it uses memory pointers.
 * StringBuffer struct is valid only within a single call, cannot be stored or be passed to another contracts.
 * It uses low level memory manipulation, so some provers or other tools can fail - you must be careful.
 * It does not break solidity memory layout, but it depends on its internal memory structures.
 */
library StringBufferLib {

    struct StringBuffer {
        // a buffer, the length field is changed by finalize()
        bytes data;
        // a pointer in the memory, the current pointer for buffer writing
        uint256 pointer;
        // a pointer is the memory, the boundary pointer for buffer writing, 32 bytes margin not included
        uint256 limit;
    }

    /**
     * @dev creates a new buffer
     * it is better to start large initial length, extending a buffer actually copies byte arrays
     * the actual buffer length is length + 32, 32 bytes is the margin for safe copying
     * @param length initial buffer length
     */
    function initialize(uint256 length) internal pure returns (StringBuffer memory stringBuffer) {
        unchecked {
            bytes memory data = new bytes(length + 32);
            uint256 pointer;
            assembly {
                pointer := add(data, 0x20)
            }
            stringBuffer = StringBuffer(data, pointer, pointer + length);
        }
    }

    /**
     * @dev it sets an actual length of stringBuffer.data
     * it can be called multiple times if needed
     */
    function finalize(StringBuffer memory stringBuffer) internal pure {
        // stringBuffer.data.length = stringBuffer.pointer - beginning of stringBuffer.data
        assembly {
            mstore(mload(stringBuffer), sub(mload(add(stringBuffer, 0x20)), add(mload(stringBuffer), 0x20)))
        }
    }

    /**
     * @dev appends bytes/string to a buffer
     * the buffer is extended if needed
     * if appending a constant string not longer than 32 bytes, it is better to use appendBytesXX()
     */
    function appendBytes(StringBuffer memory stringBuffer, bytes memory newData) internal pure {
        unchecked {
            uint256 newDataLength = newData.length;
            // const value
            uint256 srcEndPointer;
            stringBuffer.pointer += newDataLength;
            // const value
            uint256 destEndPointer = stringBuffer.pointer;
            // extend buffer if the limit is exceeded
            if (destEndPointer > stringBuffer.limit) {
                // values of srcEndPointer and destEndPointer to copy a buffer
                srcEndPointer = destEndPointer - newDataLength;
                uint256 length;
                // length = previous stringBuffer.pointer - beginning of stringBuffer.data
                assembly {
                    length := sub(srcEndPointer, add(mload(stringBuffer), 0x20))
                }
                // a new data buffer, + 32 bytes of margin
                bytes memory extendedData = new bytes(2 * length + 2 * newDataLength + 32);
                assembly {
                    destEndPointer := add(add(extendedData, 0x20), length)
                }
                // copy from an old buffer to a new buffer
                // that is assumed that allocating a string of length 1 << 255 is impossible
                // the condition fails on underflows (length - 1 and length -= 32)
                // length - 1 filters out the case length == 0
                // note that this condition is not equal to length < (1 << 255), check the case length == 0
                while (length - 1 < 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                    assembly {
                        mstore(sub(destEndPointer, length), mload(sub(srcEndPointer, length)))
                    }
                    length -= 32;
                }
                destEndPointer += newDataLength;
                stringBuffer.data = extendedData;
                stringBuffer.pointer = destEndPointer;
                // stringBuffer.limit = beginning of extendedData + extendedData.length - 32;
                // 32 bytes are subtracted because of the margin at the end
                // first 32 bytes of bytes type keep length, so it is actually - 32 bytes to the length
                assembly {
                    mstore(add(stringBuffer, 0x40), add(extendedData, mload(extendedData)))
                }
            }
            assembly {
                srcEndPointer := add(add(newData, 0x20), newDataLength)
            }
            // that is assumed that allocating a string of newDataLength 1 << 255 is impossible
            // the condition fails on underflows (newDataLength - 1 and newDataLength -= 32)
            // newDataLength - 1 filters out the case newDataLength == 0
            // note that this condition is not equal to newDataLength < (1 << 255), check the case newDataLength == 0
            // copying is safe because of 32 bytes margin
            while (newDataLength - 1 < 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                assembly {
                    mstore(sub(destEndPointer, newDataLength), mload(sub(srcEndPointer, newDataLength)))
                }
                newDataLength -= 32;
            }
        }
    }

    function appendBytes32(StringBuffer memory stringBuffer, bytes32 newData) internal pure {
        // first copy data, than check limits, it is safe because of 32 bytes margin
        // mem[stringBuffer.pointer, +32] = newData
        assembly {
            mstore(mload(add(stringBuffer, 0x20)), newData)
        }
        unchecked {
            stringBuffer.pointer += 32;
            // extend buffer if the limit is exceeded
            if (stringBuffer.pointer > stringBuffer.limit) {
                // a new data buffer, + 32 bytes of margin
                bytes memory extendedData = new bytes(2 * stringBuffer.data.length + 32);
                uint256 srcEndPointer = stringBuffer.pointer;
                uint256 destEndPointer;
                uint256 length;
                // length = stringBuffer.pointer - beginning of stringBuffer.data
                assembly {
                    length := sub(srcEndPointer, add(mload(stringBuffer), 0x20))
                    destEndPointer := add(add(extendedData, 0x20), length)
                }
                // copy from an old buffer to a new buffer
                // that is assumed that allocating a string of length 1 << 255 is impossible
                // the condition fails on underflows (length - 1 and length -= 32)
                // length - 1 filters out the case length == 0
                // note that this condition is not equal to length < (1 << 255), check the case length == 0
                while (length - 1 < 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                    assembly {
                        mstore(sub(destEndPointer, length), mload(sub(srcEndPointer, length)))
                    }
                    length -= 32;
                }
                stringBuffer.data = extendedData;
                stringBuffer.pointer = destEndPointer;
                // stringBuffer.limit = beginning of extendedData + extendedData.length - 32;
                // 32 bytes are subtracted because of the margin at the end
                // first 32 bytes of bytes type keep length, so it is actually - 32 bytes to the length
                assembly {
                    mstore(add(stringBuffer, 0x40), add(extendedData, mload(extendedData)))
                }
            }
        }
    }

    /**
     * @dev it copies only first 'length' bytes of newData to stringBuffer.data
     * it is not validated that length <= 32
     * the buffer is extended if needed
     */
    function appendBytesXX(StringBuffer memory stringBuffer, bytes32 newData, uint256 newDataLength) internal pure {
        // first copy data, than check limits, it is safe because of 32 bytes margin
        // mem[stringBuffer.pointer, +32] = newData
        assembly {
            mstore(mload(add(stringBuffer, 0x20)), newData)
        }
        unchecked {
            stringBuffer.pointer += newDataLength;
            // extend buffer if the limit is exceeded
            if (stringBuffer.pointer > stringBuffer.limit) {
                // a new data buffer, + 32 bytes of margin
                bytes memory extendedData = new bytes(2 * stringBuffer.data.length + 32);
                uint256 srcEndPointer = stringBuffer.pointer;
                uint256 destEndPointer;
                uint256 length;
                // length = stringBuffer.pointer - beginning of stringBuffer.data
                assembly {
                    length := sub(srcEndPointer, add(mload(stringBuffer), 0x20))
                    destEndPointer := add(add(extendedData, 0x20), length)
                }
                // copy from an old buffer to a new buffer
                // that is assumed that allocating a string of length 1 << 255 is impossible
                // the condition fails on underflows (length - 1 and length -= 32)
                // length - 1 filters out the case length == 0
                // note that this condition is not equal to length < (1 << 255), check the case length == 0
                while (length - 1 < 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) {
                    assembly {
                        mstore(sub(destEndPointer, length), mload(sub(srcEndPointer, length)))
                    }
                    length -= 32;
                }
                stringBuffer.data = extendedData;
                stringBuffer.pointer = destEndPointer;
                // stringBuffer.limit = beginning of extendedData + extendedData.length - 32;
                // 32 bytes are subtracted because of the margin at the end
                // first 32 bytes of bytes type keep length, so it is actually - 32 bytes to the length
                assembly {
                    mstore(add(stringBuffer, 0x40), add(extendedData, mload(extendedData)))
                }
            }
        }
    }
}