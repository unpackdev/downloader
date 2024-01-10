// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

library RevertUtils {
    /// Reverts, forwarding the return data from the last external call.
    /// If there was no preceding external call, reverts with empty returndata.
    /// It's up to the caller to ensure that the preceding call actually reverted - if it did not,
    /// the return data will come from a successfull call.
    ///
    /// @dev This function writes to arbitrary memory locations, violating any assumptions the compiler
    /// might have about memory use. This may prevent it from doing some kinds of memory optimizations
    /// planned in future versions or make them unsafe. It's recommended to obtain the revert data using 
    /// the try/catch statement and rethrow it with `rawRevert()` instead.
    function forwardRevert() internal pure {
        assembly {
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }

    /// Reverts, directly setting the return data from the provided `bytes` object.
    /// Unlike the high-level `revert` statement, this allows forwarding the revert data obtained from
    /// a failed external call (high-level `revert` would wrap it in an `Error`).
    ///
    /// @dev This function is recommended over `forwardRevert()` because it does not interfere with
    /// the memory allocation mechanism used by the compiler.
    function rawRevert(bytes memory revertData) internal pure {
        assembly {
            // NOTE: `bytes` arrays in memory start with a 32-byte size slot, which is followed by data.
            let revertDataStart := add(revertData, 32)
            let revertDataEnd := add(revertDataStart, mload(revertData))
            revert(revertDataStart, revertDataEnd)
        }
    }
}
