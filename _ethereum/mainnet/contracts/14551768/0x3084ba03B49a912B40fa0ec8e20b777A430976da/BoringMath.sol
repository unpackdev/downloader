// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked { 
            require((c = a + b) >= b, "BoringMath: Add Overflow");
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked { 
            require((c = a - b) <= a, "BoringMath: Underflow");
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        unchecked { 
            require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked { 
            require(b > 0, "BoringMath: division by zero");
            return a / b;
        }
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        unchecked { 
            require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
            c = uint128(a);
        }
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        unchecked { 
            require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
            c = uint64(a);
        }
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        unchecked { 
            require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
            c = uint32(a);
        }
    }

    function to40(uint256 a) internal pure returns (uint40 c) {
        unchecked { 
            require(a <= type(uint40).max, "BoringMath: uint40 Overflow");
            c = uint40(a);
        }
    }

    function to112(uint256 a) internal pure returns (uint112 c) {
        unchecked { 
            require(a <= type(uint112).max, "BoringMath: uint112 Overflow");
            c = uint112(a);
        }
    }

    function to224(uint256 a) internal pure returns (uint224 c) {
        unchecked { 
            require(a <= type(uint224).max, "BoringMath: uint224 Overflow");
            c = uint224(a);
        }
    }

    function to208(uint256 a) internal pure returns (uint208 c) {
        unchecked { 
            require(a <= type(uint208).max, "BoringMath: uint208 Overflow");
            c = uint208(a);
        }
    }

    function to216(uint256 a) internal pure returns (uint216 c) {
        unchecked { 
            require(a <= type(uint216).max, "BoringMath: uint216 Overflow");
            c = uint216(a);
        }
    }
}
