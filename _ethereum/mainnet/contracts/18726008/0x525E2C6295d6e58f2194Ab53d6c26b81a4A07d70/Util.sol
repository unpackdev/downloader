// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Util {
    function startsWithPrefix(
        bytes memory data,
        bytes memory prefix
    ) internal pure returns (bool) {
        if (data.length < prefix.length) {
            return false;
        }

        for (uint i = 0; i < prefix.length; i++) {
            if (data[i] != prefix[i]) {
                return false;
            }
        }

        return true;
    }

    function bytesToAddress(
        bytes memory _bs
    ) internal pure returns (address addr) {
        require(_bs.length == 20, "bytes length does not match address");
        assembly {
            // for _bs, first word store _bs.length, second word store _bs.value
            // load 32 bytes from mem[_bs+20], convert it into Uint160, meaning we take last 20 bytes as addr (address).
            addr := mload(add(_bs, 0x14)) // data within slot is lower-order aligned: https://stackoverflow.com/questions/66819732/state-variables-in-storage-lower-order-aligned-what-does-this-sentence-in-the
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory tempBytes) {
        require(_bytes.length >= (_start + _length));

        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)

                let lengthmod := and(_length, 31)
                let iz := iszero(lengthmod)

                let mc := add(add(tempBytes, lengthmod), mul(0x20, iz))
                let end := add(mc, _length)

                for {
                    let cc := add(
                        add(add(_bytes, lengthmod), mul(0x20, iz)),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }
                mstore(tempBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }
    }
}
