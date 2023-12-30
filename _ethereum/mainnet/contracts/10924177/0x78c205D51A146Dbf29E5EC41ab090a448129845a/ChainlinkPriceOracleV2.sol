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

// SPDX-License-Identifier: MIT

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

// File: contracts/interfaces/PriceOracleInterface.sol

pragma solidity 0.6.6;

/**
 * @dev Interface of the price oracle.
 */
interface PriceOracleInterface {
    /**
     * @dev Returns `true`if oracle is working.
     */
    function isWorking() external returns (bool);

    /**
     * @dev Returns the latest id. The id start from 1 and increments by 1.
     */
    function latestId() external returns (uint256);

    /**
     * @dev Returns the last updated price. Decimals is 8.
     **/
    function latestPrice() external returns (uint256);

    /**
     * @dev Returns the timestamp of the last updated price.
     */
    function latestTimestamp() external returns (uint256);

    /**
     * @dev Returns the historical price specified by `id`. Decimals is 8.
     */
    function getPrice(uint256 id) external returns (uint256);

    /**
     * @dev Returns the timestamp of historical price specified by `id`.
     */
    function getTimestamp(uint256 id) external returns (uint256);
}

// File: contracts/interfaces/AggregatorInterfaceV2.sol

pragma solidity 0.6.6;

// https://etherscan.io/address/0xfd38a152dddf1f9cf5ec9b23599c6d5f080d6aff#code
interface AggregatorInterfaceV2 {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function decimals() external view returns (uint8);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: contracts/ChainlinkPriceOracleV2.sol

pragma solidity 0.6.6;





/**
 * @notice PriceOracle wrapping AggregatorInterface by Chainlink.
 */
contract ChainlinkPriceOracleV2 is PriceOracleInterface {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    uint256 private constant SECONDS_IN_DAY = 60 * 60 * 24;
    uint8 private constant DECIMALS = 8;
    int256 private constant FLUCTUATION_THRESHOLD = 8; // 800%

    AggregatorInterfaceV2 public immutable aggregator;
    bool public healthFlag = true;

    event HealthCheck(bool indexed success);

    constructor(AggregatorInterfaceV2 aggregatorAddress) public {
        aggregator = aggregatorAddress;
    }

    //
    // Implementation of PriceOracleInterface
    //
    /**
     * @notice Returns `true` if the price is updated correctly within last 24 hours.
     * @dev Returns `false` if any exception was thrown in function calls to aggregator.
     */
    function isWorking() external override returns (bool) {
        return
            healthFlag &&
            _isNotDestructed() &&
            _isLatestAnswerProper() &&
            _isDecimalNotChanged();
    }

    /**
     * @dev See {PriceOracleInterface-latestId}.
     */
    function latestId() external override returns (uint256) {
        return aggregator.latestRound();
    }

    /**
     * @dev See {PriceOracleInterface-latestPrice}.
     */
    function latestPrice() external override returns (uint256) {
        int256 price = aggregator.latestAnswer();
        return uint256(price);
    }

    /**
     * @dev See {PriceOracleInterface-latestTimestamp}.
     */
    function latestTimestamp() external override returns (uint256) {
        return aggregator.latestTimestamp();
    }

    /**
     * @dev See {PriceOracleInterface-getPrice}.
     */
    function getPrice(uint256 id) public override returns (uint256) {
        int256 price = aggregator.getAnswer(id);
        if (price == 0) {
            return getPrice(id.sub(1));
        }
        return uint256(price);
    }

    /**
     * @dev See {PriceOracleInterface-getTimestamp}.
     */
    function getTimestamp(uint256 id) public override returns (uint256) {
        uint256 timestamp = aggregator.getTimestamp(id);
        if (timestamp == 0) {
            return getTimestamp(id.sub(1));
        }
        return timestamp;
    }

    function healthCheck() external returns (bool r) {
        r = isHealth();
        if (!r) {
            healthFlag = false;
        }
        emit HealthCheck(r);
        return r;
    }

    function isHealth() public view returns (bool r) {
        try aggregator.latestRound() returns (uint256 latestRound) {
            if (latestRound < 25) {
                return r;
            }
            for (uint256 id = latestRound - 23; id <= latestRound; id++) {
                if (!areAnswersProperAt(uint80(id))) {
                    return r;
                }
            }
            if (!areAnswersProperThoroughly(uint80(latestRound))) {
                return r;
            }
            r = true;
        } catch {}
    }

    function areAnswersProperThoroughly(uint80 startId)
        public
        view
        returns (bool)
    {
        (, int256 checkAnswer, , uint256 checkTimestamp, ) = aggregator
            .getRoundData(uint80(startId - 24));
        int256 answer;
        uint256 timestamp;
        bool areAnswersSame = true;
        bool areTimestampsSame = true;
        for (uint256 id = startId - 23; id < startId; id++) {
            (, answer, , timestamp, ) = aggregator.getRoundData(uint80(id));
            if (areAnswersSame && answer != checkAnswer) {
                areAnswersSame = false;
            }
            if (areTimestampsSame && timestamp != checkTimestamp) {
                areTimestampsSame = false;
            }
        }
        return !(areAnswersSame || areTimestampsSame);
    }

    function areAnswersProperAt(uint80 id) public view returns (bool r) {
        uint80 prev = id - 1;
        try aggregator.getRoundData(uint80(id)) returns (
            uint80,
            int256 firstAnswer,
            uint256,
            uint256 firstTimestamp,
            uint80
        ) {
            try aggregator.getRoundData(prev) returns (
                uint80,
                int256 secondAnswer,
                uint256,
                uint256 secondTimestamp,
                uint80
            ) {
                return (_isProperAnswers(firstAnswer, secondAnswer) &&
                    _isProperTimestamps(firstTimestamp, secondTimestamp));
            } catch {}
        } catch {}
    }

    /**
     * @dev Returns `true` if the aggregator is not self destructed.
     * After a contract is destructed, size of the code at the address becomes 0.
     */
    function _isNotDestructed() private view returns (bool) {
        address aggregatorAddr = address(aggregator);
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(aggregatorAddr)
        }
        return size != 0;
    }

