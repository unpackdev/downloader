// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library BytesLib {
    function writeAddress(
        bytes memory _data,
        uint256 _offset,
        address _address
    ) internal pure {
        assembly {
            let pos := add(_data, add(_offset, 20))
            let neighbor := and(
                mload(pos),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )
            mstore(
                pos,
                xor(
                    neighbor,
                    and(_address, 0xffffffffffffffffffffffffffffffffffffffff)
                )
            )
        }
    }

    function writeUInt8(
        bytes memory _data,
        uint256 _offset,
        uint256 _uint8
    ) internal pure {
        assembly {
            let pos := add(_data, add(_offset, 1))
            let neighbor := and(
                mload(pos),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
            )

            mstore(pos, xor(neighbor, and(_uint8, 0xff)))
        }
    }

    function writeUInt256(
        bytes memory _data,
        uint256 _offset,
        uint256 _uint256
    ) internal pure {
        assembly {
            let pos := add(_data, add(_offset, 32))
            mstore(pos, _uint256)
        }
    }

    function writeUInt16(
        bytes memory _data,
        uint256 _offset,
        uint256 _uint16
    ) internal pure {
        assembly {
            let pos := add(_data, add(_offset, 2))
            let neighbor := and(
                mload(pos),
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0000
            )

            mstore(pos, xor(neighbor, and(_uint16, 0xffff)))
        }
    }

    function readAddress(
        bytes memory _data,
        uint256 _offset
    ) internal pure returns (address _address) {
        assembly {
            _address := and(
                mload(add(_data, add(_offset, 20))),
                0xffffffffffffffffffffffffffffffffffffffff
            )
        }
    }

    function readUInt256(
        bytes memory _data,
        uint256 _offset
    ) internal pure returns (uint256 _uint256) {
        assembly {
            _uint256 := mload(add(_data, add(_offset, 32)))
        }
    }

    function readUInt16(
        bytes memory _data,
        uint256 _offset
    ) internal pure returns (uint256 _uint16) {
        assembly {
            _uint16 := and(mload(add(_data, add(_offset, 2))), 0xffff)
        }
    }

    function readUInt8(
        bytes memory _data,
        uint256 _offset
    ) internal pure returns (uint256 _uint8) {
        assembly {
            _uint8 := and(mload(add(_data, add(_offset, 1))), 0xff)
        }
    }
}
