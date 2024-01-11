// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256) {
        return _mulDiv(a, b, denominator, true);
    }

    function mulDivCeil(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256) {
        return _mulDiv(a, b, denominator, false);
    }

    /// @notice Calculates a×b÷denominator with full precision then rounds accorrding to `roundDown`. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @param roundDown if true, round towards negative infinity; if false, round towards positive infinity
    /// @return The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function _mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator,
        bool roundDown
    ) private pure returns (uint256) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        uint256 remainder; // Remainder of full-precision division
        assembly ("memory-safe") {
            // Full-precision multiplication
            {
                let mm := mulmod(a, b, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            remainder := mulmod(a, b, denominator)

            if and(sub(roundDown, 1), remainder) {
                // Make division exact by rounding [prod1 prod0] up to a
                // multiple of denominator
                let addend := sub(denominator, remainder)
                // Add 256 bit number to 512 bit number
                prod0 := add(prod0, addend)
                prod1 := add(prod1, lt(prod0, addend))
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            if iszero(gt(denominator, prod1)) {
                // selector for `Panic(uint256)`
                mstore(0x00, 0x4e487b71)
                // 0x11 -> overflow; 0x12 -> division by zero
                mstore(0x20, add(0x11, iszero(denominator)))
                revert(0x1c, 0x24)
            }
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            uint256 result;
            assembly ("memory-safe") {
                result := div(prod0, denominator)
            }
            return result;
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        uint256 inv;
        assembly ("memory-safe") {
            if roundDown {
                // Make division exact by rounding [prod1 prod0] down to a
                // multiple of denominator
                // Subtract 256 bit number from 512 bit number
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            {
                // Compute largest power of two divisor of denominator.
                // Always >= 1.
                let twos := and(sub(0, denominator), denominator)

                // Divide denominator by power of two
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by the factors of two
                prod0 := div(prod0, twos)
                // Shift in bits from prod1 into prod0. For this we need
                // to flip `twos` such that it is 2**256 / twos.
                // If twos is zero, then it becomes one
                twos := add(div(sub(0, twos), twos), 1)
                prod0 := or(prod0, mul(prod1, twos))
            }

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            inv := xor(mul(3, denominator), 2)

            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**8
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**16
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**32
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**64
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**128
            inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**256
        }

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        unchecked {
            return prod0 * inv;
        }
    }

    struct uint512 {
      uint256 l;
      uint256 h;
    }

    // Adapted from: https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
    function mulAdd(uint512 memory x, uint256 y, uint256 z) internal pure {
      unchecked {
        uint256 l = y * z;
        uint256 mm = mulmod(y, z, type(uint256).max);
        uint256 h = mm - l;
        x.l += l;
        if (l > x.l) h++;
        if (mm < l) h--;
        x.h += h;
      }
    }

    function _msb(uint256 x) private pure returns (uint256 r) {
        unchecked {
            require (x > 0);
            if (x >= 2**128) {
                x >>= 128;
                r += 128;
            }
            if (x >= 2**64) {
                x >>= 64;
                r += 64;
            }
            if (x >= 2**32) {
                x >>= 32;
                r += 32;
            }
            if (x >= 2**16) {
                x >>= 16;
                r += 16;
            }
            if (x >= 2**8) {
                x >>= 8;
                r += 8;
            }
            if (x >= 2**4) {
                x >>= 4;
                r += 4;
            }
            if (x >= 2**2) {
                x >>= 2;
                r += 2;
            }
            if (x >= 2**1) {
                x >>= 1;
                r += 1;
            }
        }
    }

    function div(uint512 memory x, uint256 y) internal pure returns (uint256 r) {
        uint256 l = x.l;
        uint256 h = x.h;
        require (h < y);
        unchecked {
            uint256 yShift = _msb(y);
            uint256 shiftedY = y;
            if (yShift <= 127) {
                yShift = 0;
            } else {
                yShift -= 127;
                shiftedY = (shiftedY - 1 >> yShift) + 1;
            }
            while (h > 0) {
                uint256 lShift = _msb(h) + 1;
                uint256 hShift = 256 - lShift;
                uint256 e = ((h << hShift) + (l >> lShift)) / shiftedY;
                if (lShift > yShift) {
                    e <<= (lShift - yShift);
                } else {
                    e >>= (yShift - lShift);
                }
                r += e;

                uint256 tl;
                uint256 th;
                {
                    uint256 mm = mulmod(e, y, type(uint256).max);
                    tl = e * y;
                    th = mm - tl;
                    if (mm < tl) {
                        th -= 1;
                    }
                }

                h -= th;
                if (tl > l) {
                    h -= 1;
                }
                l -= tl;
            }
            r += l / y;
        }
    }
}
