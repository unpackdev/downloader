// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

/// @title Utilities
/// @author charchar.eth
/// @notice Central location for shared functions in me3
library Utilities {
    /// @notice Hash a label for ENS use
    /// @param label The 'oops' in 'oops.bob.eth', or the 'bob' in 'bob.eth'
    /// @return Hashed label
    function labelhash(string memory label) internal pure returns (bytes32) {
        return keccak256(bytes(label));
    }

    /// @notice Create a namehash, the combination of a namehashed node and a hashed label
    /// @param node Fully qualified, namehashed ENS name ('bob.eth')
    /// @param label The 'oops' in 'oops.bob.eth', or the 'bob' in 'bob.eth'
    /// @return Hashed ENS name
    function namehash(bytes32 node, bytes32 label)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(node, label));
    }
}
