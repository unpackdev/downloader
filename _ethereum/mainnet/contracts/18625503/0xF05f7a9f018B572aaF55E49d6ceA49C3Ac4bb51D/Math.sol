// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;

library Math
{
    uint128 private constant MAX_64x64  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint128 private constant MAX_U64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @notice Cast a int128 to a uint128, revert on overflow
    /// @param y The int128 to be casted
    /// @return z The casted integer, now type uint128
    function toUint128(int128 y) internal pure returns (uint128 z) {
        unchecked
        {
            require(y >= 0);
            z = uint128(y);
        }
    }

    /// @notice Cast a uint128 to a int128, revert on overflow
    /// @param y The uint128 to be casted
    /// @return z The casted integer, now type int128
    function toInt128(uint128 y) internal pure returns (int128 z) {
        unchecked
        {
            require (y <= MAX_U64x64);
            z = int128(y);
        }
    }

    //precision 64.0 -> 64.64
    function from_uint(uint256 x) internal pure returns (uint128) 
    {
        unchecked 
        {
            require (x <= 0x7FFFFFFFFFFFFFFF);
            return uint128(x << 64);
        }
    }
     
    function div18(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
        require (y != 0);
        uint256 result = (uint256 (x) * 10**18) / y;
        require (result <= MAX_64x64);
        return uint128 (result);
        }
    }


    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x unsigned 64.64-bit fixed point number
     * @param y unsigned 64.64-bit fixed point number
     * @return unsigned 64.64-bit fixed point number
     */
    function div256(uint256 x, uint128 y) internal pure returns (uint128) {
        unchecked {
        require (y != 0);
        uint256 result = ( (x) << 64) / y;
        require (result <= MAX_64x64);
        return uint128 (result);
        }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x unsigned 64.64-bit fixed point number
     * @param y unsigned 64.64-bit fixed point number
     * @return unsigned 64.64-bit fixed point number
     */
    function mul256(uint256 x, uint128 y) internal pure returns (uint128) {
        unchecked {
        uint256 result = (x) * y >> 64;
        require (result <= MAX_64x64);
        return uint128 (result);
        }
    }


    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x unsigned 64.64-bit fixed point number
     * @param y unsigned 64.64-bit fixed point number
     * @return unsigned 64.64-bit fixed point number
     */
    function div(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
        require (y != 0);
        uint256 result = (uint256 (x) << 64) / y;
        require (result <= MAX_64x64);
        return uint128 (result);
        }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x unsigned 64.64-bit fixed point number
     * @param y unsigned 64.64-bit fixed point number
     * @return unsigned 64.64-bit fixed point number
     */
    function mul(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
        uint256 result = uint256(x) * y >> 64;
        require (result <= MAX_64x64);
        return uint128 (result);
        }
    }


    function exp_2(uint128 x) internal pure returns (uint128) 
    {
        return toUint128(exp_2(toInt128(x)));
    }

    function sqrt(uint128 x) internal pure returns (uint128) 
    {
       return sqrtu (uint256(x) << 64);
    }


    //lib

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    //  src from https://github.com/PaulRBerg/prb-math
    /// @param x0 The exponent as an unsigned 64.64-bit fixed-point number.
    /// @return result The result as an unsigned 64.64-bit  fixed-point number.
    /// @custom:smtchecker abstract-function-nondet
    function exp_2(int128 x0) internal pure returns (int128) 
    {
        unchecked {
            require (x0 < 0x400000000000000000); // Overflow
            require (x0 >= 0);
            uint256 x=uint128(x0);

            // Start from 0.5 in the 192.64-bit fixed-point format.
            uint256 result = 0x800000000000000000000000000000000000000000000000;

            // The following logic multiplies the result by $\sqrt{2^{-i}}$ when the bit at position i is 1. Key points:
            //
            // 1. Intermediate results will not overflow, as the starting point is 2^191 and all magic factors are under 2^65.
            // 2. The rationale for organizing the if statements into groups of 8 is gas savings. If the result of performing
            // a bitwise AND operation between x and any value in the array [0x80; 0x40; 0x20; 0x10; 0x08; 0x04; 0x02; 0x01] is 1,
            // we know that `x & 0xFF` is also 1.
            if (x & 0xFF00000000000000 > 0) {
                if (x & 0x8000000000000000 > 0) {
                    result = (result * 0x16A09E667F3BCC909) >> 64;
                }
                if (x & 0x4000000000000000 > 0) {
                    result = (result * 0x1306FE0A31B7152DF) >> 64;
                }
                if (x & 0x2000000000000000 > 0) {
                    result = (result * 0x1172B83C7D517ADCE) >> 64;
                }
                if (x & 0x1000000000000000 > 0) {
                    result = (result * 0x10B5586CF9890F62A) >> 64;
                }
                if (x & 0x800000000000000 > 0) {
                    result = (result * 0x1059B0D31585743AE) >> 64;
                }
                if (x & 0x400000000000000 > 0) {
                    result = (result * 0x102C9A3E778060EE7) >> 64;
                }
                if (x & 0x200000000000000 > 0) {
                    result = (result * 0x10163DA9FB33356D8) >> 64;
                }
                if (x & 0x100000000000000 > 0) {
                    result = (result * 0x100B1AFA5ABCBED61) >> 64;
                }
            }

            if (x & 0xFF000000000000 > 0) {
                if (x & 0x80000000000000 > 0) {
                    result = (result * 0x10058C86DA1C09EA2) >> 64;
                }
                if (x & 0x40000000000000 > 0) {
                    result = (result * 0x1002C605E2E8CEC50) >> 64;
                }
                if (x & 0x20000000000000 > 0) {
                    result = (result * 0x100162F3904051FA1) >> 64;
                }
                if (x & 0x10000000000000 > 0) {
                    result = (result * 0x1000B175EFFDC76BA) >> 64;
                }
                if (x & 0x8000000000000 > 0) {
                    result = (result * 0x100058BA01FB9F96D) >> 64;
                }
                if (x & 0x4000000000000 > 0) {
                    result = (result * 0x10002C5CC37DA9492) >> 64;
                }
                if (x & 0x2000000000000 > 0) {
                    result = (result * 0x1000162E525EE0547) >> 64;
                }
                if (x & 0x1000000000000 > 0) {
                    result = (result * 0x10000B17255775C04) >> 64;
                }
            }

            if (x & 0xFF0000000000 > 0) {
                if (x & 0x800000000000 > 0) {
                    result = (result * 0x1000058B91B5BC9AE) >> 64;
                }
                if (x & 0x400000000000 > 0) {
                    result = (result * 0x100002C5C89D5EC6D) >> 64;
                }
                if (x & 0x200000000000 > 0) {
                    result = (result * 0x10000162E43F4F831) >> 64;
                }
                if (x & 0x100000000000 > 0) {
                    result = (result * 0x100000B1721BCFC9A) >> 64;
                }
                if (x & 0x80000000000 > 0) {
                    result = (result * 0x10000058B90CF1E6E) >> 64;
                }
                if (x & 0x40000000000 > 0) {
                    result = (result * 0x1000002C5C863B73F) >> 64;
                }
                if (x & 0x20000000000 > 0) {
                    result = (result * 0x100000162E430E5A2) >> 64;
                }
                if (x & 0x10000000000 > 0) {
                    result = (result * 0x1000000B172183551) >> 64;
                }
            }

            if (x & 0xFF00000000 > 0) {
                if (x & 0x8000000000 > 0) {
                    result = (result * 0x100000058B90C0B49) >> 64;
                }
                if (x & 0x4000000000 > 0) {
                    result = (result * 0x10000002C5C8601CC) >> 64;
                }
                if (x & 0x2000000000 > 0) {
                    result = (result * 0x1000000162E42FFF0) >> 64;
                }
                if (x & 0x1000000000 > 0) {
                    result = (result * 0x10000000B17217FBB) >> 64;
                }
                if (x & 0x800000000 > 0) {
                    result = (result * 0x1000000058B90BFCE) >> 64;
                }
                if (x & 0x400000000 > 0) {
                    result = (result * 0x100000002C5C85FE3) >> 64;
                }
                if (x & 0x200000000 > 0) {
                    result = (result * 0x10000000162E42FF1) >> 64;
                }
                if (x & 0x100000000 > 0) {
                    result = (result * 0x100000000B17217F8) >> 64;
                }
            }

            if (x & 0xFF000000 > 0) {
                if (x & 0x80000000 > 0) {
                    result = (result * 0x10000000058B90BFC) >> 64;
                }
                if (x & 0x40000000 > 0) {
                    result = (result * 0x1000000002C5C85FE) >> 64;
                }
                if (x & 0x20000000 > 0) {
                    result = (result * 0x100000000162E42FF) >> 64;
                }
                if (x & 0x10000000 > 0) {
                    result = (result * 0x1000000000B17217F) >> 64;
                }
                if (x & 0x8000000 > 0) {
                    result = (result * 0x100000000058B90C0) >> 64;
                }
                if (x & 0x4000000 > 0) {
                    result = (result * 0x10000000002C5C860) >> 64;
                }
                if (x & 0x2000000 > 0) {
                    result = (result * 0x1000000000162E430) >> 64;
                }
                if (x & 0x1000000 > 0) {
                    result = (result * 0x10000000000B17218) >> 64;
                }
            }

            if (x & 0xFF0000 > 0) {
                if (x & 0x800000 > 0) {
                    result = (result * 0x1000000000058B90C) >> 64;
                }
                if (x & 0x400000 > 0) {
                    result = (result * 0x100000000002C5C86) >> 64;
                }
                if (x & 0x200000 > 0) {
                    result = (result * 0x10000000000162E43) >> 64;
                }
                if (x & 0x100000 > 0) {
                    result = (result * 0x100000000000B1721) >> 64;
                }
                if (x & 0x80000 > 0) {
                    result = (result * 0x10000000000058B91) >> 64;
                }
                if (x & 0x40000 > 0) {
                    result = (result * 0x1000000000002C5C8) >> 64;
                }
                if (x & 0x20000 > 0) {
                    result = (result * 0x100000000000162E4) >> 64;
                }
                if (x & 0x10000 > 0) {
                    result = (result * 0x1000000000000B172) >> 64;
                }
            }

            if (x & 0xFF00 > 0) {
                if (x & 0x8000 > 0) {
                    result = (result * 0x100000000000058B9) >> 64;
                }
                if (x & 0x4000 > 0) {
                    result = (result * 0x10000000000002C5D) >> 64;
                }
                if (x & 0x2000 > 0) {
                    result = (result * 0x1000000000000162E) >> 64;
                }
                if (x & 0x1000 > 0) {
                    result = (result * 0x10000000000000B17) >> 64;
                }
                if (x & 0x800 > 0) {
                    result = (result * 0x1000000000000058C) >> 64;
                }
                if (x & 0x400 > 0) {
                    result = (result * 0x100000000000002C6) >> 64;
                }
                if (x & 0x200 > 0) {
                    result = (result * 0x10000000000000163) >> 64;
                }
                if (x & 0x100 > 0) {
                    result = (result * 0x100000000000000B1) >> 64;
                }
            }

            if (x & 0xFF > 0) {
                if (x & 0x80 > 0) {
                    result = (result * 0x10000000000000059) >> 64;
                }
                if (x & 0x40 > 0) {
                    result = (result * 0x1000000000000002C) >> 64;
                }
                if (x & 0x20 > 0) {
                    result = (result * 0x10000000000000016) >> 64;
                }
                if (x & 0x10 > 0) {
                    result = (result * 0x1000000000000000B) >> 64;
                }
                if (x & 0x8 > 0) {
                    result = (result * 0x10000000000000006) >> 64;
                }
                if (x & 0x4 > 0) {
                    result = (result * 0x10000000000000003) >> 64;
                }
                if (x & 0x2 > 0) {
                    result = (result * 0x10000000000000001) >> 64;
                }
                if (x & 0x1 > 0) {
                    result = (result * 0x10000000000000001) >> 64;
                }
            }

            result >>= 127 - (x >> 64);

            require (result <= uint256 (int256 (0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)));

            return int128 (int256 (result));

        }
    }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt0 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x4) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

