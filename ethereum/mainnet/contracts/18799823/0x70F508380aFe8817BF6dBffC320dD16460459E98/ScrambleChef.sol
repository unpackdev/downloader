// SPDX-License-Identifier: MIT
import "./Ownable.sol";
import "./SafeERC20.sol";

import "./IUniswapV2Router02.sol";
import "./IScramble.sol";
import "./IFullProtec.sol";
import "./IWhite.sol";
import "./IUniswapV2Pair.sol";

/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <mikhail.vladimirov@gmail.com>
 */
pragma solidity 0.8.19;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromInt(int256 x) internal pure returns (int128) {
        unchecked {
            require(x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
            return int128(x << 64);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64-bit integer number
     */
    function toInt(int128 x) internal pure returns (int64) {
        unchecked {
            return int64(x >> 64);
        }
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function fromUInt(uint256 x) internal pure returns (int128) {
        unchecked {
            require(x <= 0x7FFFFFFFFFFFFFFF);
            return int128(int256(x << 64));
        }
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return unsigned 64-bit integer number
     */
    function toUInt(int128 x) internal pure returns (uint64) {
        unchecked {
            require(x >= 0);
            return uint64(uint128(x >> 64));
        }
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function from128x128(int256 x) internal pure returns (int128) {
        unchecked {
            int256 result = x >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 128.128 fixed point number
     */
    function to128x128(int128 x) internal pure returns (int256) {
        unchecked {
            return int256(x) << 64;
        }
    }

    /**
     * Calculate x + y.  Revert on overflow.
     * The
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function add(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) + y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sub(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = int256(x) - y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function mul(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 result = (int256(x) * y) >> 64;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
     * @param y signed 256-bit integer number
     * @return signed 256-bit integer number
     */
    function muli(int128 x, int256 y) internal pure returns (int256) {
        unchecked {
            if (x == MIN_64x64) {
                require(
                    y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                        && y <= 0x1000000000000000000000000000000000000000000000000
                );
                return -y << 63;
            } else {
                bool negativeResult = false;
                if (x < 0) {
                    x = -x;
                    negativeResult = true;
                }
                if (y < 0) {
                    y = -y; // We rely on overflow behavior here
                    negativeResult = !negativeResult;
                }
                uint256 absoluteResult = mulu(x, uint256(y));
                if (negativeResult) {
                    require(absoluteResult <= 0x8000000000000000000000000000000000000000000000000000000000000000);
                    return -int256(absoluteResult); // We rely on overflow behavior here
                } else {
                    require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                    return int256(absoluteResult);
                }
            }
        }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     * beginning
     * @param x signed 64.64 fixed point number
     * @param y unsigned 256-bit integer number
     * @return unsigned 256-bit integer number
     */
    function mulu(int128 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) return 0;

            require(x >= 0);

            uint256 lo = (uint256(int256(x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
            uint256 hi = uint256(int256(x)) * (y >> 128);

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            hi <<= 64;

            require(hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
            return hi + lo;
        }
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function div(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            int256 result = (int256(x) << 64) / y;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
     * @param y signed 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divi(int256 x, int256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);

            bool negativeResult = false;
            if (x < 0) {
                x = -x; // We rely on overflow behavior here
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint128 absoluteResult = divuu(uint256(x), uint256(y));
            if (negativeResult) {
                require(absoluteResult <= 0x80000000000000000000000000000000);
                return -int128(absoluteResult); // We rely on overflow behavior here
            } else {
                require(absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(absoluteResult); // We rely on overflow behavior here
            }
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return signed 64.64-bit fixed point number
     */
    function divu(uint256 x, uint256 y) internal pure returns (int128) {
        unchecked {
            require(y != 0);
            uint128 result = divuu(x, y);
            require(result <= uint128(MAX_64x64));
            return int128(result);
        }
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function neg(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return -x;
        }
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function abs(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != MIN_64x64);
            return x < 0 ? -x : x;
        }
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function inv(int128 x) internal pure returns (int128) {
        unchecked {
            require(x != 0);
            int256 result = int256(0x100000000000000000000000000000000) / x;
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function avg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            return int128((int256(x) + int256(y)) >> 1);
        }
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function gavg(int128 x, int128 y) internal pure returns (int128) {
        unchecked {
            int256 m = int256(x) * int256(y);
            require(m >= 0);
            require(m < 0x4000000000000000000000000000000000000000000000000000000000000000);
            return int128(sqrtu(uint256(m)));
        }
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @param y uint256 value
     * @return signed 64.64-bit fixed point number
     */
    function pow(int128 x, uint256 y) internal pure returns (int128) {
        unchecked {
            bool negative = x < 0 && y & 1 == 1;

            uint256 absX = uint128(x < 0 ? -x : x);
            uint256 absResult;
            absResult = 0x100000000000000000000000000000000;

            if (absX <= 0x10000000000000000) {
                absX <<= 63;
                while (y != 0) {
                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x2 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x4 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    if (y & 0x8 != 0) {
                        absResult = (absResult * absX) >> 127;
                    }
                    absX = (absX * absX) >> 127;

                    y >>= 4;
                }

                absResult >>= 64;
            } else {
                uint256 absXShift = 63;
                if (absX < 0x1000000000000000000000000) {
                    absX <<= 32;
                    absXShift -= 32;
                }
                if (absX < 0x10000000000000000000000000000) {
                    absX <<= 16;
                    absXShift -= 16;
                }
                if (absX < 0x1000000000000000000000000000000) {
                    absX <<= 8;
                    absXShift -= 8;
                }
                if (absX < 0x10000000000000000000000000000000) {
                    absX <<= 4;
                    absXShift -= 4;
                }
                if (absX < 0x40000000000000000000000000000000) {
                    absX <<= 2;
                    absXShift -= 2;
                }
                if (absX < 0x80000000000000000000000000000000) {
                    absX <<= 1;
                    absXShift -= 1;
                }

                uint256 resultShift = 0;
                while (y != 0) {
                    require(absXShift < 64);

                    if (y & 0x1 != 0) {
                        absResult = (absResult * absX) >> 127;
                        resultShift += absXShift;
                        if (absResult > 0x100000000000000000000000000000000) {
                            absResult >>= 1;
                            resultShift += 1;
                        }
                    }
                    absX = (absX * absX) >> 127;
                    absXShift <<= 1;
                    if (absX >= 0x100000000000000000000000000000000) {
                        absX >>= 1;
                        absXShift += 1;
                    }

                    y >>= 1;
                }

                require(resultShift < 64);
                absResult >>= 64 - resultShift;
            }
            int256 result = negative ? -int256(absResult) : int256(absResult);
            require(result >= MIN_64x64 && result <= MAX_64x64);
            return int128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     * of
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function sqrt(int128 x) internal pure returns (int128) {
        unchecked {
            require(x >= 0);
            return int128(sqrtu(uint256(int256(x)) << 64));
        }
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function log_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return int128(int256((uint256(int256(log_2(x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128));
        }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp_2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            uint256 result = 0x80000000000000000000000000000000;

            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDEC) >> 128;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A791F) >> 128;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F6298B92B71842A98363) >> 128;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE7C548EB68CA417FD) >> 128;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8) >> 128;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D84A66AE336DCDFA3F) >> 128;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9543) >> 128;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679B) >> 128;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC506D21BFC89A23A00F) >> 128;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA128BCA9C55C31E5DF) >> 128;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA38E31671CA939725) >> 128;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D6CACD4B180917C3D) >> 128;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9491D0985C348C68E7B3) >> 128;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE054754457D5995292026) >> 128;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C040618BF4A4ADE83FC) >> 128;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB) >> 128;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9) >> 128;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1628) >> 128;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F016468F6BAC5CA2B) >> 128;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A18F6119E3C02282A5) >> 128;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B1721835514B86E6D96EFD1BFE) >> 128;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B48C6BE5DF846C5B2EF) >> 128;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC6B9E94213C72737A) >> 128;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF037DF38AA2B219F06) >> 128;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBA9C739AA5819F44F9) >> 128;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC823) >> 128;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE31F35A6A30DA1BE50) >> 128;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF0999CE3541B9FFFCF) >> 128;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFBF8479BD5A81B51AD) >> 128;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FDF84BD62AE30A74CC) >> 128;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F7D5A7716BBA4A9AE) >> 128;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90BFBE9DDBAC5E109CCE) >> 128;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0D) >> 128;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17217F7D20CF927C8E94C) >> 128;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90BFBE8F71CB4E4B33D) >> 128;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C85FDF477B662B26945) >> 128;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E42FEFA3AE53369388C) >> 128;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B17217F7D1D351A389D40) >> 128;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDE) >> 128;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C85FDF4741BEA6E77E) >> 128;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E42FEFA39FE95583C2) >> 128;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B17217F7D1CFB72B45E1) >> 128;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B90BFBE8E7CC35C3F0) >> 128;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5C85FDF473E242EA38) >> 128;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000162E42FEFA39EF44D91) >> 128;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000058B90BFBE8E7BCE544) >> 128;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x100000000000000058B90BFBE8E7BCD6D) >> 128;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000002C5C85FDF473DE6B2) >> 128;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x1000000000000000162E42FEFA39EF358) >> 128;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000000B17217F7D1CF79AB) >> 128;
            }

            result >>= uint256(int256(63 - (x >> 64)));
            require(result <= uint256(int256(MAX_64x64)));

            return int128(int256(result));
        }
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     * his
     * @param x signed 64.64-bit fixed point number
     * @return signed 64.64-bit fixed point number
     */
    function exp(int128 x) internal pure returns (int128) {
        unchecked {
            require(x < 0x400000000000000000); // Overflow

            if (x < -0x400000000000000000) return 0; // Underflow

            return exp_2(int128((int256(x) * 0x171547652B82FE1777D0FFDA0D23A7D12) >> 128));
        }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
     * @param y unsigned 256-bit integer number
     * @return unsigned 64.64-bit fixed point number
     */
    function divuu(uint256 x, uint256 y) private pure returns (uint128) {
        unchecked {
            require(y != 0);

            uint256 result;

            if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) {
                result = (x << 64) / y;
            } else {
                uint256 msb = 192;
                uint256 xc = x >> 192;
                if (xc >= 0x100000000) {
                    xc >>= 32;
                    msb += 32;
                }
                if (xc >= 0x10000) {
                    xc >>= 16;
                    msb += 16;
                }
                if (xc >= 0x100) {
                    xc >>= 8;
                    msb += 8;
                }
                if (xc >= 0x10) {
                    xc >>= 4;
                    msb += 4;
                }
                if (xc >= 0x4) {
                    xc >>= 2;
                    msb += 2;
                }
                if (xc >= 0x2) msb += 1; // No need to shift xc anymore

                result = (x << (255 - msb)) / (((y - 1) >> (msb - 191)) + 1);
                require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 hi = result * (y >> 128);
                uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

                uint256 xh = x >> 192;
                uint256 xl = x << 64;

                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here
                lo = hi << 128;
                if (xl < lo) xh -= 1;
                xl -= lo; // We rely on overflow behavior here

                assert(xh == hi >> 128);

                result += xl / y;
            }

            require(result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return uint128(result);
        }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
     * @return unsigned 128-bit integer number
     */
    function sqrtu(uint256 x) private pure returns (uint128) {
        unchecked {
            if (x == 0) {
                return 0;
            } else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) {
                    xx >>= 128;
                    r <<= 64;
                }
                if (xx >= 0x10000000000000000) {
                    xx >>= 64;
                    r <<= 32;
                }
                if (xx >= 0x100000000) {
                    xx >>= 32;
                    r <<= 16;
                }
                if (xx >= 0x10000) {
                    xx >>= 16;
                    r <<= 8;
                }
                if (xx >= 0x100) {
                    xx >>= 8;
                    r <<= 4;
                }
                if (xx >= 0x10) {
                    xx >>= 4;
                    r <<= 2;
                }
                if (xx >= 0x8) {
                    r <<= 1;
                }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return uint128(r < r1 ? r : r1);
            }
        }
    }
}

