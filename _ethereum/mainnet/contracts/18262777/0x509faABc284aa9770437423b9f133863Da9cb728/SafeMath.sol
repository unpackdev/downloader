// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

abstract contract SafeMath {
    error AmountExceedBits();
    error AmountOverflow();
    error AmountUnderflow();

    function safe96(uint256 n) internal pure returns (uint96) {
        if (n > 2 ** 96) revert AmountExceedBits();
        return uint96(n);
    }

    function sub96(uint96 a, uint96 b) internal pure returns (uint96) {
        unchecked {
            if (b > a) revert AmountUnderflow();
            return a - b;
        }
    }
}