    /**
     * @dev Returns `true` if the aggregator's latest price value is proper.
     * Returns `false` when catch exception.
     */
    function _isLatestAnswerProper() private view returns (bool r) {
        try aggregator.latestRoundData() returns (
            uint80 latestRound,
            int256 latestAnswer,
            uint256,
            uint256 updatedAt,
            uint80
        ) {
            // check if `latestRound` is not 0 to avoid under flow on L 111.
            if (latestRound == 0) {
                return r;
            }
            try aggregator.getAnswer(latestRound - 1) returns (
                int256 previousAnswer
            ) {
                return (_isProperAnswers(latestAnswer, previousAnswer) &&
                    _isProperTimestamps(now, updatedAt));
            } catch {}
        } catch {}
    }

    /**
     * @dev Returns `true` if the aggregator returns 8 for the decimals.
     * Returns `false` when catch exception.
     * When the aggregator decimals() returns a different value,
     * stop providing data and turn into Recovery phase.
     */
    function _isDecimalNotChanged() private view returns (bool) {
        try aggregator.decimals() returns (uint8 d) {
            return d == DECIMALS;
        } catch {
            return false;
        }
    }

    /*
     * @dev Returns `true` if the contiguous prices are proper.
     * 1. More than 0.
     * 2. Not too larger than the previous value.
     * 3. Not too smaller than the previous value.
     */
    function _isProperAnswers(int256 firstAnswer, int256 secondAnswer)
        private
        pure
        returns (bool r)
    {
        // 1. More than 0.
        // check if the first price is more than 0.
        if (firstAnswer <= 0) {
            return r;
        }
        // 2. Not too larger than the previous value.
        // check if the first price is not too larger than the second price.
        if (firstAnswer > secondAnswer.mul(FLUCTUATION_THRESHOLD)) {
            return r;
        }
        // 3. Not too smaller than the previous value.
        // check if the first price is not too smaller than the second price.
        if (firstAnswer.mul(FLUCTUATION_THRESHOLD) < secondAnswer) {
            return r;
        }
        return true;
    }

    /*
     * @dev Returns `true` if the contiguous timestamp are proper.
     */
    function _isProperTimestamps(
        uint256 firstTimestamp,
        uint256 secondTimestamp
    ) private pure returns (bool) {
        //check if diff of timestamps is within 24 hours.
        return firstTimestamp.sub(secondTimestamp) <= SECONDS_IN_DAY;
    }
}