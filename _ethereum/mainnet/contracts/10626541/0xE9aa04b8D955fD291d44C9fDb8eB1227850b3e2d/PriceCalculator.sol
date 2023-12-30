// File: contracts/Interfaces/PriceCalculatorInterface.sol

pragma solidity >=0.6.6;

interface PriceCalculatorInterface {
    function calculatePrice(
        uint256 buyAmount,
        uint256 buyAmountLimit,
        uint256 sellAmount,
        uint256 sellAmountLimit,
        uint256 baseTokenPool,
        uint256 settlementTokenPool
    ) external view returns (uint256[5] memory);
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

// File: contracts/utils/PriceCalculator.sol

pragma solidity >=0.6.6;





contract PriceCalculator is PriceCalculatorInterface {
    using RateMath for uint256;
    using SafeMath for uint256;
    using SafeCast for uint256;
    uint256 public constant TOLERANCE_RATE = 1001000000000000000; //= 100.1%
    uint256 public constant SECURE_RATE = 1050000000000000000; //105% max slippage for all orders
    uint256 public constant DECIMAL = 1000000000000000000;

    /**
     * @notice calculates and return price, and refund rates
     * @param AmountFLEX0_1 Amount of flex order of token0 to token1
     * @param AmountSTRICT0_1 Amount of strict order of token0 to token1
     * @param AmountFLEX1_0  Amount of flex order of token1 to token0
     * @param AmountSTRICT1_0 Amount of strict order of token1 to token0
     * @param reserve0 Amount of reserve0
     * @param reserve1 Amount of reserve1
     * @return [price, refundStatus, partiallyRefundRate, executed amount of token0 to token1, executed amount of token1 to token0]
     * @dev Refund for careful users if change of price is bigger than TORELANCE_RATE
     * @dev Refund for all traders if change of price is bigger than SECURE_RATE
     **/
    function calculatePrice(
        uint256 AmountFLEX0_1,
        uint256 AmountSTRICT0_1,
        uint256 AmountFLEX1_0,
        uint256 AmountSTRICT1_0,
        uint256 reserve0,
        uint256 reserve1
    ) external override view returns (uint256[5] memory) {
        require(
            reserve0 != 0 && reserve1 != 0,
            "There are no reserves. Please add liquidity or redeploy exchange"
        );
        // initial price = reserve1 / reserve0
        // price = (reserve1 + sell order amount) / (reserve0 + sell order amount)
        uint256 price = (reserve1.add(AmountFLEX1_0).add(AmountSTRICT1_0))
            .divByRate(reserve0.add(AmountFLEX0_1).add(AmountSTRICT0_1));
        // initial low Price is price of Limit order(initial price / 1.001)
        uint256 lowPrice = (reserve1.divByRate(reserve0)).divByRate(
            TOLERANCE_RATE
        );
        // initial high Price is price of Limit order(initial price * 1.001)
        uint256 highPrice = (reserve1.divByRate(reserve0)).mulByRate(
            TOLERANCE_RATE
        );
        // if initial price is within the TORELANCE_RATE, return initial price and execute all orders
        if (price > lowPrice && price < highPrice) {
            return [
                price,
                0,
                0,
                AmountFLEX0_1.add(AmountSTRICT0_1),
                AmountFLEX1_0.add(AmountSTRICT1_0)
            ];
        } else if (price <= lowPrice) {
            return
                _calculatePriceAnd0_1RefundRate(
                    price,
                    lowPrice,
                    AmountFLEX0_1,
                    AmountSTRICT0_1,
                    AmountFLEX1_0.add(AmountSTRICT1_0),
                    reserve0,
                    reserve1
                );
        } else {
            return
                _calculatePriceAnd1_0RefundRate(
                    price,
                    highPrice,
                    AmountFLEX0_1.add(AmountSTRICT0_1),
                    AmountFLEX1_0,
                    AmountSTRICT1_0,
                    reserve0,
                    reserve1
                );
        }
    }

    /**
     * @notice calculates price and refund rates if price is lower than `lowPrice`
     * @param price price which is calculated in _calculatePrice()
     * @param lowPrice reserve1 / reserve0 * 0.999
     * @param AmountFLEX0_1 Amount of no-limit token0 to token1
     * @param AmountSTRICT0_1 Amount of limit token0 to token1
     * @param all1_0Amount Amount of all token1 to token0 order. In this function, all token1 to token0 order will be executed
     * @return [price, refundStatus, partiallyRefundRate, executed amount of token0 to token1 order, executed amount of token1 to token0 order]
     **/
    function _calculatePriceAnd0_1RefundRate(
        uint256 price,
        uint256 lowPrice,
        uint256 AmountFLEX0_1,
        uint256 AmountSTRICT0_1,
        uint256 all1_0Amount,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256[5] memory) {
        // executeAmount is amount of buy orders in lowPrice(initial price * 0.999)
        uint256 executeAmount = _calculateExecuteAmount0_1(
            reserve0,
            reserve1,
            all1_0Amount,
            lowPrice
        );

        // if executeAmount > AmountFLEX0_1, (AmountFLEX0_1 - executeAmount) in limit order will be executed
        if (executeAmount > AmountFLEX0_1) {
            uint256 refundRate = (
                AmountFLEX0_1.add(AmountSTRICT0_1).sub(executeAmount)
            )
                .divByRate(AmountSTRICT0_1);
            return [lowPrice, 1, refundRate, executeAmount, all1_0Amount];
        } else {
            // refund all limit buy orders
            // update lowPrice to SECURE_RATE
            uint256 nextLowPrice = (reserve1.divByRate(reserve0)).divByRate(
                SECURE_RATE
            );
            // update price
            price = (reserve1.add(all1_0Amount)).divByRate(
                reserve0.add(AmountFLEX0_1)
            );
            if (nextLowPrice > price) {
                // executeAmount is amount of buy orders when the price is lower than lowPrice (initial price * 0.95)
                executeAmount = _calculateExecuteAmount0_1(
                    reserve0,
                    reserve1,
                    all1_0Amount,
                    nextLowPrice
                );

                // if executeAmount < AmountFLEX0_1, refund all of limit buy orders and refund some parts of no-limit buy orders
                if (executeAmount < AmountFLEX0_1) {
                    uint256 refundRate = (AmountFLEX0_1.sub(executeAmount))
                        .divByRate(AmountFLEX0_1);
                    return [
                        nextLowPrice,
                        2,
                        refundRate,
                        executeAmount,
                        all1_0Amount
                    ];
                }
            }
            // execute all no-limit buy orders and refund all limit buy orders
            return [price, 1, DECIMAL, AmountFLEX0_1, all1_0Amount];
        }
    }

    /**
     * @notice calculates price and refund rates if price is higher than highPrice
     * @param price price which is calculated in _calculatePrice()
     * @param highPrice reserve1 / reserve0 * 1.001
     * @param all0_1Amount Amount of all token0 to token1 order. In this function, all token0 to token1 order will be executed
     * @param AmountFLEX1_0  Amount of limit token0 to token1 order.
     * @param AmountSTRICT1_0 Amount of no-limit token1 to token0 order
     * @return [price, refundStatus, partiallyRefundRate, executed amount of token0 to token1 order, executed amount of token1 to token0 order]
     **/
    function _calculatePriceAnd1_0RefundRate(
        uint256 price,
        uint256 highPrice,
        uint256 all0_1Amount,
        uint256 AmountFLEX1_0,
        uint256 AmountSTRICT1_0,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256[5] memory) {
        // executeAmount is amount of sell orders when the price is higher than highPrice(initial price * 1.001)
        uint256 executeAmount = _calculateExecuteAmount1_0(
            reserve1,
            reserve0,
            all0_1Amount,
            highPrice
        );

        if (executeAmount > AmountFLEX1_0) {
            //if executeAmount > AmountFLEX1_0 , (AmountFLEX1_0  - executeAmount) in limit order will be executed
            uint256 refundRate = (
                AmountFLEX1_0.add(AmountSTRICT1_0).sub(executeAmount)
            )
                .divByRate(AmountSTRICT1_0);
            return [highPrice, 3, refundRate, all0_1Amount, executeAmount];
        } else {
            // refund all limit sell orders
            // update highPrice to SECURE_RATE
            uint256 nextHighPrice = (reserve1.divByRate(reserve0)).mulByRate(
                SECURE_RATE
            );
            // update price
            price = (reserve1.add(AmountFLEX1_0)).divByRate(
                reserve0.add(all0_1Amount)
            );
            if (nextHighPrice < price) {
                // executeAmount is amount of sell orders when the price is higher than highPrice(initial price * 1.05)
                executeAmount = _calculateExecuteAmount1_0(
                    reserve1,
                    reserve0,
                    all0_1Amount,
                    nextHighPrice
                );
                // if executeAmount < AmountFLEX1_0 , refund all of limit sell orders and refund some parts of no-limit sell orders
                if (executeAmount < AmountFLEX1_0) {
                    uint256 refundRate = (AmountFLEX1_0.sub(executeAmount))
                        .divByRate(AmountFLEX1_0);
                    return [
                        nextHighPrice,
                        4,
                        refundRate,
                        all0_1Amount,
                        executeAmount
                    ];
                }
            }
            // execute all no-limit sell orders and refund all limit sell orders
            return [price, 3, DECIMAL, all0_1Amount, AmountFLEX1_0];
        }
    }

    /**
     * @notice Calculates TOKEN0 amount to execute in price `price`
     **/
    function _calculateExecuteAmount0_1(
        uint256 reserve,
        uint256 opponentReserve,
        uint256 opppnentAmount,
        uint256 price
    ) private pure returns (uint256) {
        uint256 possibleReserve = (opponentReserve.add(opppnentAmount))
            .divByRate(price);

        if (possibleReserve > reserve) {
            return possibleReserve.sub(reserve);
        } else {
            return 0;
        }
    }

    /**
     * @notice Calculates TOKEN1 amount to execute in price `price`
     **/
    function _calculateExecuteAmount1_0(
        uint256 reserve,
        uint256 opponentReserve,
        uint256 opppnentAmount,
        uint256 price
    ) private pure returns (uint256) {
        uint256 possibleReserve = (opponentReserve.add(opppnentAmount))
            .mulByRate(price);

        if (possibleReserve > reserve) {
            return possibleReserve.sub(reserve);
        } else {
            return 0;
        }
    }
}