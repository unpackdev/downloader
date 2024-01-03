pragma solidity 0.6.6;

// File: contracts/oracle/LatestPriceOracleInterface.sol




/**
 * @dev Interface of the price oracle.
 */
interface LatestPriceOracleInterface {
    /**
     * @dev Returns `true`if oracle is working.
     */
    function isWorking() external returns (bool);

    /**
     * @dev Returns the last updated price. Decimals is 8.
     **/
    function latestPrice() external returns (uint256);

    /**
     * @dev Returns the timestamp of the last updated price.
     */
    function latestTimestamp() external returns (uint256);
}

// File: contracts/oracle/PriceOracleInterface.sol





/**
 * @dev Interface of the price oracle.
 */
interface PriceOracleInterface is LatestPriceOracleInterface {
    /**
     * @dev Returns the latest id. The id start from 1 and increments by 1.
     */
    function latestId() external returns (uint256);

    /**
     * @dev Returns the historical price specified by `id`. Decimals is 8.
     */
    function getPrice(uint256 id) external returns (uint256);

    /**
     * @dev Returns the timestamp of historical price specified by `id`.
     */
    function getTimestamp(uint256 id) external returns (uint256);
}

// File: contracts/util/TransferETHInterface.sol




interface TransferETHInterface {
    receive() external payable;

    event LogTransferETH(address indexed from, address indexed to, uint256 value);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/bondToken/BondTokenInterface.sol






interface BondTokenInterface is IERC20 {
    event LogExpire(uint128 rateNumerator, uint128 rateDenominator, bool firstTime);

    function mint(address account, uint256 amount) external returns (bool success);

    function expire(uint128 rateNumerator, uint128 rateDenominator)
        external
        returns (bool firstTime);

    function simpleBurn(address account, uint256 amount) external returns (bool success);

    function burn(uint256 amount) external returns (bool success);

    function burnAll() external returns (uint256 amount);

    function getRate() external view returns (uint128 rateNumerator, uint128 rateDenominator);
}

// File: contracts/bondMaker/BondMakerInterface.sol





interface BondMakerInterface {
    event LogNewBond(
        bytes32 indexed bondID,
        address indexed bondTokenAddress,
        uint256 indexed maturity,
        bytes32 fnMapID
    );

    event LogNewBondGroup(
        uint256 indexed bondGroupID,
        uint256 indexed maturity,
        uint64 indexed sbtStrikePrice,
        bytes32[] bondIDs
    );

    event LogIssueNewBonds(uint256 indexed bondGroupID, address indexed issuer, uint256 amount);

    event LogReverseBondGroupToCollateral(
        uint256 indexed bondGroupID,
        address indexed owner,
        uint256 amount
    );

    event LogExchangeEquivalentBonds(
        address indexed owner,
        uint256 indexed inputBondGroupID,
        uint256 indexed outputBondGroupID,
        uint256 amount
    );

    event LogLiquidateBond(bytes32 indexed bondID, uint128 rateNumerator, uint128 rateDenominator);

    function registerNewBond(uint256 maturity, bytes calldata fnMap)
        external
        returns (
            bytes32 bondID,
            address bondTokenAddress,
            bytes32 fnMapID
        );

    function registerNewBondGroup(bytes32[] calldata bondIDList, uint256 maturity)
        external
        returns (uint256 bondGroupID);

    function reverseBondGroupToCollateral(uint256 bondGroupID, uint256 amount)
        external
        returns (bool success);

    function exchangeEquivalentBonds(
        uint256 inputBondGroupID,
        uint256 outputBondGroupID,
        uint256 amount,
        bytes32[] calldata exceptionBonds
    ) external returns (bool);

    function liquidateBond(uint256 bondGroupID, uint256 oracleHintID)
        external
        returns (uint256 totalPayment);

    function collateralAddress() external view returns (address);

    function oracleAddress() external view returns (PriceOracleInterface);

    function feeTaker() external view returns (address);

    function decimalsOfBond() external view returns (uint8);

    function decimalsOfOraclePrice() external view returns (uint8);

    function maturityScale() external view returns (uint256);

    function nextBondGroupID() external view returns (uint256);

