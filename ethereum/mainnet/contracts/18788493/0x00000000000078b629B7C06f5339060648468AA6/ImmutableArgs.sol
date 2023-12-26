// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.15;

/// @title ImmutableArgs
/// @author zefram.eth, Saw-mon & Natalie
/// @notice Provides helper functions for reading immutable args from calldata
library ImmutableArgs {
    function addr() internal pure returns (address arg) {
        assembly {
            arg := shr(0x60, calldataload(sub(calldatasize(), 22)))
        }
    }

    /// @notice Reads an immutable arg with type address
    /// @param offset The offset of the arg in the packed data
    /// @return arg The arg value
    function addressAt(uint256 offset) internal pure returns (address arg) {
        uint256 start = _startOfImmutableArgs();
        assembly {
            arg := shr(0x60, calldataload(add(start, offset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param offset The offset of the arg in the packed data
    /// @return arg The arg value
    function uint256At(uint256 offset) internal pure returns (uint256 arg) {
        uint256 start = _startOfImmutableArgs();
        assembly {
            arg := calldataload(add(start, offset))
        }
    }

    function all() internal pure returns (bytes memory args) {
        uint256 start = _startOfImmutableArgs();
        unchecked {
            args = msg.data[start:msg.data.length - 2];
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _startOfImmutableArgs() private pure returns (uint256 offset) {
        assembly {
            //                                      read final 2 bytes of calldata, i.e. `extraLength`
            offset := sub(calldatasize(), shr(0xf0, calldataload(sub(calldatasize(), 2))))
        }
    }
}
