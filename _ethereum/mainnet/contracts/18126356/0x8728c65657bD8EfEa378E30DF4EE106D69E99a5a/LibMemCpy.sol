// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

import "./LibPointer.sol";

library LibMemCpy {
    /// Copy an arbitrary number of bytes from one location in memory to another.
    /// As we can only read/write bytes in 32 byte chunks we first have to loop
    /// over 32 byte values to copy then handle any unaligned remaining data. The
    /// remaining data will be appropriately masked with the existing data in the
    /// final chunk so as to not write past the desired length. Note that the
    /// final unaligned write will be more gas intensive than the prior aligned
    /// writes. The writes are completely unsafe, the caller MUST ensure that
    /// sufficient memory is allocated and reading/writing the requested number
    /// of bytes from/to the requested locations WILL NOT corrupt memory in the
    /// opinion of solidity or other subsequent read/write operations.
    /// @param sourceCursor The starting pointer to read from.
    /// @param targetCursor The starting pointer to write to.
    /// @param length The number of bytes to read/write.
    function unsafeCopyBytesTo(Pointer sourceCursor, Pointer targetCursor, uint256 length) internal pure {
        assembly ("memory-safe") {
            // Precalculating the end here, rather than tracking the remaining
            // length each iteration uses relatively more gas for less data, but
            // scales better for more data. Copying 1-2 words is ~30 gas more
            // expensive but copying 3+ words favours a precalculated end point
            // increasingly for more data.
            let m := mod(length, 0x20)
            let end := add(sourceCursor, sub(length, m))
            for {} lt(sourceCursor, end) {
                sourceCursor := add(sourceCursor, 0x20)
                targetCursor := add(targetCursor, 0x20)
            } { mstore(targetCursor, mload(sourceCursor)) }

            if iszero(iszero(m)) {
                //slither-disable-next-line incorrect-shift
                let mask_ := shr(mul(m, 8), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                // preserve existing bytes
                mstore(
                    targetCursor,
                    or(
                        // input
                        and(mload(sourceCursor), not(mask_)),
                        and(mload(targetCursor), mask_)
                    )
                )
            }
        }
    }

    /// Copies `length` `uint256` values starting from `source` to `target`
    /// with NO attempt to check that this is safe to do so. The caller MUST
    /// ensure that there exists allocated memory at `target` in which it is
    /// safe and appropriate to copy `length * 32` bytes to. Anything that was
    /// already written to memory at `[target:target+(length * 32 bytes)]`
    /// will be overwritten.
    /// There is no return value as memory is modified directly.
    /// @param source The starting position in memory that data will be copied
    /// from.
    /// @param target The starting position in memory that data will be copied
    /// to.
    /// @param length The number of 32 byte (i.e. `uint256`) words that will
    /// be copied.
    function unsafeCopyWordsTo(Pointer source, Pointer target, uint256 length) internal pure {
        assembly ("memory-safe") {
            for { let end_ := add(source, mul(0x20, length)) } lt(source, end_) {
                source := add(source, 0x20)
                target := add(target, 0x20)
            } { mstore(target, mload(source)) }
        }
    }
}
