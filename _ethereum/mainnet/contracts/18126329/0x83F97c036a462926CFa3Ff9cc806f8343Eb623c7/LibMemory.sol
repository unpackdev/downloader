// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

library LibMemory {
    /// Returns true if the free memory pointer is pointing at a multiple of 32
    /// bytes, false otherwise. If all memory allocations are handled by Solidity
    /// then this will always be true, but assembly blocks can violate this, so
    /// this is a useful tool to test compliance of a custom assembly block with
    /// the solidity allocator.
    /// @return isAligned true if the memory is currently aligned to 32 bytes.
    function memoryIsAligned() internal pure returns (bool isAligned) {
        assembly ("memory-safe") {
            isAligned := iszero(mod(mload(0x40), 0x20))
        }
    }
}
