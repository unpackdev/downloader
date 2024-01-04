pragma solidity 0.6.6;

// File: contracts/bondPricer/Enums.sol



/**
    Pure SBT:
        ___________
       /
      /
     /
    /

    LBT Shape:
              /
             /
            /
           /
    ______/

    SBT Shape:
              ______
             /
            /
    _______/

    Triangle:
              /\
             /  \
            /    \
    _______/      \________
 */
enum BondType {NONE, PURE_SBT, SBT_SHAPE, LBT_SHAPE, TRIANGLE}

// File: @openzeppelin/contracts/math/SafeMath.sol



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
 * In addition, one can use SignedSafeMath and SafeCast.toUint256(int256) for int256.
 * In the case of the operation to the uint64 value, one needs to cast the value into int256 in
 * advance to use `sub` as SignedSafeMath.sub not SafeMath.sub.
 * For example:
 *   int256 a = 1;
 *   uint64 b = 2;
 *   int256 c = 3;
 *   a = a.add(int256(b).sub(c)); // `a` becomes 0 as int256
 *   b = a.toUint256().toUint64(); // `b` becomes 0 as uint64
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

// File: contracts/math/AdvancedMath.sol



abstract contract AdvancedMath {
    /**
     * @dev sqrt(2*PI) * 10^8
     */
    int256 internal constant SQRT_2PI_E8 = 250662827;
    int256 internal constant PI_E8 = 314159265;
    int256 internal constant E_E8 = 271828182;
    int256 internal constant INV_E_E8 = 36787944; // 1/e
    int256 internal constant LOG2_E8 = 30102999;
    int256 internal constant LOG3_E8 = 47712125;

    int256 internal constant p = 23164190;
    int256 internal constant b1 = 31938153;
    int256 internal constant b2 = -35656378;
    int256 internal constant b3 = 178147793;
    int256 internal constant b4 = -182125597;
    int256 internal constant b5 = 133027442;

    /**
     * @dev Calcurate an approximate value of the square root of x by Babylonian method.
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

    /**
     * @dev Returns log(x) for any positive x.
     */
    function _logTaylor(int256 inputE4) internal pure returns (int256 outputE4) {
        require(inputE4 > 1, "input should be positive number");
        int256 inputE8 = inputE4 * 10**4;
        // input x for _logTayler1 is adjusted to 1/e < x < 1.
        while (inputE8 < INV_E_E8) {
            inputE8 = (inputE8 * E_E8) / 10**8;
            outputE4 -= 10**4;
        }
        while (inputE8 > 10**8) {
            inputE8 = (inputE8 * INV_E_E8) / 10**8;
            outputE4 += 10**4;
        }
        outputE4 += _logTaylor1(inputE8 / 10**4 - 10**4);
    }

    /**
     * @notice Calculate an approximate value of the logarithm of input value by
     * Taylor expansion around 1.
     * @dev log(x + 1) = x - 1/2 x^2 + 1/3 x^3 - 1/4 x^4 + 1/5 x^5
     *                     - 1/6 x^6 + 1/7 x^7 - 1/8 x^8 + ...
     */
    function _logTaylor1(int256 inputE4) internal pure returns (int256 outputE4) {
        outputE4 =
            inputE4 -
            inputE4**2 /
            (2 * 10**4) +
            inputE4**3 /
            (3 * 10**8) -
            inputE4**4 /
            (4 * 10**12) +
            inputE4**5 /
            (5 * 10**16) -
            inputE4**6 /
            (6 * 10**20) +
            inputE4**7 /
            (7 * 10**24) -
            inputE4**8 /
            (8 * 10**28);
    }

    /**
     * @notice Calculate the cumulative distribution function of standard normal
     * distribution.
     * @dev Abramowitz and Stegun, Handbook of Mathematical Functions (1964)
     * http://people.math.sfu.ca/~cbm/aands/
     */
    function _calcPnorm(int256 inputE4) internal pure returns (int256 outputE8) {
        require(inputE4 < 440 * 10**4 && inputE4 > -440 * 10**4, "input is too large");
        int256 _inputE4 = inputE4 > 0 ? inputE4 : inputE4 * (-1);
        int256 t = 10**16 / (10**8 + (p * _inputE4) / 10**4);
        int256 X2 = (inputE4 * inputE4) / 2;
        int256 exp2X2 = 10**8 +
            X2 +
            (X2**2 / (2 * 10**8)) +
            (X2**3 / (6 * 10**16)) +
            (X2**4 / (24 * 10**24)) +
            (X2**5 / (120 * 10**32)) +
            (X2**6 / (720 * 10**40));
        int256 Z = (10**24 / exp2X2) / SQRT_2PI_E8;
        int256 y = (b5 * t) / 10**8;
        y = ((y + b4) * t) / 10**8;
        y = ((y + b3) * t) / 10**8;
        y = ((y + b2) * t) / 10**8;
        y = 10**8 - (Z * ((y + b1) * t)) / 10**16;
        return inputE4 > 0 ? y : 10**8 - y;
    }
}

