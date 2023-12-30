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

// File: contracts/interfaces/AggregatorInterface.sol

pragma solidity 0.6.6;

// https://github.com/smartcontractkit/chainlink/blob/feature/whitelisted-interface/evm-contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
// https://github.com/smartcontractkit/chainlink/blob/feature/whitelisted-interface/evm-contracts/src/v0.6/interfaces/AggregatorInterface.sol
interface AggregatorInterface {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint256 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint256 answeredInRound
        );
}

// File: contracts/ChainlinkPriceOracle.sol

pragma solidity 0.6.6;





/**
 * @notice PriceOracle wrapping AggregatorInterface by Chainlink.
 */
contract ChainlinkPriceOracle is PriceOracleInterface {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    uint256 private constant SECONDS_IN_DAY = 60 * 60 * 24;
    uint8 private constant DECIMALS = 8;
    int256 private constant FLUCTUATION_THRESHOLD = 8; // 800%

    AggregatorInterface public immutable aggregator;

    constructor(AggregatorInterface aggregatorAddress) public {
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
            _isNotDestructed() &&
            _isLatestPriceProper() &&
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
    function getPrice(uint256 id) external override returns (uint256) {
        int256 price = aggregator.getAnswer(id);
        return uint256(price);
    }

    /**
     * @dev See {PriceOracleInterface-getTimestamp}.
     */
    function getTimestamp(uint256 id) external override returns (uint256) {
        return aggregator.getTimestamp(id);
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
     * @dev Returns `true` if the aggregator's latest price value is appropriate.
     * 1. Updated within last 24 hours.
     * 2. More than 0.
     * 3. Not too larger than the previous value.
     * 4. Not too smaller than the previous value.
     * Returns `false` when catch exception.
     */
    function _isLatestPriceProper() private view returns (bool r) {
        try aggregator.latestRoundData() returns (
            uint256 latestRound,
            int256 latestAnswer,
            uint256,
            uint256 updatedAt,
            uint256
        ) {
            // check if `latestRound` is not 0 to avoid under flow on L 111.
            if (latestRound == 0) {
                return r;
            }
            try aggregator.getAnswer(latestRound - 1) returns (
                int256 previousAnswer
            ) {
                // 1. Updated within last 24 hours.
                //check if the aggregator updated the price within last 24 hours.
                if (now.sub(updatedAt) > SECONDS_IN_DAY) {
                    return r;
                }
                // 2. More than 0.
                // check if the latest and the previous price are more than 0.
                if (latestAnswer <= 0) {
                    return r;
                }
                // 3. Not too larger than the previous value.
                // check if the latest price is not too larger than the previous price.
                if (latestAnswer > previousAnswer.mul(FLUCTUATION_THRESHOLD)) {
                    return r;
                }
                // 4. Not too smaller than the previous value.
                // check if the latest price is not too smaller than the previous price.
                if (latestAnswer.mul(FLUCTUATION_THRESHOLD) < previousAnswer) {
                    return r;
                }
                r = true;
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
}