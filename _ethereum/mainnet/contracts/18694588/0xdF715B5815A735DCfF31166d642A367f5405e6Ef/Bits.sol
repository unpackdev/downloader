// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Bits {
    /**
     * @dev unpack bit [offset] (bool)
     */
    function getBool(bytes32 p, uint8 offset) internal pure returns (bool r) {
        assembly {
            r := and(shr(offset, p), 1)
        }
    }

    /**
     * @dev unpack 8 bits [offset...offset+8] uint8
     */
    function getUint8(bytes32 p, uint8 offset) internal pure returns(uint8 r) {
        assembly {
            r := and(shr(offset, p), 0xFF)
        }
    }

    /**
     * @dev unpack 16 bits [offset...offset+16] uint16
     */
    function getUint16(bytes32 p, uint8 offset) internal pure returns(uint16 r) {
        assembly {
            r := and(shr(offset, p), 0xFFFF)
        }
    }

    /**
     * @dev unpack 32 bits [offset...offset+32] uint32
     */
    function getUint32(bytes32 p, uint8 offset) internal pure returns(uint32 r) {
        assembly {
            r := and(shr(offset, p), 0xFFFFFFFF)
        }
    }

    /**
     * @dev unpack 64 bits [offset...offset+64] uint64
     */
    function getUint64(bytes32 p, uint8 offset) internal pure returns(uint64 r) {
        assembly {
            r := and(shr(offset, p), 0xFFFFFFFFFFFFFFFF)
        }
    }

    /**
     * @dev unpack 128 bits [offset...offset+96] uint96
     */
    function getUint128(bytes32 p, uint8 offset) internal pure returns(uint128 r) {
        assembly {
            r := and(shr(offset, p), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        }
    }

    /**
     * @dev set bit [offset] to {value}
     */
    function setBool(
        bytes32 p,
        uint8 offset,
        bool value
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 1)
                    )
                ),
                shl(offset, value)
            )
        }
    }

    /**
     * @dev set 8bits [offset..offset+8] to {value}
     */
    function setUint8(
        bytes8 p,
        uint8 offset,
        uint8 value
    ) internal pure returns (bytes8 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 0xFF)
                    )
                ),
                shl(offset, value)
            )
        }
    }


    /**
     * @dev set 16bits [offset..offset+16] to {value}
     */
    function setUint16(
        bytes32 p,
        uint8 offset,
        uint16 value
    ) internal pure returns (bytes16 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 0xFFFF)
                    )
                ),
                shl(offset, value)
            )
        }
    }


    /**
     * @dev set 32bits [offset..offset+32] to {value}
     */
    function setUint32(
        bytes32 p,
        uint8 offset,
        uint32 value
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 0xFFFFFFFF)
                    )
                ),
                shl(offset, value)
            )
        }
    }

    /**
     * @dev set 64 bits [offset..offset+64] to {value}
     */
    function setUint64(
        bytes32 p,
        uint8 offset,
        uint64 value
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 0xFFFFFFFFFFFFFFFF)
                    )
                ),
                shl(offset, value)
            )
        }
    }

    /**
     * @dev set 128 bits [offset..offset+128] to {value}
     */
    function setUint128(
        bytes32 p,
        uint8 offset,
        uint128 value
    ) internal pure returns (bytes32 np) {
        assembly {
            np := or(
                and(
                    p,
                    xor(
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
                        shl(offset, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    )
                ),
                shl(offset, value)
            )
        }
    }
}
