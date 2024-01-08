// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.6;

abstract contract Random {
    uint256 private s_Previous = 0;

    function _random() internal returns (uint256) {
        // Oh look, random number generation on-chain. What could go wrong?

        unchecked {
            uint256 bitfield;

            for (uint ii = 1; ii < 257; ii++) {
                uint256 bits = uint256(blockhash(block.number - ii));
                bitfield |= bits & (1 << (ii - 1));
            }

            uint256 value = uint256(keccak256(abi.encodePacked(bytes32(bitfield))));
            s_Previous ^= value;

            return uint256(keccak256(abi.encodePacked(s_Previous)));
        }
    }
}