// File: contracts/bondPricer/GeneralizedPricing.sol






/**
 * @dev The decimals of price, point, spotPrice and strikePrice are all the same.
 */
contract GeneralizedPricing is UseSafeMath, AdvancedMath {
    /**
     * @dev sqrt(365*86400) * 10^8
     */
    int256 internal constant SQRT_YEAR_E8 = 5615.69229926 * 10**8;

    int256 internal constant MIN_ND1_E8 = 0.0001 * 10**8;
    int256 internal constant MAX_ND1_E8 = 0.9999 * 10**8;
    uint256 internal constant MAX_LEVERAGE_E8 = 1000 * 10**8;

    /**
     * @notice Calculate bond price and leverage by black-scholes formula.
     * @param bondType type of target bond.
     * @param points coodinates of polyline which is needed for price calculation
     * @param untilMaturity Remaining period of target bond in second
     **/
    function calcPriceAndLeverage(
        BondType bondType,
        uint256[] memory points,
        int256 spotPrice,
        int256 volatilityE8,
        int256 untilMaturity
    ) public pure returns (uint256 price, uint256 leverageE8) {
        if (bondType == BondType.LBT_SHAPE) {
            (price, leverageE8) = _calcLbtShapePriceAndLeverage(
                points,
                spotPrice,
                volatilityE8,
                untilMaturity
            );
        } else if (bondType == BondType.SBT_SHAPE) {
            (price, leverageE8) = _calcSbtShapePrice(
                points,
                spotPrice,
                volatilityE8,
                untilMaturity
            );
        } else if (bondType == BondType.TRIANGLE) {
            (price, leverageE8) = _calcTrianglePrice(
                points,
                spotPrice,
                volatilityE8,
                untilMaturity
            );
        } else if (bondType == BondType.PURE_SBT) {
            (price, leverageE8) = _calcPureSBTPrice(
                points,
                spotPrice,
                volatilityE8,
                untilMaturity
            );
        }
    }

    /**
     * @notice Calculate pure call option price and multiply incline of LBT.
     **/

    function _calcLbtShapePriceAndLeverage(
        uint256[] memory points,
        int256 spotPrice,
        int256 volatilityE8,
        int256 untilMaturity
    ) internal pure returns (uint256 price, uint256 leverageE8) {
        require(
            points.length == 3,
            "3 coordinates is needed for LBT price calculation"
        );
        uint256 inclineE8 = (points[2].mul(10**8)).div(
            points[1].sub(points[0])
        );
        (uint256 callOptionPriceE8, int256 nd1E8) = calcCallOptionPrice(
            spotPrice,
            int256(points[0]),
            volatilityE8,
            untilMaturity
        );
        price = (callOptionPriceE8 * inclineE8) / 10**8;
        leverageE8 = _calcLbtLeverage(
            uint256(spotPrice),
            price,
            (nd1E8 * int256(inclineE8)) / 10**8
        );
    }

    /**
     * @notice Calculate (etherPrice - call option price at strike price of SBT).
     **/
    function _calcPureSBTPrice(
        uint256[] memory points,
        int256 spotPrice,
        int256 volatilityE8,
        int256 untilMaturity
    ) internal pure returns (uint256 price, uint256 leverageE8) {
        require(
            points.length == 1,
            "1 coordinate is needed for pure SBT price calculation"
        );
        (uint256 callOptionPrice1, int256 nd1E8) = calcCallOptionPrice(
            spotPrice,
            int256(points[0]),
            volatilityE8,
            untilMaturity
        );
        price = uint256(spotPrice) > callOptionPrice1
            ? (uint256(spotPrice) - callOptionPrice1)
            : 0;
        leverageE8 = _calcLbtLeverage(uint256(spotPrice), price, 10**8 - nd1E8);
    }

    /**
     * @notice Calculate (call option1  - call option2) * incline of SBT.

              ______                 /
             /                      /
            /          =           /        -                   /
    _______/               _______/                 ___________/
    SBT SHAPE BOND         CALL OPTION 1            CALL OPTION 2
     **/
    function _calcSbtShapePrice(
        uint256[] memory points,
        int256 spotPrice,
        int256 volatilityE8,
        int256 untilMaturity
    ) internal pure returns (uint256 price, uint256 leverageE8) {
        require(
            points.length == 3,
            "3 coordinates is needed for SBT price calculation"
        );
        uint256 inclineE8 = (points[2].mul(10**8)).div(
            points[1].sub(points[0])
        );
        (uint256 callOptionPrice1, int256 nd11E8) = calcCallOptionPrice(
            spotPrice,
            int256(points[0]),
            volatilityE8,
            untilMaturity
        );
        (uint256 callOptionPrice2, int256 nd12E8) = calcCallOptionPrice(
            spotPrice,
            int256(points[1]),
            volatilityE8,
            untilMaturity
        );
        price = callOptionPrice1 > callOptionPrice2
            ? (inclineE8 * (callOptionPrice1 - callOptionPrice2)) / 10**8
            : 0;
        leverageE8 = _calcLbtLeverage(
            uint256(spotPrice),
            price,
            (int256(inclineE8) * (nd11E8 - nd12E8)) / 10**8
        );
    }

    /**
      * @notice Calculate (call option1 * left incline) - (call option2 * (left incline + right incline)) + (call option3 * right incline).

                                                                   /
                                                                  /
                                                                 /
              /\                            /                    \
             /  \                          /                      \
            /    \            =           /     -                  \          +
    _______/      \________       _______/               _______    \             __________________
                                                                     \                          \
                                                                      \                          \

    **/
    function _calcTrianglePrice(
        uint256[] memory points,
        int256 spotPrice,
        int256 volatilityE8,
        int256 untilMaturity
    ) internal pure returns (uint256 price, uint256 leverageE8) {
        require(
            points.length == 4,
            "4 coordinates is needed for triangle option price calculation"
        );
        uint256 incline1E8 = (points[2].mul(10**8)).div(
            points[1].sub(points[0])
        );
        uint256 incline2E8 = (points[2].mul(10**8)).div(
            points[3].sub(points[1])
        );
        (uint256 callOptionPrice1, int256 nd11E8) = calcCallOptionPrice(
            spotPrice,
            int256(points[0]),
            volatilityE8,
            untilMaturity
        );
        (uint256 callOptionPrice2, int256 nd12E8) = calcCallOptionPrice(
            spotPrice,
            int256(points[1]),
            volatilityE8,
            untilMaturity
        );
        (uint256 callOptionPrice3, int256 nd13E8) = calcCallOptionPrice(
            spotPrice,
            int256(points[3]),
            volatilityE8,
            untilMaturity
        );
        int256 nd1E8 = ((nd11E8 * int256(incline1E8)) +
            (nd13E8 * int256(incline2E8)) -
            (int256(incline1E8 + incline2E8) * nd12E8)) / 10**8;

        uint256 price12 = (callOptionPrice1 * incline1E8) +
            (callOptionPrice3 * incline2E8);
        price = price12 > (incline1E8 + incline2E8) * callOptionPrice2
            ? (price12 - ((incline1E8 + incline2E8) * callOptionPrice2)) / 10**8
            : 0;
        leverageE8 = _calcLbtLeverage(uint256(spotPrice), price, nd1E8);
    }

    /**
     * @dev calcCallOptionPrice() imposes the restrictions of strikePrice, spotPrice, nd1E8 and nd2E8.
     */
    function _calcLbtPrice(
        int256 spotPrice,
        int256 strikePrice,
        int256 nd1E8,
        int256 nd2E8
    ) internal pure returns (int256 lbtPrice) {
        int256 lowestPrice = (spotPrice > strikePrice)
            ? spotPrice - strikePrice
            : 0;
        lbtPrice = (spotPrice * nd1E8 - strikePrice * nd2E8) / 10**8;
        if (lbtPrice < lowestPrice) {
            lbtPrice = lowestPrice;
        }
    }

    /**
     * @dev calcCallOptionPrice() imposes the restrictions of spotPrice, lbtPrice and nd1E8.
     */
    function _calcLbtLeverage(
        uint256 spotPrice,
        uint256 lbtPrice,
        int256 nd1E8
    ) internal pure returns (uint256 lbtLeverageE8) {
        int256 modifiedNd1E8 = nd1E8 < MIN_ND1_E8
            ? MIN_ND1_E8
            : nd1E8 > MAX_ND1_E8
            ? MAX_ND1_E8
            : nd1E8;
        return
            lbtPrice != 0
                ? (uint256(modifiedNd1E8) * spotPrice) / lbtPrice
                : MAX_LEVERAGE_E8;
    }

    /**
     * @notice Calculate pure call option price and N(d1) by black-scholes formula.
     * @param spotPrice is a oracle price.
     * @param strikePrice Strike price of call option
     * @param volatilityE8 is a oracle volatility.
     * @param untilMaturity Remaining period of target bond in second
     **/
    function calcCallOptionPrice(
        int256 spotPrice,
        int256 strikePrice,
        int256 volatilityE8,
        int256 untilMaturity
    ) public pure returns (uint256 price, int256 nd1E8) {
        require(
            spotPrice > 0 && spotPrice < 10**13,
            "oracle price should be between 0 and 10^13"
        );
        require(
            volatilityE8 > 0 && volatilityE8 < 10 * 10**8,
            "oracle volatility should be between 0% and 1000%"
        );
        require(
            untilMaturity > 0 && untilMaturity < 31536000,
            "the bond should not have expired and less than 1 year"
        );
        require(
            strikePrice > 0 && strikePrice < 10**13,
            "strike price should be between 0 and 10^13"
        );

        int256 spotPerStrikeE4 = (spotPrice * 10**4) / strikePrice;
        int256 sigE8 = (volatilityE8 * (_sqrt(untilMaturity)) * (10**8)) /
            SQRT_YEAR_E8;

        int256 logSigE4 = _logTaylor(spotPerStrikeE4);
        int256 d1E4 = ((logSigE4 * 10**8) / sigE8) + (sigE8 / (2 * 10**4));
        nd1E8 = _calcPnorm(d1E4);

        int256 d2E4 = d1E4 - (sigE8 / 10**4);
        int256 nd2E8 = _calcPnorm(d2E4);
        price = uint256(_calcLbtPrice(spotPrice, strikePrice, nd1E8, nd2E8));
    }
}