    function getBond(bytes32 bondID)
        external
        view
        returns (
            address bondAddress,
            uint256 maturity,
            uint64 solidStrikePrice,
            bytes32 fnMapID
        );

    function getFnMap(bytes32 fnMapID) external view returns (bytes memory fnMap);

    function getBondGroup(uint256 bondGroupID)
        external
        view
        returns (bytes32[] memory bondIDs, uint256 maturity);

    function generateFnMapID(bytes calldata fnMap) external view returns (bytes32 fnMapID);

    function generateBondID(uint256 maturity, bytes calldata fnMap)
        external
        view
        returns (bytes32 bondID);
}

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

// File: contracts/util/Polyline.sol




contract Polyline is UseSafeMath {
    struct Point {
        uint64 x; // Value of the x-axis of the x-y plane
        uint64 y; // Value of the y-axis of the x-y plane
    }

    struct LineSegment {
        Point left; // The left end of the line definition range
        Point right; // The right end of the line definition range
    }

    /**
     * @notice Return the value of y corresponding to x on the given line. line in the form of
     * a rational number (numerator / denominator).
     * If you treat a line as a line segment instead of a line, you should run
     * includesDomain(line, x) to check whether x is included in the line's domain or not.
     * @dev To guarantee accuracy, the bit length of the denominator must be greater than or equal
     * to the bit length of x, and the bit length of the numerator must be greater than or equal
     * to the sum of the bit lengths of x and y.
     */
    function _mapXtoY(LineSegment memory line, uint64 x)
        internal
        pure
        returns (uint128 numerator, uint64 denominator)
    {
        int256 x1 = int256(line.left.x);
        int256 y1 = int256(line.left.y);
        int256 x2 = int256(line.right.x);
        int256 y2 = int256(line.right.y);

        require(x2 > x1, "must be left.x < right.x");

        denominator = uint64(x2 - x1);

        // Calculate y = ((x2 - x) * y1 + (x - x1) * y2) / (x2 - x1)
        // in the form of a fraction (numerator / denominator).
        int256 n = (x - x1) * y2 + (x2 - x) * y1;

        require(n >= 0, "underflow n");
        require(n < 2**128, "system error: overflow n");
        numerator = uint128(n);
    }

    /**
     * @notice Checking that a line segment is a valid format.
     */
    function assertLineSegment(LineSegment memory segment) internal pure {
        uint64 x1 = segment.left.x;
        uint64 x2 = segment.right.x;
        require(x1 < x2, "must be left.x < right.x");
    }

    /**
     * @notice Checking that a polyline is a valid format.
     */
    function assertPolyline(LineSegment[] memory polyline) internal pure {
        uint256 numOfSegment = polyline.length;
        require(numOfSegment != 0, "polyline must not be empty array");

        LineSegment memory leftSegment = polyline[0]; // mutable
        int256 gradientNumerator = int256(leftSegment.right.y) - int256(leftSegment.left.y); // mutable
        int256 gradientDenominator = int256(leftSegment.right.x) - int256(leftSegment.left.x); // mutable

        // The beginning of the first line segment's domain is 0.
        require(
            leftSegment.left.x == uint64(0),
            "the x coordinate of left end of the first segment must be 0"
        );
        // The value of y when x is 0 is 0.
        require(
            leftSegment.left.y == uint64(0),
            "the y coordinate of left end of the first segment must be 0"
        );

        // Making sure that the first line segment is a correct format.
        assertLineSegment(leftSegment);

        // The end of the domain of a segment and the beginning of the domain of the adjacent
        // segment must coincide.
        LineSegment memory rightSegment; // mutable
        for (uint256 i = 1; i < numOfSegment; i++) {
            rightSegment = polyline[i];

            // Make sure that the i-th line segment is a correct format.
            assertLineSegment(rightSegment);

            // Checking that the x-coordinates are same.
            require(
                leftSegment.right.x == rightSegment.left.x,
                "given polyline has an undefined domain."
            );

            // Checking that the y-coordinates are same.
            require(
                leftSegment.right.y == rightSegment.left.y,
                "given polyline is not a continuous function"
            );

            int256 nextGradientNumerator = int256(rightSegment.right.y) -
                int256(rightSegment.left.y);
            int256 nextGradientDenominator = int256(rightSegment.right.x) -
                int256(rightSegment.left.x);
            require(
                nextGradientNumerator * gradientDenominator !=
                    nextGradientDenominator * gradientNumerator,
                "the sequential segments must not have the same gradient"
            );

            leftSegment = rightSegment;
            gradientNumerator = nextGradientNumerator;
            gradientDenominator = nextGradientDenominator;
        }

        // rightSegment is lastSegment

        // About the last line segment.
        require(
            gradientNumerator >= 0 && gradientNumerator <= gradientDenominator,
            "the gradient of last line segment must be non-negative, and equal to or less than 1"
        );
    }

    /**
     * @notice zip a LineSegment structure to uint256
     * @return zip uint256( 0 ... 0 | x1 | y1 | x2 | y2 )
     */
    function zipLineSegment(LineSegment memory segment) internal pure returns (uint256 zip) {
        uint256 x1U256 = uint256(segment.left.x) << (64 + 64 + 64); // uint64
        uint256 y1U256 = uint256(segment.left.y) << (64 + 64); // uint64
        uint256 x2U256 = uint256(segment.right.x) << 64; // uint64
        uint256 y2U256 = uint256(segment.right.y); // uint64
        zip = x1U256 | y1U256 | x2U256 | y2U256;
    }

    /**
     * @notice unzip uint256 to a LineSegment structure
     */
    function unzipLineSegment(uint256 zip) internal pure returns (LineSegment memory) {
        uint64 x1 = uint64(zip >> (64 + 64 + 64));
        uint64 y1 = uint64(zip >> (64 + 64));
        uint64 x2 = uint64(zip >> 64);
        uint64 y2 = uint64(zip);
        return LineSegment({left: Point({x: x1, y: y1}), right: Point({x: x2, y: y2})});
    }

    /**
     * @notice unzip the fnMap to uint256[].
     */
    function decodePolyline(bytes memory fnMap) internal pure returns (uint256[] memory) {
        return abi.decode(fnMap, (uint256[]));
    }
}

// File: contracts/helper/BondMakerHelper.sol

// SPDX-License-Identifier: UNLICENSED

pragma experimental ABIEncoderV2;




contract BondMakerHelper is Polyline {
    event LogRegisterSbt(bytes32 bondID);
    event LogRegisterLbt(bytes32 bondID);
    event LogRegisterBondAndBondGroup(uint256 indexed bondGroupID, bytes32[] bondIDs);

    function registerSbt(
        address bondMakerAddress,
        uint64 strikePrice,
        uint256 maturity
    ) external returns (bytes32 bondID) {
        require(strikePrice != 0, "the strike price must be non-zero");
        require(strikePrice <= uint64(-2), "the strike price is too large");

        BondMakerInterface bondMaker = BondMakerInterface(bondMakerAddress);
        try bondMaker.oracleAddress().latestPrice() returns (uint256 spotPrice) {
            require(
                strikePrice >= spotPrice / 10 && strikePrice <= spotPrice * 10,
                "must be 0.1 <= S/K <= 10"
            );
        } catch {}

        bytes memory fnMap = _getSbtFnMap(strikePrice);
        (bondID, , ) = bondMaker.registerNewBond(maturity, fnMap);

        emit LogRegisterSbt(bondID);
    }

    function registerLbt(
        address bondMakerAddress,
        uint64 strikePrice,
        uint256 maturity
    ) external returns (bytes32 bondID) {
        require(strikePrice != 0, "the strike price must be non-zero");
        require(strikePrice <= uint64(-2), "the strike price is too large");

        BondMakerInterface bondMaker = BondMakerInterface(bondMakerAddress);
        try bondMaker.oracleAddress().latestPrice() returns (uint256 spotPrice) {
            require(
                strikePrice >= spotPrice / 10 && strikePrice <= spotPrice * 10,
                "must be 0.1 <= S/K <= 10"
            );
        } catch {}

        bytes memory fnMap = _getLbtFnMap(strikePrice);
        (bondID, , ) = bondMaker.registerNewBond(maturity, fnMap);

        emit LogRegisterLbt(bondID);
    }

    function registerSbtAndLbtAndBondGroup(
        address bondMakerAddress,
        uint64 strikePrice,
        uint256 maturity
    ) external returns (uint256 bondGroupID) {
        require(strikePrice != 0, "the SBT strike price must be non-zero");

        BondMakerInterface bondMaker = BondMakerInterface(bondMakerAddress);
        try bondMaker.oracleAddress().latestPrice() returns (uint256 spotPrice) {
            require(
                strikePrice >= spotPrice / 10 && strikePrice <= spotPrice * 10,
                "must be 0.1 <= S/K <= 10"
            );
        } catch {}

        bytes[] memory fnMaps = _getSbtAndLbtFnMap(strikePrice);
        bondGroupID = _registerBondAndBondGroup(bondMakerAddress, fnMaps, maturity);
    }

    function registerExoticBondAndBondGroup(
        address bondMakerAddress,
        uint64 sbtstrikePrice,
        uint64 lbtStrikePrice,
        uint256 maturity
    ) external returns (uint256 bondGroupID) {
        require(sbtstrikePrice != 0, "the SBT strike price must be non-zero");

        BondMakerInterface bondMaker = BondMakerInterface(bondMakerAddress);
        try bondMaker.oracleAddress().latestPrice() returns (uint256 spotPrice) {
            require(
                sbtstrikePrice >= spotPrice / 10 && sbtstrikePrice <= spotPrice * 10,
                "must be 0.1 <= S/K <= 10"
            );
            require(
                lbtStrikePrice >= spotPrice / 10 && lbtStrikePrice <= spotPrice * 10,
                "must be 0.1 <= S/K <= 10"
            );
        } catch {}

        bytes[] memory fnMaps = _getExoticFnMap(sbtstrikePrice, lbtStrikePrice);
        bondGroupID = _registerBondAndBondGroup(bondMakerAddress, fnMaps, maturity);
    }

    function registerBondAndBondGroup(
        address bondMakerAddress,
        bytes[] calldata fnMaps,
        uint256 maturity
    ) external returns (uint256 bondGroupID) {
        bondGroupID = _registerBondAndBondGroup(bondMakerAddress, fnMaps, maturity);
    }

    function getSbtFnMap(uint64 strikePrice) external pure returns (bytes memory fnMap) {
        fnMap = _getSbtFnMap(strikePrice);
    }

    function getLbtFnMap(uint64 strikePrice) external pure returns (bytes memory fnMap) {
        fnMap = _getLbtFnMap(strikePrice);
    }

    function getSbtAndLbtFnMap(uint64 strikePrice) external pure returns (bytes[] memory fnMaps) {
        fnMaps = _getSbtAndLbtFnMap(strikePrice);
    }

    function getExoticFnMap(uint64 sbtStrikePrice, uint64 lbtStrikePrice)
        external
        pure
        returns (bytes[] memory fnMaps)
    {
        fnMaps = _getExoticFnMap(sbtStrikePrice, lbtStrikePrice);
    }

    /**
     * @dev register bonds and bond group
     */
    function _registerBondAndBondGroup(
        address bondMakerAddress,
        bytes[] memory fnMaps,
        uint256 maturity
    ) internal returns (uint256 bondGroupID) {
        require(fnMaps.length != 0, "fnMaps must be non-empty list");

        BondMakerInterface bondMaker = BondMakerInterface(bondMakerAddress);
        bytes32[] memory bondIDs = new bytes32[](fnMaps.length);
        for (uint256 j = 0; j < fnMaps.length; j++) {
            bytes32 bondID = bondMaker.generateBondID(maturity, fnMaps[j]);
            (address bondAddress, , , ) = bondMaker.getBond(bondID);
            if (bondAddress == address(0)) {
                (bytes32 returnedBondID, , ) = bondMaker.registerNewBond(maturity, fnMaps[j]);
                require(
                    returnedBondID == bondID,
                    "system error: bondID was not generated as expected"
                );
            }
            bondIDs[j] = bondID;
        }

        bondGroupID = bondMaker.registerNewBondGroup(bondIDs, maturity);
        emit LogRegisterBondAndBondGroup(bondGroupID, bondIDs);
    }

    /**
     * @return fnMaps divided into SBT and LBT
     */
    function _getSbtAndLbtFnMap(uint64 strikePrice) internal pure returns (bytes[] memory fnMaps) {
        require(strikePrice <= uint64(-2), "the strike price is too large");

        fnMaps = new bytes[](2);
        fnMaps[0] = _getSbtFnMap(strikePrice);
        fnMaps[1] = _getLbtFnMap(strikePrice);
    }

    /**
     * @return fnMaps divided into pure SBT, LBT, semi-SBT and triangle bond.
     */
    function _getExoticFnMap(uint64 sbtStrikePrice, uint64 lbtStrikePrice)
        internal
        pure
        returns (bytes[] memory fnMaps)
    {
        require(
            sbtStrikePrice < lbtStrikePrice,
            "the SBT strike price must be less than the LBT strike price"
        );
        uint64 semiSbtStrikePrice = lbtStrikePrice - sbtStrikePrice;
        require(semiSbtStrikePrice % 2 == 0, "the triangle peak must be integer");
        uint64 trianglePeak = semiSbtStrikePrice / 2;
        uint64 triangleRightmost = semiSbtStrikePrice + lbtStrikePrice;
        require(
            triangleRightmost > lbtStrikePrice,
            "the triangle rightmost must be more than the LBT strike price"
        );
        require(triangleRightmost <= uint64(-2), "the strike price is too large");

        uint256[] memory semiSbtPolyline;
        {
            Point[] memory points = new Point[](3);
            points[0] = Point(sbtStrikePrice, 0);
            points[1] = Point(triangleRightmost, semiSbtStrikePrice);
            points[2] = Point(triangleRightmost + 1, semiSbtStrikePrice);
            semiSbtPolyline = _calcPolyline(points);
        }

        uint256[] memory trianglePolyline;
        {
            Point[] memory points = new Point[](4);
            points[0] = Point(sbtStrikePrice, 0);
            points[1] = Point(lbtStrikePrice, trianglePeak);
            points[2] = Point(triangleRightmost, 0);
            points[3] = Point(triangleRightmost + 1, 0);
            trianglePolyline = _calcPolyline(points);
        }

        fnMaps = new bytes[](4);
        fnMaps[0] = _getSbtFnMap(sbtStrikePrice);
        fnMaps[1] = _getLbtFnMap(lbtStrikePrice);
        fnMaps[2] = abi.encode(semiSbtPolyline);
        fnMaps[3] = abi.encode(trianglePolyline);
    }

    function _getSbtFnMap(uint64 strikePrice) internal pure returns (bytes memory fnMap) {
        Point[] memory points = new Point[](2);
        points[0] = Point(strikePrice, strikePrice);
        points[1] = Point(strikePrice + 1, strikePrice);
        uint256[] memory polyline = _calcPolyline(points);

        fnMap = abi.encode(polyline);
    }

    function _getLbtFnMap(uint64 strikePrice) internal pure returns (bytes memory fnMap) {
        Point[] memory points = new Point[](2);
        points[0] = Point(strikePrice, 0);
        points[1] = Point(strikePrice + 1, 1);
        uint256[] memory polyline = _calcPolyline(points);

        fnMap = abi.encode(polyline);
    }

    /**
     * @dev [(x_1, y_1), (x_2, y_2), ..., (x_(n-1), y_(n-1)), (x_n, y_n)]
     *   -> [(0, 0, x_1, y_1), (x_1, y_1, x_2, y_2), ..., (x_(n-1), y_(n-1), x_n, y_n)]
     */
    function _calcPolyline(Point[] memory points)
        internal
        pure
        returns (uint256[] memory polyline)
    {
        Point memory leftPoint = Point(0, 0);
        polyline = new uint256[](points.length);
        for (uint256 i = 0; i < points.length; i++) {
            Point memory rightPoint = points[i];
            polyline[i] = zipLineSegment(LineSegment(leftPoint, rightPoint));
            leftPoint = rightPoint;
        }
    }
}