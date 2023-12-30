// File: contracts/Interfaces/OracleInterface.sol

pragma solidity >=0.6.6;

interface OracleInterface {
    function latestPrice() external returns (uint256);

    function getVolatility() external returns (uint256);

    function latestId() external returns (uint256);
}

// File: contracts/Interfaces/SpreadCalculatorInterface.sol

pragma solidity >=0.6.6;


interface SpreadCalculatorInterface {
    function calculateCurrentSpread(
        uint256 _maturity,
        uint256 _strikePrice,
        OracleInterface oracle
    ) external returns (uint128);

    function calculateSpreadByAssetVolatility(OracleInterface oracle)
        external
        returns (uint128);
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

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
     *
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
     *
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
     *
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/Libraries/RateMath.sol

pragma solidity >=0.6.6;


library RateMath {
    using SafeMath for uint256;
    uint256 public constant RATE_POINT_MULTIPLIER = 1000000000000000000; // 10^18

    function getRate(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(RATE_POINT_MULTIPLIER).div(b);
    }

    function divByRate(uint256 self, uint256 rate)
        internal
        pure
        returns (uint256)
    {
        return self.mul(RATE_POINT_MULTIPLIER).div(rate);
    }

    function mulByRate(uint256 self, uint256 rate)
        internal
        pure
        returns (uint256)
    {
        return self.mul(rate).div(RATE_POINT_MULTIPLIER);
    }
}

// File: @openzeppelin/contracts/utils/SafeCast.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
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
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
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

// File: contracts/utils/SpreadCalculator.sol

pragma solidity >=0.6.6;






contract SpreadCalculator is SpreadCalculatorInterface {
    using RateMath for uint256;
    using SafeMath for uint256;
    using SafeCast for uint256;

    uint256 public constant SPREAD_RATE = 3000000000000000; //= 0.3%
    uint256 public constant DECIMAL = 1000000000000000000;
    uint256 public constant TEN_DIGITS = 10000000000;
    uint256
        public constant MAX_RATIONAL_ORACLE_VALUE = 100000000000000000000000; // too much volatility or ETH price

    // parameters of approximate expression of Black-Scholes equation that calculates LBT volatility
    // 'X4' is unused parameter because minimum spread rate is 0.3 %
    uint256 public constant ALPHA1 = 6085926862470381000;
    uint256 public constant ALPHA2 = 2931875257585468700;
    uint256 public constant MAX_EXECUTE_ACCOUNT = 5;
    uint256 public constant ALPHA3 = 2218732501079067300;
    int256 public constant BETA1 = 1406874237416828400;
    int256 public constant BETA2 = 1756430504093997600;
    int256 public constant BETA3 = 2434962998012975000;
    uint256 public constant COEF1 = 226698973741174460000;
    uint256 public constant COEF2 = 14143621388702120000;
    uint256 public constant COEF3 = 3191869733673552600;
    //uint256 public constant COEF4 = 194954040017071670;
    uint256 public constant COEFSIG1 = 1332906524709810000000;
    uint256 public constant COEFSIG2 = 39310196066041410000;
    uint256 public constant COEFSIG3 = 7201026361442427000;
    //uint256 public constant COEFSIG4 = 551672108932873900;
    uint256 public constant INTERCEPT1 = 327997870106653860000;
    uint256 public constant INTERCEPT2 = 28959220856904096000;
    uint256 public constant INTERCEPT3 = 9723230176749988000;
    //uint256 public constant INTERCEPT4 = 2425851354532068300;
    uint256 public constant ROOTEDYEARINSECOND = 5615;
    event CalculateSpread(
        uint256 indexed price,
        uint256 indexed volatility,
        uint256 indexed spread
    );

    /**
     * @notice Spread rate calculation
     * @param maturity Maturity of option token
     * @param strikePrice Strikeprice of option token
     * @return spreadRate Spread rate of this option token
     * @dev S/K is Price of ETH / strikeprice
     * @dev Spread is difined by volatility of LBT which is approached by linear equation (intercept - coef * S/K - coefsig * vol * t^0.5)
     * @dev Coefficient and intercept of linear equation are determined by S/K(and alpha - beta * vol * t^0.5)
     **/
    function calculateCurrentSpread(
        uint256 maturity,
        uint256 strikePrice,
        OracleInterface oracle
    ) external override returns (uint128) {
        uint256 spreadRate = SPREAD_RATE;
        if (address(oracle) == address(0)) {
            emit CalculateSpread(0, 0, spreadRate);
            return uint128(spreadRate);
        }
        uint256 ethPrice = oracle.latestPrice().mul(TEN_DIGITS);
        uint256 volatility = oracle.getVolatility().mul(TEN_DIGITS);

        if (
            ethPrice > MAX_RATIONAL_ORACLE_VALUE ||
            volatility > MAX_RATIONAL_ORACLE_VALUE
        ) {
            emit CalculateSpread(ethPrice, volatility, spreadRate);
            return uint128(spreadRate);
        }
        uint256 time = (_sqrt(maturity - block.timestamp).mul(DECIMAL)).div(
            ROOTEDYEARINSECOND
        );
        uint256 sigTime = volatility.mulByRate(time);
        uint256 ratio = ethPrice.divByRate(strikePrice);
        if (int256(ratio) <= BETA1 - int256(ALPHA1.mulByRate(sigTime))) {
            spreadRate = (
                SPREAD_RATE.mulByRate(
                    _caluculateZ(COEF1, COEFSIG1, INTERCEPT1, ratio, sigTime)
                )
            );
        } else if (int256(ratio) <= BETA2 - int256(ALPHA2.mulByRate(sigTime))) {
            spreadRate = (
                SPREAD_RATE.mulByRate(
                    _caluculateZ(COEF2, COEFSIG2, INTERCEPT2, ratio, sigTime)
                )
            );
        } else if (int256(ratio) <= BETA3 - int256(ALPHA3.mulByRate(sigTime))) {
            spreadRate = (
                SPREAD_RATE.mulByRate(
                    _caluculateZ(COEF3, COEFSIG3, INTERCEPT3, ratio, sigTime)
                )
            );
        }
        emit CalculateSpread(ethPrice, volatility, spreadRate);
        return spreadRate.toUint128();
        // if S/K is under first tolerance difined by COEF4, COEFSIG4, INTERCEPT4, returns 0.3%
        /*
        else {
            uint256 spreadRate = SPREAD_RATE.mulByRate(_caluculateZ(COEF4, COEFSIG4, INTERCEPT4, ratio, sigTime));
            return uint64(spreadRate);
        }
        return uint64(SPREAD_RATE);
        */
    }

    /**
     * @notice If volatility of asset pair is over 200%, spread rate becomes variable
     **/
    function calculateSpreadByAssetVolatility(OracleInterface oracle)
        external
        override
        returns (uint128)
    {
        if (address(oracle) == address(0)) {
            return uint128(SPREAD_RATE);
        }
        uint256 volatility = oracle.getVolatility().mul(TEN_DIGITS);
        if ((DECIMAL * 100) > volatility && (DECIMAL * 2) < volatility) {
            return SPREAD_RATE.mulByRate(volatility).div(2).toUint128();
        } else if (DECIMAL * 100 <= volatility) {
            return uint128(SPREAD_RATE * 50);
        }
        return uint128(SPREAD_RATE);
    }

    /**
     * @notice Approximate expression of option token volatility
     * @param coef Coefficient of S/K in the linear equation
     * @param coefsig Coefficient of vol * t^0.5 in the linear equation
     * @param intercept Intercept in the linear equation
     * @param ratio S/K
     * @param sigTime vol * t^0.5
     * @dev Spread is difined by volatility of LBT which is approached by linear equation (intercept - coef * S/K - coefsig * vol * t^0.5)
     * @dev Coefficient and intercept of linear equation is determined by S/k(and alpha - beta * vol * t^0.5)
     * @dev spread = 0.3 * v / 2
     **/
    function _caluculateZ(
        uint256 coef,
        uint256 coefsig,
        uint256 intercept,
        uint256 ratio,
        uint256 sigTime
    ) private pure returns (uint256) {
        uint256 z = intercept.sub(ratio.mulByRate(coef)).sub(
            sigTime.mulByRate(coefsig)
        );
        if (z <= 2 * DECIMAL) {
            return DECIMAL;
        } else if (z >= DECIMAL.mul(100)) {
            return DECIMAL * 50;
        }
        return z.div(2);
    }

    /**
     * @notice Calculate square root of uint
     **/
    function _sqrt(uint256 x) private pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}