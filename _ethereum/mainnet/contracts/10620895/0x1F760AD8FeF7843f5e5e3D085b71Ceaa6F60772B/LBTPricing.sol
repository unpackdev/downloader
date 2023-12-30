// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/math/SignedSafeMath.sol

pragma solidity ^0.6.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Multiplies two signed integers, reverts on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Subtracts two signed integers, reverts on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Adds two signed integers, reverts on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// File: @openzeppelin/contracts/utils/SafeCast.sol

pragma solidity ^0.6.0;


/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// File: contracts/math/UseSafeMath.sol

pragma solidity ^0.6.0;





/**
 * @notice ((a - 1) / b) + 1 = (a + b -1) / b
 * for example a.add(10**18 -1).div(10**18) = a.sub(1).div(10**18) + 1
 */

library SafeMathDivRoundUp {
    using SafeMath for uint256;

    function divRoundUp(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        require(b > 0, errorMessage);
        return ((a - 1) / b) + 1;
    }

    function divRoundUp(uint256 a, uint256 b) internal pure returns (uint256) {
        return divRoundUp(a, b, "SafeMathDivRoundUp: modulo by zero");
    }
}


/**
 * @title UseSafeMath
 * @dev One can use SafeMath for not only uint256 but also uin64 or uint16,
 * and also can use SafeCast for uint256.
 * For example:
 *   uint64 a = 1;
 *   uint64 b = 2;
 *   a = a.add(b).toUint64() // `a` become 3 as uint64
 * In additionally, one can use SignedSafeMath and SafeCast.toUint256(int256) for int256.
 * In the case of the operation to the uint64 value, one need to cast the value into int256 in
 * advance to use `sub` as SignedSafeMath.sub not SafeMath.sub.
 * For example:
 *   int256 a = 1;
 *   uint64 b = 2;
 *   int256 c = 3;
 *   a = a.add(int256(b).sub(c)); // `a` become 0 as int256
 *   b = a.toUint256().toUint64(); // `b` become 0 as uint64
 */
abstract contract UseSafeMath {
    using SafeMath for uint256;
    using SafeMathDivRoundUp for uint256;
    using SafeMath for uint64;
    using SafeMathDivRoundUp for uint64;
    using SafeMath for uint16;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
}

// File: contracts/DecentralizedOTC/LBTPricing.sol

pragma solidity 0.6.6;



contract LBTPricing is UseSafeMath {
    int256 internal constant ONEE4 = 10**4;

    /**
     * @dev sqrt(365*86400) * 10^8
     */
    int256 internal constant SQRT_YEAR_E8 = 561569229926;

    /**
     * @dev sqrt(2*PI) * 10^8
     */
    int256 internal constant SQRT_2PI_E8 = 250662827;

    /**
     * @notice Calcurate the exponent of the int256 value.
     * WARNING: 10**8 is of uint256 type, but _pow(10, 8) is of int256 type.
     * @dev If y is zero, z is 1 whatever x is.
     */
    function _pow(int256 x, uint256 y) internal pure returns (int256 z) {
        z = 1;
        for (uint256 i = 0; i < y; i++) {
            z = z.mul(x);
        }
    }

    /**
     * @dev Calcurate an approximate value of the square root of x by Newton's method.
     */
    function _sqrt(int256 x) internal pure returns (int256 y) {
        require(x >= 0, "cannot calculate the square root of a negative number");
        int256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**s
     * @notice Calculate an approximate value of the logarithm of input value by
     * Taylor expansion.
     * @dev log(x + 1) = x - 1/2 x^2 + 1/3 x^3 - 1/4 x^4 + 1/5 x^5
     *                     - 1/6 x^6 + 1/7 x^7 - 1/8 x^8 + ...
     */
    function _logTaylor(int256 inputE4) internal pure returns (int256 outputE4) {
        outputE4 = 0;
        int256 sign;
        require(inputE4 < 2 * 10**4, "inputE4 < 20000 (2) is required");
        for (uint256 i = 1; i < 9; i++) {
            if (i % 2 == 0) {
                sign = -1;
            } else {
                sign = 1;
            }
            outputE4 = outputE4.add(
                _pow(inputE4, i).div(_pow(10, 4 * i - 4)).div(int256(i)).mul(sign)
            );
        }
    }

    /**
     * @notice Calculate the cumulative distribution function of standard normal
     * distribution by Taylor expansion.
     * @dev N(x)
     *    = exp(-(x^2)/2) / sqrt(2*PI)
     *    = 1/2 + (x - 1/6 x^3 + 1/40 x^5 - 1/330 x^7 + 3456 x^9 - ...)/sqrt(2*PI)
     */
    function _NTaylor(int256 inputE4) internal pure returns (int256 outputE4) {
        int256 t = inputE4
            .sub(_pow(inputE4, 3).div(6 * 10**8))
            .add(_pow(inputE4, 5).div(40 * 10**16))
            .sub(_pow(inputE4, 7).div(330 * 10**24))
            .add(_pow(inputE4, 9).div(3456 * 10**32));
        return t.mul(10**8).div(SQRT_2PI_E8).add(5 * 10**3);
    }

    /**
     * @dev
     * s := v*sqrt(t/365*86400)
     * d1 := log(S/K - 1)/s + s/2
     * d2 := d1 - ss
     * price :=
     *   | S*NTaylor(d1) - K*NTaylor(d2) (if 0.7 <= S/K <= 2 & -2 < d1 < 2 & -2 < d2 < 2)
     *   | max(S - K, 0)                 (otherwise).
     */
    function pricing(
        int256 rateETH2USDE4,
        int256 liquidStrikePriceE4,
        int256 volatility,
        int256 untilMaturity
    ) public pure returns (int256) {
        int256 pE4 = rateETH2USDE4.mul(ONEE4).div(liquidStrikePriceE4);
        int256 sigE8 = volatility.mul(_sqrt(untilMaturity)).mul(_pow(10, 8)).div(SQRT_YEAR_E8);

        if (pE4 <= 7000 || pE4 >= 20000) {
            if (liquidStrikePriceE4 < rateETH2USDE4) {
                return rateETH2USDE4.sub(liquidStrikePriceE4);
            } else {
                return 0;
            }
        }

        int256 d1E4 = _logTaylor(pE4.sub(ONEE4)).mul(10**8).div(sigE8).add(sigE8.div(2 * 10**4));
        int256 d2E4 = d1E4.sub(sigE8.div(ONEE4));

        if (d1E4 > -2 * ONEE4 && d1E4 < 2 * ONEE4 && d2E4 > -2 * ONEE4 && d2E4 < 2 * ONEE4) {
            return
                rateETH2USDE4.mul(_NTaylor(d1E4)).sub(liquidStrikePriceE4.mul(_NTaylor(d2E4))).div(
                    10**4
                );
        } else if (liquidStrikePriceE4 < rateETH2USDE4) {
            return rateETH2USDE4.sub(liquidStrikePriceE4);
        } else {
            return 0;
        }
    }
}