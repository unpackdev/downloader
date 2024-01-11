// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Buffers {
    struct Writer {
        uint256 length;
        string buffer;
    }

    bytes1 private constant _SPACE = " ";

    function getWriter(uint256 size) internal pure returns (Writer memory) {
        Writer memory writer;
        writer.buffer = new string(size);

        return writer;
    }

    function write(Writer memory writer, string memory input) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        uint256 length = bytes(input).length;

        assembly {
            for {
                let k := 0
            } lt(k, length) {

            } {
                k := add(k, 0x20)
                mstore(add(add(buffer, offset), k), mload(add(input, k)))
            }
        }

        unchecked {
            writer.length += length;
        }
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b
    ) internal pure {
        write(writer, a);
        write(writer, b);
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c
    ) internal pure {
        write(writer, a);
        write(writer, b);
        write(writer, c);
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure {
        write(writer, a);
        write(writer, b);
        write(writer, c);
        write(writer, d);
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e
    ) internal pure {
        write(writer, a);
        write(writer, b);
        write(writer, c);
        write(writer, d);
        write(writer, e);
    }

    function write(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e,
        string memory f
    ) internal pure {
        write(writer, a);
        write(writer, b);
        write(writer, c);
        write(writer, d);
        write(writer, e);
        write(writer, f);
    }

    function writeChar(Writer memory writer, bytes1 input) internal pure {
        string memory buffer = writer.buffer;

        assembly {
            mstore(add(add(buffer, mload(writer)), 0x20), input)
        }

        unchecked {
            writer.length++;
        }
    }

    function writeWord(Writer memory writer, string memory input)
        internal
        pure
    {
        string memory buffer = writer.buffer;
        uint256 length = bytes(input).length;

        assembly {
            mstore(
                add(add(buffer, mload(writer)), 0x20),
                mload(add(input, 0x20))
            )
        }

        unchecked {
            writer.length += length;
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(bufferPtr, mload(add(e, 0x20)))
            bufferPtr := add(bufferPtr, mload(e))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeWords(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e,
        string memory f
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(bufferPtr, mload(add(e, 0x20)))
            bufferPtr := add(bufferPtr, mload(e))

            mstore(bufferPtr, mload(add(f, 0x20)))
            bufferPtr := add(bufferPtr, mload(f))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeSentence(
        Writer memory writer,
        string memory a,
        string memory b
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeSentence(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function writeSentence(
        Writer memory writer,
        string memory a,
        string memory b,
        string memory c,
        string memory d,
        string memory e,
        string memory f
    ) internal pure {
        string memory buffer = writer.buffer;
        uint256 offset = writer.length;
        assembly {
            let bufferPtr := add(add(buffer, offset), 0x20)

            mstore(bufferPtr, mload(add(a, 0x20)))
            bufferPtr := add(bufferPtr, mload(a))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(b, 0x20)))
            bufferPtr := add(bufferPtr, mload(b))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(c, 0x20)))
            bufferPtr := add(bufferPtr, mload(c))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(d, 0x20)))
            bufferPtr := add(bufferPtr, mload(d))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(e, 0x20)))
            bufferPtr := add(bufferPtr, mload(e))

            mstore(bufferPtr, _SPACE)
            bufferPtr := add(bufferPtr, 1)

            mstore(bufferPtr, mload(add(f, 0x20)))
            bufferPtr := add(bufferPtr, mload(f))

            mstore(writer, sub(sub(bufferPtr, buffer), 0x20))
        }
    }

    function toString(Writer memory writer)
        internal
        pure
        returns (string memory)
    {
        string memory buffer = writer.buffer;

        assembly {
            mstore(buffer, mload(writer))
        }

        return buffer;
    }
}
