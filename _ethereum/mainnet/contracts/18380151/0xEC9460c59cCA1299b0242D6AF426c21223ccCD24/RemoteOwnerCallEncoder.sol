// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./RemoteOwner.sol";

/// @title RemoteOwnerCallEncoder
/// @author G9 Software Inc.
/// @notice Provides an interface to encode calldata for a RemoteOwner to execute.
library RemoteOwnerCallEncoder {

    /// @notice Encodes calldata for a RemoteOwner to execute on `target`.
    /// @param target The target address that RemoteOwner will call with the given value and data
    /// @param value The value that RemoteOwner will send to `target`
    /// @param data The data that RemoteOwner will call `target` with
    /// @return The encoded calldata
    function encodeCalldata(address target, uint256 value, bytes memory data) internal pure returns (bytes memory) {
        return abi.encodeCall(
            RemoteOwner.execute,
            (
                target,
                value,
                data
            )
        );
    }
}