// File: contracts/ScrambleChef.sol
import "./ERC20.sol";

pragma solidity 0.8.19;

contract ScrambleChef is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 lockEndedTimestamp;
    }
    //
    //   pending reward = (user.amount * pool.accRewardPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accRewardPerShare` (and `lastRewardTimestamp`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that Rewards distribution occurs.
        uint256 accRewardPerShare; // Accumulated Rewards per share.
    }

    // SCRAMBLE
    IScramble public scramble;
    // SCRAMBLE LP address
    IUniswapV2Pair public scrambleLp;
    // WHITE pool
    IFullProtec public fullProtec;
    // WHITE token
    IWhite public white;

    // SCRAMBLE tokens reward per block.
    uint256 public rewardPerSecond;
    // We cap daily debase rate to -50% so things don't go out of control
    uint256 public dailyDebaseRateHardCap = 50e18;
    // Rebase start time
    uint256 public lastTimestamp;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // user's withdrawable rewards
    mapping(uint256 => mapping(address => uint256)) private userRewards;
    // Lock duration in seconds
    mapping(uint256 => uint256) public lockDurations;
    // user's accumulated xp
    mapping(address => uint256) public xpAccumulated;
    // tracks block when user last made scramble
    mapping(address => uint256) public lastClaimedBlock;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when SCRAMBLE mining starts.
    uint256 public startTimestamp;

    mapping(uint256 => uint256) public totalStakedInPool;

    // Events
    event Deposit(address indexed user, uint256 indexed pid, uint256 indexed amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 indexed amount);
    event RewardPaid(address indexed user, uint256 indexed pid, uint256 indexed amount);
    event LogRewardPerSecond(uint256 amount);
    event LogPoolAddition(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken);
    event LogSetPool(uint256 indexed pid, uint256 allocPoint);
    event LogUpdatePool(uint256 indexed pid, uint256 lastRewardTimestamp, uint256 lpSupply, uint256 accRewardPerShare);
    event LogSetLockDuration(uint256 indexed pid, uint256 lockDuration);

    constructor() {
        scramble = IScramble(0x63b420fb3294BA1d300CE5D3ba4BBCA0F4fe5e3b);
        white = IWhite(0x7a38aFa395666799b3DbFe22C0d1467feC931Bb0);
        fullProtec = IFullProtec(0x400aFbc1bBa6E8fF4462D161f7DC24e4873D4eBB);
        scrambleLp = IUniswapV2Pair(0xeD7985385bF434F0815AA9C90450945aEE02d733);
        rewardPerSecond = 10e18;
        startTimestamp = block.timestamp;
        lastTimestamp = block.timestamp;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Set the lock duration for a pool
    // The lock duration is the number of seconds the user's tokens will be locked
    // after staking. The user will not be able to unstake until the lock
    // duration has passed.
    function setLockDuration(uint256 _pid, uint256 _lockDuration) external onlyOwner {
        lockDurations[_pid] = _lockDuration;
        emit LogSetLockDuration(_pid, _lockDuration);
    }

    // Update the rewards per second
    // This is the amount of reward token that is distributed to each user
    // per second.
    function updateRewardPerSecond(uint256 _rewardPerSecond) external onlyOwner {
        massUpdatePools();
        rewardPerSecond = _rewardPerSecond;
        emit LogRewardPerSecond(_rewardPerSecond);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardTimestamp: lastRewardTimestamp,
                accRewardPerShare: 0
            })
        );

        emit LogPoolAddition(poolInfo.length - 1, _allocPoint, _lpToken);
    }

    // Update the given pool's SCRAMBLE allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) external onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit LogSetPool(_pid, _allocPoint);
    }

    // View function to see pending Scramble on frontend.
    function pendingReward(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 accRewardPerShare = pool.accRewardPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (address(pool.lpToken) == address(scramble)) {
            lpSupply = scramble.balanceOfUnderlying(address(this));
        }
        if (block.timestamp > pool.lastRewardTimestamp && lpSupply != 0) {
            uint256 scrambleReward =
                ((block.timestamp - pool.lastRewardTimestamp) * rewardPerSecond * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare += (scrambleReward * 1e12) / lpSupply;
        }
        return userRewards[_pid][_user] + (user.amount * accRewardPerShare) / 1e12 - user.rewardDebt;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTimestamp) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 scrambleReward =
            ((block.timestamp - pool.lastRewardTimestamp) * rewardPerSecond * pool.allocPoint) / totalAllocPoint;
        pool.accRewardPerShare += (scrambleReward * 1e12) / lpSupply;
        pool.lastRewardTimestamp = block.timestamp;

        emit LogUpdatePool(_pid, pool.lastRewardTimestamp, lpSupply, pool.accRewardPerShare);
    }

    // Deposit tokens to ScrambleChef for SCRAMBLE allocation.
    function deposit(uint256 _pid, uint256 _amount, address _account) external {
        if (_pid == 0) {
            require(msg.sender == address(fullProtec), "Not allowed");
        } else {
            require(
                msg.sender == _account || msg.sender == address(this) || msg.sender == address(fullProtec),
                "You can't deposit for someone else"
            );
        }

        require(_amount > 0, "Deposit amount can't be zero");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        user.lockEndedTimestamp = block.timestamp + lockDurations[_pid];

        updatePool(_pid);
        queueRewards(_pid, _account);

        if (address(pool.lpToken) == address(white)) {
            pool.lpToken.safeTransferFrom(address(fullProtec), address(this), _amount);
            totalStakedInPool[_pid] += _amount;
        } else {
            pool.lpToken.safeTransferFrom(_account, address(this), _amount);
            totalStakedInPool[_pid] += _amount;
        }

        emit Deposit(_account, _pid, _amount);

        user.amount += _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;
    }

    // Withdraw tokens from ScrambleChef.
    function withdraw(uint256 _pid, uint256 _amount, address _account) external {
        if (_pid == 0) {
            require(msg.sender == address(fullProtec), "Not allowed");
        } else {
            require(
                msg.sender == _account || msg.sender == address(this) || msg.sender == address(fullProtec),
                "You can't withdraw for someone else"
            );
        }
        require(_amount > 0, "Withdraw amount can't be zero");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_account];
        require(user.lockEndedTimestamp <= block.timestamp, "Still locked");
        require(user.amount >= _amount, "You can't withdraw that much");

        updatePool(_pid);
        queueRewards(_pid, _account);

        user.amount -= _amount;
        user.rewardDebt = (user.amount * pool.accRewardPerShare) / 1e12;

        if (address(pool.lpToken) == address(white)) {
            pool.lpToken.safeTransfer(address(fullProtec), _amount);
            totalStakedInPool[_pid] -= _amount;
            // _amount = scramble.scrambleToFragment(_amount);
        } else {
            pool.lpToken.safeTransfer(address(_account), _amount);
            totalStakedInPool[_pid] -= _amount;
        }

        emit Withdraw(_account, _pid, _amount);
    }

    function makeScramble(address _account) external {
        require(msg.sender == _account || msg.sender == address(this), "You can't claim for someone else");

        uint256 stakedPool0 = userInfo[0][_account].amount;
        uint256 stakedPool1 = userInfo[1][_account].amount;

        if (stakedPool0 == 0 && stakedPool1 == 0) {
            require(stakedPool0 > 0 && stakedPool1 > 0, "Can't make scramble without WHITE or YOLK");
        }

        // upgrades logic
        if (lastClaimedBlock[_account] == 0) {
            lastClaimedBlock[_account] = block.number - 1000;
        }

        xpAccumulated[_account] += getPendingXp(_account);
        xpAccumulated[_account] += getPendingBonusXp(_account);

        lastClaimedBlock[_account] = block.number;

        uint256 bonusRewards = 0;
        // claim from upgrades
        if (getPendingBonusRewards(_account) > 0) {
            bonusRewards = getPendingBonusRewards(_account);
        }
        // claim both pools
        claim(0, _account);
        claim(1, _account);

        if (bonusRewards > 0) {
            scramble.mint(_account, bonusRewards);
        }
    }

    function claim(uint256 _pid, address _account) internal returns (uint256) {
        require(msg.sender == _account || msg.sender == address(this), "You can't claim for someone else");
        updatePool(_pid);
        queueRewards(_pid, _account);

        uint256 pending = userRewards[_pid][_account];

        if (pending > 0) {
            UserInfo storage user = userInfo[_pid][_account];
            user.lockEndedTimestamp = block.timestamp + lockDurations[_pid];

            userRewards[_pid][_account] = 0;
            userInfo[_pid][_account].rewardDebt =
                (userInfo[_pid][_account].amount * poolInfo[_pid].accRewardPerShare) / (1e12);

            if (lastTimestamp != block.timestamp) {
                uint256 secs = block.timestamp - lastTimestamp;
                if (block.timestamp - lastTimestamp > 1 days) {
                    secs = 1 days;
                }
                lastTimestamp = block.timestamp;
                scramble.rebase(block.timestamp, getDebaseRate() * secs, false);
                scrambleLp.sync();
            }

            scramble.mint(_account, pending);

            emit RewardPaid(_account, _pid, pending);

            return pending;
        } else {
            return 0;
        }
    }

    // Queue rewards - increase pending rewards
    function queueRewards(uint256 _pid, address _account) internal {
        UserInfo memory user = userInfo[_pid][_account];
        uint256 pending = (user.amount * poolInfo[_pid].accRewardPerShare) / (1e12) - user.rewardDebt;
        if (pending > 0) {
            userRewards[_pid][_account] += pending;
        }
    }

    function getDebaseRate() public view returns (uint256) {
        if (fullProtec.getPercentSupplyStaked() >= dailyDebaseRateHardCap) {
            return (dailyDebaseRateHardCap * 1e16) / 1e18 / 86400;
        } else {
            return (fullProtec.getPercentSupplyStaked() * 1e16) / 1e18 / 86400;
        }
    }

    function setDailyDebaseRateHardCap(uint256 _dailyDebaseRateHardCap) public onlyOwner {
        dailyDebaseRateHardCap = _dailyDebaseRateHardCap;
    }

    function setWhiteVaultAddress(address _fullProtec) public onlyOwner {
        fullProtec = IFullProtec(_fullProtec);
    }

    function emergencyWithdraw(address lpToken, uint amount) public onlyOwner {
        IERC20(lpToken).transfer(owner(), amount);
    }

    /*
        Upgrades
    */

    mapping(address => uint256) public claimMultiplierLevel;
    mapping(address => uint256) public xpMultiplierLevel;

    function upgradeScrambleMultiplier(address _account) public {
        require(msg.sender == _account || msg.sender == address(this), "You can't upgrade for someone else");
        uint256 upgradePrice = getClaimMultiplierUpgradePrice(_account);
        require(xpAccumulated[_account] >= upgradePrice, "Not enough XP");
        xpAccumulated[_account] -= upgradePrice;
        claimMultiplierLevel[_account] += 1;
    }

    function upgradeXpMultiplier(address _account) public {
        require(msg.sender == _account || msg.sender == address(this), "You can't upgrade for someone else");
        uint256 upgradePrice = getXpMultiplierUpgradePrice(_account);
        require(xpAccumulated[_account] >= upgradePrice, "Not enough XP");
        xpAccumulated[_account] -= upgradePrice;
        xpMultiplierLevel[_account] += 1;
    }

    function getClaimMultiplierUpgradePrice(address _account) public view returns (uint256) {
        return claimMultiplierLevel[_account] * 1000 + 1000;
    }

    function getXpMultiplierUpgradePrice(address _account) public view returns (uint256) {
        return xpMultiplierLevel[_account] * 1000 + 1000;
    }

    function getPendingBonusRewards(address _account) public view returns (uint256) {
        uint256 pending0 = pendingReward(0, _account);
        uint256 pending1 = pendingReward(1, _account);
        uint256 total = pending0 + pending1;
        uint256 bonus = (total * claimMultiplierLevel[_account] * 10) / 100;
        return bonus;
    }

    function getPendingXp(address _account) public view returns (uint256) {
        uint256 _lastClaimedBlock;
        if (lastClaimedBlock[_account] == 0) {
            _lastClaimedBlock = block.number - 1000;
        } else {
            _lastClaimedBlock = lastClaimedBlock[_account];
        }
        return block.number - _lastClaimedBlock;
    }

    function getPendingBonusXp(address _account) public view returns (uint256) {
        return (getPendingXp(_account) * (xpMultiplierLevel[_account] * 10)) / 100;
    }
}
