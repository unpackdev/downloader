// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

/// @title Struct used across various interfaces in IPOR Protocol.
library IporTypes {
    /// @notice enum describing Swap's state, ACTIVE - when the swap is opened, INACTIVE when it's closed
    enum SwapState {
        INACTIVE,
        ACTIVE
    }

    /// @notice enum describing Swap's duration, 28 days, 60 days or 90 days
    enum SwapTenor {
        DAYS_28,
        DAYS_60,
        DAYS_90
    }

    /// @notice The struct describing the IPOR and its params calculated for the time when it was most recently updated and the change that took place since the update.
    /// Namely, the interest that would be computed into IBT should the rebalance occur.
    struct  AccruedIpor {
        /// @notice IPOR Index Value
        /// @dev value represented in 18 decimals
        uint256 indexValue;
        /// @notice IBT Price (IBT - Interest Bearing Token). For more information refer to the documentation:
        /// https://ipor-labs.gitbook.io/ipor-labs/interest-rate-derivatives/ibt
        /// @dev value represented in 18 decimals
        uint256 ibtPrice;
    }

    /// @notice Struct representing balances used internally for asset calculations
    /// @dev all balances in 18 decimals
    struct AmmBalancesMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool Balance. This balance is where the liquidity from liquidity providers and the opening fee are accounted for,
        /// @dev Amount of opening fee accounted in this balance is defined by _OPENING_FEE_FOR_TREASURY_PORTION_RATE param.
        uint256 liquidityPool;
        /// @notice Vault's balance, describes how much asset has been transferred to Asset Management Vault (AssetManagement)
        uint256 vault;
    }

    struct AmmBalancesForOpenSwapMemory {
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Fixed & Receive Floating leg.
        uint256 totalCollateralPayFixed;
        /// @notice Total notional amount of all swaps on  Pay Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalPayFixed;
        /// @notice Sum of all collateral put forward by the derivative buyer's on  Pay Floating & Receive Fixed leg.
        uint256 totalCollateralReceiveFixed;
        /// @notice Total notional amount of all swaps on  Receive Fixed leg (denominated in 18 decimals).
        uint256 totalNotionalReceiveFixed;
        /// @notice Liquidity Pool Balance.
        uint256 liquidityPool;
    }

    struct SpreadInputs {
        //// @notice Swap's assets DAI/USDC/USDT
        address asset;
        /// @notice Swap's notional value
        uint256 swapNotional;
        /// @notice demand spread factor used in demand spread calculation
        uint256 demandSpreadFactor;
        /// @notice Base spread
        int256 baseSpreadPerLeg;
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPoolBalance;
        /// @notice Ipor index value at the time of swap creation
        uint256 iporIndexValue;
        // @notice fixed rate cap for given leg for offered rate without demandSpread in 18 decimals
        uint256 fixedRateCapPerLeg;
    }
}

/// @title Spread interface for tenor 28 days service
interface ISpread60Days {
    /// @notice Calculates the quote value for a fixed 60-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateAndUpdateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 60-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateAndUpdateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);
}

/// @title Spread interface for tenor 60 days lens
interface ISpread60DaysLens {
    /// @notice Calculates the quote value for a fixed 60-day period on the pay-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the pay-fixed side.
    function calculateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Calculates the quote value for a fixed 60-day period on the receive-fixed side based on the provided spread inputs.
    /// @param spreadInputs The spread inputs required for the calculation.
    /// @return quoteValue The calculated quote value for the receive-fixed side.
    function calculateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external returns (uint256 quoteValue);

    /// @notice Returns the configuration values for the spread function used in the 60-day imbalance spread calculation.
    /// @return An array of configuration values for the spread function.
    function spreadFunction60DaysConfig() external pure returns (uint256[] memory);
}

library IporOracleErrors {
    // 200-299- iporOracle
    /// @notice Asset address not supported
    //@dev Address is not supported when lastUpdateTimestamp == 0.
    //When lastUpdateTimestamp is equal 0, then we assume that asset is not supported.
    string public constant ASSET_NOT_SUPPORTED = "IPOR_200";

    /// @notice Cannot add new asset to asset list, because it's already added
    string public constant CANNOT_ADD_ASSET_ASSET_ALREADY_EXISTS = "IPOR_201";

    /// @notice The caller must be the IporOracle updater
    string public constant CALLER_NOT_UPDATER = "IPOR_202";

    /// @notice Actual IPOR Index timestamp is higher than accrue timestamp
    string public constant INDEX_TIMESTAMP_HIGHER_THAN_ACCRUE_TIMESTAMP = "IPOR_203";

    /// @notice Address is not a valid oracle address
    string public constant INVALID_ORACLE_ADDRESS = "IPOR_204";
}

library IporErrors {
    // 000-199 - general codes

    /// @notice General problem, address is wrong
    string public constant WRONG_ADDRESS = "IPOR_000";

    /// @notice General problem. Wrong decimals
    string public constant WRONG_DECIMALS = "IPOR_001";

    /// @notice General problem, addresses mismatch
    string public constant ADDRESSES_MISMATCH = "IPOR_002";

    /// @notice Sender's asset balance is too low to transfer and to open a swap
    string public constant SENDER_ASSET_BALANCE_TOO_LOW = "IPOR_003";

    /// @notice Value is not greater than zero
    string public constant VALUE_NOT_GREATER_THAN_ZERO = "IPOR_004";

    /// @notice Input arrays length mismatch
    string public constant INPUT_ARRAYS_LENGTH_MISMATCH = "IPOR_005";

    /// @notice Amount is too low to transfer
    string public constant NOT_ENOUGH_AMOUNT_TO_TRANSFER = "IPOR_006";

    /// @notice msg.sender is not an appointed owner, so cannot confirm his appointment to be an owner of a specific smart contract
    string public constant SENDER_NOT_APPOINTED_OWNER = "IPOR_007";

    /// @notice only Router can have access to function
    string public constant CALLER_NOT_IPOR_PROTOCOL_ROUTER = "IPOR_008";

    /// @notice Chunk size is equal to zero
    string public constant CHUNK_SIZE_EQUAL_ZERO = "IPOR_009";

    /// @notice Chunk size is too big
    string public constant CHUNK_SIZE_TOO_BIG = "IPOR_010";

    /// @notice Caller is not a  guardian
    string public constant CALLER_NOT_GUARDIAN = "IPOR_011";

    /// @notice Request contains invalid method signature, which is not supported by the Ipor Protocol Router
    string public constant ROUTER_INVALID_SIGNATURE = "IPOR_012";

    /// @notice Only AMM Treasury can have access to function
    string public constant CALLER_NOT_AMM_TREASURY = "IPOR_013";

    /// @notice Caller is not an owner
    string public constant CALLER_NOT_OWNER = "IPOR_014";

    /// @notice Method is paused
    string public constant METHOD_PAUSED = "IPOR_015";

    /// @notice Reentrancy appears
    string public constant REENTRANCY = "IPOR_016";

    /// @notice Asset is not supported
    string public constant ASSET_NOT_SUPPORTED = "IPOR_017";

    /// @notice Return back ETH failed in Ipor Protocol Router
    string public constant ROUTER_RETURN_BACK_ETH_FAILED = "IPOR_018";
}

library IporContractValidator {
    function checkAddress(address addr) internal pure returns (address) {
        require(addr != address(0), IporErrors.WRONG_ADDRESS);
        return addr;
    }
}

library IporMath {
    uint256 private constant RAY = 1e27;

    //@notice Division with rounding up on last position, x, and y is with MD
    function division(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x + (y / 2)) / y;
    }

    function divisionInt(int256 x, int256 y) internal pure returns (int256 z) {
        uint256 absX = uint256(x < 0 ? -x : x);
        uint256 absY = uint256(y < 0 ? -y : y);

        // Use bitwise XOR to get the sign on MBS bit then shift to LSB
        // sign == 0x0000...0000 ==  0 if the number is non-negative
        // sign == 0xFFFF...FFFF == -1 if the number is negative
        int256 sign = (x ^ y) >> 255;

        uint256 divAbs;
        uint256 remainder;

        unchecked {
            divAbs = absX / absY;
            remainder = absX % absY;
        }
        // Check if we need to round
        if (sign < 0) {
            // remainder << 1 left shift is equivalent to multiplying by 2
            if (remainder << 1 > absY) {
                ++divAbs;
            }
        } else {
            if (remainder << 1 >= absY) {
                ++divAbs;
            }
        }

        // (sign | 1) is cheaper than (sign < 0) ? -1 : 1;
        unchecked {
            z = int256(divAbs) * (sign | 1);
        }
    }

    function divisionWithoutRound(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
    }

    function convertWadToAssetDecimals(uint256 value, uint256 assetDecimals) internal pure returns (uint256) {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return value * 10 ** (assetDecimals - 18);
        } else {
            return division(value, 10 ** (18 - assetDecimals));
        }
    }

    function convertWadToAssetDecimalsWithoutRound(
        uint256 value,
        uint256 assetDecimals
    ) internal pure returns (uint256) {
        if (assetDecimals == 18) {
            return value;
        } else if (assetDecimals > 18) {
            return value * 10 ** (assetDecimals - 18);
        } else {
            return divisionWithoutRound(value, 10 ** (18 - assetDecimals));
        }
    }

    function convertToWad(uint256 value, uint256 assetDecimals) internal pure returns (uint256) {
        if (value > 0) {
            if (assetDecimals == 18) {
                return value;
            } else if (assetDecimals > 18) {
                return division(value, 10 ** (assetDecimals - 18));
            } else {
                return value * 10 ** (18 - assetDecimals);
            }
        } else {
            return value;
        }
    }

    function absoluteValue(int256 value) internal pure returns (uint256) {
        return (uint256)(value < 0 ? -value : value);
    }

    function percentOf(uint256 value, uint256 rate) internal pure returns (uint256) {
        return division(value * rate, 1e18);
    }

    /// @notice Calculates x^n where x and y are represented in RAY (27 decimals)
    /// @param x base, represented in 27 decimals
    /// @param n exponent, represented in 27 decimals
    /// @return z x^n represented in 27 decimals
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := RAY
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := RAY
                }
                default {
                    z := x
                }
                let half := div(RAY, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, RAY)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, RAY)
                    }
                }
            }
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

/// @title Errors which occur inside AmmTreasury's method execution.
library AmmErrors {
    // 300-399-AMM
    /// @notice Liquidity Pool balance is equal 0.
    string public constant LIQUIDITY_POOL_IS_EMPTY = "IPOR_300";

    /// @notice Liquidity Pool balance is too low, should be equal or higher than 0.
    string public constant LIQUIDITY_POOL_AMOUNT_TOO_LOW = "IPOR_301";

    /// @notice Liquidity Pool Collateral Ratio exceeded. Liquidity Pool Collateral Ratio is higher than configured in AmmTreasury maximum liquidity pool collateral ratio.
    string public constant LP_COLLATERAL_RATIO_EXCEEDED = "IPOR_302";

    /// @notice Liquidity Pool Collateral Ratio Per Leg exceeded. Liquidity Pool Collateral Ratio per leg is higher than configured in AmmTreasury maximum liquidity pool collateral ratio per leg.
    string public constant LP_COLLATERAL_RATIO_PER_LEG_EXCEEDED = "IPOR_303";

    /// @notice Liquidity Pool Balance is too high
    string public constant LIQUIDITY_POOL_BALANCE_IS_TOO_HIGH = "IPOR_304";

    /// @notice Swap cannot be closed because liquidity pool is too low for payid out cash. Situation should never happen where Liquidity Pool is insolvent.
    string public constant CANNOT_CLOSE_SWAP_LP_IS_TOO_LOW = "IPOR_305";

    /// @notice Swap id used in input has incorrect value (like 0) or not exists.
    string public constant INCORRECT_SWAP_ID = "IPOR_306";

    /// @notice Swap has incorrect status.
    string public constant INCORRECT_SWAP_STATUS = "IPOR_307";

    /// @notice Leverage given as a parameter when opening swap is lower than configured in AmmTreasury minimum leverage.
    string public constant LEVERAGE_TOO_LOW = "IPOR_308";

    /// @notice Leverage given as a parameter when opening swap is higher than configured in AmmTreasury maxumum leverage.
    string public constant LEVERAGE_TOO_HIGH = "IPOR_309";

    /// @notice Total amount given as a parameter when opening swap is too low. Cannot be equal zero.
    string public constant TOTAL_AMOUNT_TOO_LOW = "IPOR_310";

    /// @notice Total amount given as a parameter when opening swap is lower than sum of liquidation deposit amount and ipor publication fee.
    string public constant TOTAL_AMOUNT_LOWER_THAN_FEE = "IPOR_311";

    /// @notice Amount of collateral used to open swap is higher than configured in AmmTreasury max swap collateral amount
    string public constant COLLATERAL_AMOUNT_TOO_HIGH = "IPOR_312";

    /// @notice Acceptable fixed interest rate defined by traded exceeded.
    string public constant ACCEPTABLE_FIXED_INTEREST_RATE_EXCEEDED = "IPOR_313";

    /// @notice Swap Notional Amount is higher than Total Notional for specific leg.
    string public constant SWAP_NOTIONAL_HIGHER_THAN_TOTAL_NOTIONAL = "IPOR_314";

    /// @notice Number of swaps per leg which are going to be liquidated is too high, is higher than configured in AmmTreasury liquidation leg limit.
    string public constant MAX_LENGTH_LIQUIDATED_SWAPS_PER_LEG_EXCEEDED = "IPOR_315";

    /// @notice Sum of SOAP and Liquidity Pool Balance is lower than zero.
    /// @dev SOAP can be negative, Sum of SOAP and Liquidity Pool Balance can be negative, but this is undesirable.
    string public constant SOAP_AND_LP_BALANCE_SUM_IS_TOO_LOW = "IPOR_316";

    /// @notice Calculation timestamp is earlier than last SOAP rebalance timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SOAP_REBALANCE_TIMESTAMP = "IPOR_317";

    /// @notice Calculation timestamp is lower than  Swap's open timestamp.
    string public constant CALC_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_318";

    /// @notice Closing timestamp is lower than Swap's open timestamp.
    string public constant CLOSING_TIMESTAMP_LOWER_THAN_SWAP_OPEN_TIMESTAMP = "IPOR_319";

    /// @notice Swap cannot be closed because sender is not a buyer nor liquidator.
    string public constant CANNOT_CLOSE_SWAP_SENDER_IS_NOT_BUYER_NOR_LIQUIDATOR = "IPOR_320";

    /// @notice Interest from Strategy is below zero.
    string public constant INTEREST_FROM_STRATEGY_EXCEEDED_THRESHOLD = "IPOR_321";

    /// @notice IPOR publication fee balance is too low.
    string public constant PUBLICATION_FEE_BALANCE_IS_TOO_LOW = "IPOR_322";

    /// @notice The caller must be the Token Manager (Smart Contract responsible for managing token total supply).
    string public constant CALLER_NOT_TOKEN_MANAGER = "IPOR_323";

    /// @notice Deposit amount is too low.
    string public constant DEPOSIT_AMOUNT_IS_TOO_LOW = "IPOR_324";

    /// @notice Vault balance is lower than deposit value.
    string public constant VAULT_BALANCE_LOWER_THAN_DEPOSIT_VALUE = "IPOR_325";

    /// @notice Treasury balance is too low.
    string public constant TREASURY_BALANCE_IS_TOO_LOW = "IPOR_326";

    /// @notice Swap cannot be closed because closing timestamp is lower than swap's open timestamp in general.
    string public constant CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY = "IPOR_327";

    /// @notice Swap cannot be closed because closing timestamp is lower than swap's open timestamp for buyer.
    string public constant CANNOT_CLOSE_SWAP_CLOSING_IS_TOO_EARLY_FOR_BUYER = "IPOR_328";

    /// @notice Swap cannot be closed and unwind because is too late
    string public constant CANNOT_UNWIND_CLOSING_TOO_LATE = "IPOR_329";

    /// @notice Unsupported swap tenor
    string public constant UNSUPPORTED_SWAP_TENOR = "IPOR_330";

    /// @notice Sender is not AMM (is not a IporProtocolRouter contract)
    string public constant SENDER_NOT_AMM = "IPOR_331";

    /// @notice Storage id is not time weighted notional group
    string public constant STORAGE_ID_IS_NOT_TIME_WEIGHTED_NOTIONAL = "IPOR_332";

    /// @notice Spread function is not supported
    string public constant FUNCTION_NOT_SUPPORTED = "IPOR_333";

    /// @notice Unsupported direction
    string public constant UNSUPPORTED_DIRECTION = "IPOR_334";

    /// @notice Invalid notional
    string public constant INVALID_NOTIONAL = "IPOR_335";

    /// @notice Average interest rate cannot be zero when open swap
    string public constant AVERAGE_INTEREST_RATE_WHEN_OPEN_SWAP_CANNOT_BE_ZERO = "IPOR_336";

    /// @notice Average interest rate cannot be zero when close swap
    string public constant AVERAGE_INTEREST_RATE_WHEN_CLOSE_SWAP_CANNOT_BE_ZERO = "IPOR_337";

    /// @notice Submit ETH to stETH contract failed.
    string public constant STETH_SUBMIT_FAILED = "IPOR_338";

    /// @notice Collateral is not sufficient to cover unwind swap
    string public constant COLLATERAL_IS_NOT_SUFFICIENT_TO_COVER_UNWIND_SWAP = "IPOR_339";

    /// @notice Error when withdraw from asset management is not enough to cover transfer amount to buyer and/or beneficiary
    string public constant ASSET_MANAGEMENT_WITHDRAW_NOT_ENOUGH = "IPOR_340";
}

/// @title Spread storage library
library SpreadStorageLibs {
    using SafeCast for uint256;
    uint256 private constant STORAGE_SLOT_BASE = 10_000;

    /// Only allowed to append new value to the end of the enum
    enum StorageId {
        // address
        Owner,
        // address
        AppointedOwner,
        // uint256
        Paused,
        // WeightedNotionalStorage
        TimeWeightedNotional28DaysDai,
        TimeWeightedNotional28DaysUsdc,
        TimeWeightedNotional28DaysUsdt,
        TimeWeightedNotional60DaysDai,
        TimeWeightedNotional60DaysUsdc,
        TimeWeightedNotional60DaysUsdt,
        TimeWeightedNotional90DaysDai,
        TimeWeightedNotional90DaysUsdc,
        TimeWeightedNotional90DaysUsdt
    }

    /// @notice Struct which contains owner address of Spread Router
    struct OwnerStorage {
        address owner;
    }

    /// @notice Struct which contains pause flag on Spread Router
    struct PausedStorage {
        uint256 value;
    }

    /// @notice Struct which contains address of appointed owner of Spread Router
    struct AppointedOwnerStorage {
        address appointedOwner;
    }

    /// @notice Saves time weighted notional for a specific asset and tenor
    /// @param timeWeightedNotionalStorageId The storage ID of the time weighted notional
    /// @param timeWeightedNotional The time weighted notional to save
    function saveTimeWeightedNotionalForAssetAndTenor(
        StorageId timeWeightedNotionalStorageId,
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional
    ) internal {
        _checkTimeWeightedNotional(timeWeightedNotionalStorageId);
        uint256 timeWeightedNotionalPayFixedTemp;
        uint256 timeWeightedNotionalReceiveFixedTemp;
        unchecked {
            timeWeightedNotionalPayFixedTemp = timeWeightedNotional.timeWeightedNotionalPayFixed / 1e18;

            timeWeightedNotionalReceiveFixedTemp = timeWeightedNotional.timeWeightedNotionalReceiveFixed / 1e18;
        }

        uint96 timeWeightedNotionalPayFixed = timeWeightedNotionalPayFixedTemp.toUint96();
        uint32 lastUpdateTimePayFixed = timeWeightedNotional.lastUpdateTimePayFixed.toUint32();
        uint96 timeWeightedNotionalReceiveFixed = timeWeightedNotionalReceiveFixedTemp.toUint96();
        uint32 lastUpdateTimeReceiveFixed = timeWeightedNotional.lastUpdateTimeReceiveFixed.toUint32();
        uint256 slotAddress = _getStorageSlot(timeWeightedNotionalStorageId);
        assembly {
            let value := add(
                timeWeightedNotionalPayFixed,
                add(
                    shl(96, lastUpdateTimePayFixed),
                    add(shl(128, timeWeightedNotionalReceiveFixed), shl(224, lastUpdateTimeReceiveFixed))
                )
            )
            sstore(slotAddress, value)
        }
    }

    /// @notice Gets the time-weighted notional for a specific storage ID representing an asset and tenor
    /// @param timeWeightedNotionalStorageId The storage ID of the time weighted notional
    function getTimeWeightedNotionalForAssetAndTenor(
        StorageId timeWeightedNotionalStorageId
    ) internal view returns (SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional28Days) {
        _checkTimeWeightedNotional(timeWeightedNotionalStorageId);
        uint256 timeWeightedNotionalPayFixed;
        uint256 lastUpdateTimePayFixed;
        uint256 timeWeightedNotionalReceiveFixed;
        uint256 lastUpdateTimeReceiveFixed;
        uint256 slotAddress = _getStorageSlot(timeWeightedNotionalStorageId);
        assembly {
            let slotValue := sload(slotAddress)
            timeWeightedNotionalPayFixed := mul(and(slotValue, 0xFFFFFFFFFFFFFFFFFFFFFFFF), 1000000000000000000)
            lastUpdateTimePayFixed := and(shr(96, slotValue), 0xFFFFFFFF)
            timeWeightedNotionalReceiveFixed := mul(
                and(shr(128, slotValue), 0xFFFFFFFFFFFFFFFFFFFFFFFF),
                1000000000000000000
            )
            lastUpdateTimeReceiveFixed := and(shr(224, slotValue), 0xFFFFFFFF)
        }

        return
            SpreadTypes.TimeWeightedNotionalMemory({
                timeWeightedNotionalPayFixed: timeWeightedNotionalPayFixed,
                lastUpdateTimePayFixed: lastUpdateTimePayFixed,
                timeWeightedNotionalReceiveFixed: timeWeightedNotionalReceiveFixed,
                lastUpdateTimeReceiveFixed: lastUpdateTimeReceiveFixed,
                storageId: timeWeightedNotionalStorageId
            });
    }

    /// @notice Gets all time weighted notional storage IDs
    function getAllStorageId() internal pure returns (StorageId[] memory storageIds, string[] memory keys) {
        storageIds = new StorageId[](9);
        keys = new string[](9);
        storageIds[0] = StorageId.TimeWeightedNotional28DaysDai;
        keys[0] = "TimeWeightedNotional28DaysDai";
        storageIds[1] = StorageId.TimeWeightedNotional28DaysUsdc;
        keys[1] = "TimeWeightedNotional28DaysUsdc";
        storageIds[2] = StorageId.TimeWeightedNotional28DaysUsdt;
        keys[2] = "TimeWeightedNotional28DaysUsdt";
        storageIds[3] = StorageId.TimeWeightedNotional60DaysDai;
        keys[3] = "TimeWeightedNotional60DaysDai";
        storageIds[4] = StorageId.TimeWeightedNotional60DaysUsdc;
        keys[4] = "TimeWeightedNotional60DaysUsdc";
        storageIds[5] = StorageId.TimeWeightedNotional60DaysUsdt;
        keys[5] = "TimeWeightedNotional60DaysUsdt";
        storageIds[6] = StorageId.TimeWeightedNotional90DaysDai;
        keys[6] = "TimeWeightedNotional90DaysDai";
        storageIds[7] = StorageId.TimeWeightedNotional90DaysUsdc;
        keys[7] = "TimeWeightedNotional90DaysUsdc";
        storageIds[8] = StorageId.TimeWeightedNotional90DaysUsdt;
        keys[8] = "TimeWeightedNotional90DaysUsdt";
    }

    /// @notice Gets the owner of the Spread Router
    /// @return owner The owner of the Spread Router
    function getOwner() internal pure returns (OwnerStorage storage owner) {
        uint256 slotAddress = _getStorageSlot(StorageId.Owner);
        assembly {
            owner.slot := slotAddress
        }
    }

    /// @notice Gets the appointed owner of the Spread Router
    /// @return appointedOwner The appointed owner of the Spread Router
    function getAppointedOwner() internal pure returns (AppointedOwnerStorage storage appointedOwner) {
        uint256 slotAddress = _getStorageSlot(StorageId.AppointedOwner);
        assembly {
            appointedOwner.slot := slotAddress
        }
    }

    /// @notice Gets the paused state of the Spread Router
    /// @return paused The paused state of the Spread Router
    function getPaused() internal pure returns (PausedStorage storage paused) {
        uint256 slotAddress = _getStorageSlot(StorageId.Paused);
        assembly {
            paused.slot := slotAddress
        }
    }

    function _getStorageSlot(StorageId storageId) internal pure returns (uint256 slot) {
        slot = uint256(storageId) + STORAGE_SLOT_BASE;
    }

    function _checkTimeWeightedNotional(StorageId storageId) internal pure {
        require(
            storageId == StorageId.TimeWeightedNotional28DaysDai ||
                storageId == StorageId.TimeWeightedNotional28DaysUsdc ||
                storageId == StorageId.TimeWeightedNotional28DaysUsdt ||
                storageId == StorageId.TimeWeightedNotional60DaysDai ||
                storageId == StorageId.TimeWeightedNotional60DaysUsdc ||
                storageId == StorageId.TimeWeightedNotional60DaysUsdt ||
                storageId == StorageId.TimeWeightedNotional90DaysDai ||
                storageId == StorageId.TimeWeightedNotional90DaysUsdc ||
                storageId == StorageId.TimeWeightedNotional90DaysUsdt,
            AmmErrors.STORAGE_ID_IS_NOT_TIME_WEIGHTED_NOTIONAL
        );
    }
}

library SpreadTypes {
    /// @notice structure used to save the weighted notional for the 28 days into storage
    /// timeWeightedNotionalPayFixed without decimals - uint96 - bytes 0-96
    /// lastUpdateTimePayFixed - uint32 - bytes 96-128
    /// timeWeightedNotionalReceiveFixed  without decimals - uint96 - bytes 128-224
    /// lastUpdateTimeReceiveFixed - uint32 - bytes 224-256
    struct WeightedNotionalStorage {
        bytes32 weightedNotional;
    }

    /// @notice Dto for the Weighted Notional
    struct TimeWeightedNotionalMemory {
        /// @notice timeWeightedNotionalPayFixed with 18 decimals
        uint256 timeWeightedNotionalPayFixed;
        /// @notice lastUpdateTimePayFixed timestamp in seconds
        uint256 lastUpdateTimePayFixed;
        /// @notice timeWeightedNotionalReceiveFixed with 18 decimals
        uint256 timeWeightedNotionalReceiveFixed;
        /// @notice lastUpdateTimeReceiveFixed timestamp in seconds
        uint256 lastUpdateTimeReceiveFixed;
        /// @notice storageId from SpreadStorageLibs
        SpreadStorageLibs.StorageId storageId;
    }

    /// @notice Technical structure used in Lens for the Weighted Notional params
    struct TimeWeightedNotionalResponse {
        /// @notice timeWeightedNotionalPayFixed time weighted notional params
        TimeWeightedNotionalMemory timeWeightedNotional;
        string key;
    }
}

library CalculateTimeWeightedNotionalLibs {
    /// @notice calculate amm lp depth
    /// @param liquidityPoolBalance liquidity pool balance
    /// @param totalCollateralPayFixed total collateral pay fixed
    /// @param totalCollateralReceiveFixed total collateral receive fixed
    function calculateLpDepth(
        uint256 liquidityPoolBalance,
        uint256 totalCollateralPayFixed,
        uint256 totalCollateralReceiveFixed
    ) internal pure returns (uint256 lpDepth) {
        if (totalCollateralPayFixed >= totalCollateralReceiveFixed) {
            lpDepth = liquidityPoolBalance + totalCollateralReceiveFixed - totalCollateralPayFixed;
        } else {
            lpDepth = liquidityPoolBalance + totalCollateralPayFixed - totalCollateralReceiveFixed;
        }
    }

    /// @notice calculate weighted notional
    /// @param timeWeightedNotional weighted notional value
    /// @param timeFromLastUpdate time from last update in seconds
    /// @param tenorInSeconds tenor in seconds
    function calculateTimeWeightedNotional(
        uint256 timeWeightedNotional,
        uint256 timeFromLastUpdate,
        uint256 tenorInSeconds
    ) internal pure returns (uint256) {
        if (timeFromLastUpdate >= tenorInSeconds) {
            return 0;
        }
        uint256 newTimeWeightedNotional = IporMath.divisionWithoutRound(
            timeWeightedNotional * (tenorInSeconds - timeFromLastUpdate),
            tenorInSeconds
        );
        return newTimeWeightedNotional;
    }

    /// @notice Updates the time-weighted notional value for the receive fixed leg.
    /// @param timeWeightedNotional The memory struct containing the time-weighted notional information.
    /// @param newSwapNotional The new swap notional value.
    /// @param tenorInSeconds Tenor in seconds.
    /// @dev This function is internal and used to update the time-weighted notional value for the receive fixed leg.
    function updateTimeWeightedNotionalReceiveFixed(
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional,
        uint256 newSwapNotional,
        uint256 tenorInSeconds
    ) internal {
        if (timeWeightedNotional.timeWeightedNotionalReceiveFixed == 0) {
            timeWeightedNotional.timeWeightedNotionalReceiveFixed = calculateTimeWeightedNotional(
                newSwapNotional,
                0,
                tenorInSeconds
            );
        } else {
            uint256 oldWeightedNotionalReceiveFixed = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalReceiveFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimeReceiveFixed,
                tenorInSeconds
            );
            timeWeightedNotional.timeWeightedNotionalReceiveFixed = newSwapNotional + oldWeightedNotionalReceiveFixed;
        }
        timeWeightedNotional.lastUpdateTimeReceiveFixed = block.timestamp;
        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(timeWeightedNotional.storageId, timeWeightedNotional);
    }

    /// @notice Updates the time-weighted notional value for the pay fixed leg.
    /// @param timeWeightedNotional The memory struct containing the time-weighted notional information.
    /// @param newSwapNotional The new swap notional value.
    /// @param tenorInSeconds Tenor in seconds.
    /// @dev This function is internal and used to update the time-weighted notional value for the pay fixed leg.
    function updateTimeWeightedNotionalPayFixed(
        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional,
        uint256 newSwapNotional,
        uint256 tenorInSeconds
    ) internal {
        if (timeWeightedNotional.timeWeightedNotionalPayFixed == 0) {
            timeWeightedNotional.timeWeightedNotionalPayFixed = calculateTimeWeightedNotional(
                newSwapNotional,
                0,
                tenorInSeconds
            );
        } else {
            uint256 oldWeightedNotionalPayFixed = calculateTimeWeightedNotional(
                timeWeightedNotional.timeWeightedNotionalPayFixed,
                block.timestamp - timeWeightedNotional.lastUpdateTimePayFixed,
                tenorInSeconds
            );
            timeWeightedNotional.timeWeightedNotionalPayFixed = newSwapNotional + oldWeightedNotionalPayFixed;
        }
        timeWeightedNotional.lastUpdateTimePayFixed = block.timestamp;
        SpreadStorageLibs.saveTimeWeightedNotionalForAssetAndTenor(timeWeightedNotional.storageId, timeWeightedNotional);
    }

    /// @notice Calculates the time-weighted notional values for the pay fixed and receive fixed legs.
    /// @param timeWeightedNotionalStorageIds The array of storage IDs representing the time-weighted notional storage locations.
    /// @param tenorsInSeconds The array of maturities corresponding to each storage ID.
    /// @param selectedTenorInSeconds The tenor in seconds used to calculate the time-weighted notional values.
    /// @return timeWeightedNotionalPayFixed The aggregated time-weighted notional value for the pay fixed leg.
    /// @return timeWeightedNotionalReceiveFixed The aggregated time-weighted notional value for the receive fixed leg.
    /// @dev This function is internal and used to calculate the aggregated time-weighted notional values for multiple storage IDs and maturities.
    function getTimeWeightedNotional(
        SpreadStorageLibs.StorageId[] memory timeWeightedNotionalStorageIds,
        uint256[] memory tenorsInSeconds,
        uint256 selectedTenorInSeconds
    ) internal view returns (uint256 timeWeightedNotionalPayFixed, uint256 timeWeightedNotionalReceiveFixed) {
        uint256 length = timeWeightedNotionalStorageIds.length;

        SpreadTypes.TimeWeightedNotionalMemory memory timeWeightedNotional;
        uint256 timeWeightedNotionalPayFixedIteration;
        uint256 timeWeightedNotionalReceiveFixedIteration;

        for (uint256 i; i != length; ) {
            timeWeightedNotional = SpreadStorageLibs.getTimeWeightedNotionalForAssetAndTenor(timeWeightedNotionalStorageIds[i]);
            timeWeightedNotionalPayFixedIteration = _isTimeWeightedNotionalRecalculationRequired(
                timeWeightedNotional.lastUpdateTimePayFixed,
                tenorsInSeconds[i],
                selectedTenorInSeconds
            )
                ? calculateTimeWeightedNotional(
                    timeWeightedNotional.timeWeightedNotionalPayFixed,
                    block.timestamp - timeWeightedNotional.lastUpdateTimePayFixed,
                    tenorsInSeconds[i]
                )
                : timeWeightedNotional.timeWeightedNotionalPayFixed;
            timeWeightedNotionalPayFixed = timeWeightedNotionalPayFixed + timeWeightedNotionalPayFixedIteration;

            timeWeightedNotionalReceiveFixedIteration = _isTimeWeightedNotionalRecalculationRequired(
                timeWeightedNotional.lastUpdateTimeReceiveFixed,
                tenorsInSeconds[i],
                selectedTenorInSeconds
            )
                ? calculateTimeWeightedNotional(
                    timeWeightedNotional.timeWeightedNotionalReceiveFixed,
                    block.timestamp - timeWeightedNotional.lastUpdateTimeReceiveFixed,
                    tenorsInSeconds[i]
                )
                : timeWeightedNotional.timeWeightedNotionalReceiveFixed;
            timeWeightedNotionalReceiveFixed = timeWeightedNotionalReceiveFixedIteration + timeWeightedNotionalReceiveFixed;

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Determines if the time-weighted notional should be recalculated based on the last update time and tenors.
    /// @param lastUpdateTime The last time the notional was updated.
    /// @param iterationTenorInSeconds The tenor duration in seconds.
    /// @param selectedTenorInSeconds The duration in seconds for which the spread should be calculated for a given tenor.
    /// @dev This function is internal and used to decide if a recalculation of the time-weighted notional is necessary.
    function _isTimeWeightedNotionalRecalculationRequired(
        uint256 lastUpdateTime,
        uint256 iterationTenorInSeconds,
        uint256 selectedTenorInSeconds
    ) internal view returns (bool) {
        return iterationTenorInSeconds + lastUpdateTime < block.timestamp + selectedTenorInSeconds;
    }
}

library DemandSpreadLibs {
    uint256 internal constant INTERVAL_ONE = 2e17;
    uint256 internal constant INTERVAL_TWO = 5e17;
    uint256 internal constant INTERVAL_THREE = 1e18;

    uint256 internal constant SLOPE_ONE = 5e16;
    uint256 internal constant BASE_ONE = 0;

    uint256 internal constant SLOPE_TWO = 133333333333333333;
    uint256 internal constant BASE_TWO = 16666666666666667;

    uint256 internal constant SLOPE_THREE = 5e17;
    uint256 internal constant BASE_THREE = 2e17;

    /// @notice DTO for the Weighted Notional
    struct SpreadInputData {
        /// @notice Swap's balance for Pay Fixed leg
        uint256 totalCollateralPayFixed;
        /// @notice Swap's balance for Receive Fixed leg
        uint256 totalCollateralReceiveFixed;
        /// @notice Liquidity Pool's Balance
        uint256 liquidityPoolBalance;
        /// @notice Swap's notional
        uint256 swapNotional;
        /// @notice demand spread factor used in demand spread calculation, value without decimals
        uint256 demandSpreadFactor;
        /// @notice List of supported tenors in seconds
        uint256[] tenorsInSeconds;
        /// @notice List of storage ids for a TimeWeightedNotional for all tenors for a given asset
        SpreadStorageLibs.StorageId[] timeWeightedNotionalStorageIds;
        /// @notice Storage id for a TimeWeightedNotional for a specific tenor and asset.
        SpreadStorageLibs.StorageId timeWeightedNotionalStorageId;
        // @notice Calculation for tenor in seconds
        uint256 selectedTenorInSeconds;
    }

    /// @notice Gets the spread function configuration.
    function spreadFunctionConfig() internal pure returns (uint256[] memory) {
        uint256[] memory config = new uint256[](21);
        config[0] = INTERVAL_ONE;
        config[1] = INTERVAL_TWO;
        config[2] = INTERVAL_THREE;
        config[3] = SLOPE_ONE;
        config[4] = BASE_ONE;
        config[5] = SLOPE_TWO;
        config[6] = BASE_TWO;
        config[7] = SLOPE_THREE;
        config[8] = BASE_THREE;
        return config;
    }

    /// @notice Calculates the spread value for the pay-fixed side based on the provided input data.
    /// @param inputData The input data required for the calculation, including liquidity pool information and collateral amounts.
    /// @return spreadValue The calculated spread value for the pay-fixed side.
    function calculatePayFixedSpread(SpreadInputData memory inputData) internal view returns (uint256 spreadValue) {
        uint256 lpDepth = CalculateTimeWeightedNotionalLibs.calculateLpDepth(
            inputData.liquidityPoolBalance,
            inputData.totalCollateralPayFixed,
            inputData.totalCollateralReceiveFixed
        );

        /// @dev demandSpreadFactor is without decimals.
        uint256 notionalDepth = lpDepth * inputData.demandSpreadFactor;

        (
            uint256 oldWeightedNotionalPayFixed,
            uint256 timeWeightedNotionalReceiveFixed
        ) = CalculateTimeWeightedNotionalLibs.getTimeWeightedNotional(
                inputData.timeWeightedNotionalStorageIds,
                inputData.tenorsInSeconds,
                inputData.selectedTenorInSeconds
            );

        uint256 newWeightedNotionalPayFixed = oldWeightedNotionalPayFixed + inputData.swapNotional;

        if (newWeightedNotionalPayFixed > timeWeightedNotionalReceiveFixed) {
            uint256 oldSpread;

            if (oldWeightedNotionalPayFixed > timeWeightedNotionalReceiveFixed) {
                oldSpread = calculateSpreadFunction(
                    notionalDepth,
                    oldWeightedNotionalPayFixed - timeWeightedNotionalReceiveFixed
                );
            }

            uint256 newSpread = calculateSpreadFunction(
                notionalDepth,
                newWeightedNotionalPayFixed - timeWeightedNotionalReceiveFixed
            );

            spreadValue = IporMath.division(oldSpread + newSpread, 2);
        } else {
            spreadValue = 0;
        }
    }

    /// @notice Calculates the spread value for the receive-fixed side based on the provided input data.
    /// @param inputData The input data required for the calculation, including liquidity pool information and collateral amounts.
    /// @return spreadValue The calculated spread value for the receive-fixed side.
    function calculateReceiveFixedSpread(SpreadInputData memory inputData) internal view returns (uint256 spreadValue) {
        uint256 lpDepth = CalculateTimeWeightedNotionalLibs.calculateLpDepth(
            inputData.liquidityPoolBalance,
            inputData.totalCollateralPayFixed,
            inputData.totalCollateralReceiveFixed
        );

        /// @dev demandSpreadFactor is without decimals.
        uint256 notionalDepth = lpDepth * inputData.demandSpreadFactor;

        (
            uint256 timeWeightedNotionalPayFixed,
            uint256 oldWeightedNotionalReceiveFixed
        ) = CalculateTimeWeightedNotionalLibs.getTimeWeightedNotional(
                inputData.timeWeightedNotionalStorageIds,
                inputData.tenorsInSeconds,
                inputData.selectedTenorInSeconds
            );

        uint256 newWeightedNotionalReceiveFixed = oldWeightedNotionalReceiveFixed + inputData.swapNotional;

        if (newWeightedNotionalReceiveFixed > timeWeightedNotionalPayFixed) {
            uint256 oldSpread;

            if (oldWeightedNotionalReceiveFixed > timeWeightedNotionalPayFixed) {
                oldSpread = calculateSpreadFunction(
                    notionalDepth,
                    oldWeightedNotionalReceiveFixed - timeWeightedNotionalPayFixed
                );
            }

            uint256 newSpread = calculateSpreadFunction(
                notionalDepth,
                newWeightedNotionalReceiveFixed - timeWeightedNotionalPayFixed
            );

            spreadValue = IporMath.division(oldSpread + newSpread, 2);
        } else {
            spreadValue = 0;
        }
    }

    /// @notice Calculates the spread value based on the given maximum notional and weighted notional.
    /// @param maxNotional The maximum notional value determined by lpDepth and demandSpreadFactor from Risk Oracle
    /// @param weightedNotional The weighted notional value used in the spread calculation.
    /// @return spreadValue The calculated spread value based on the given inputs.
    /// @dev maxNotional = lpDepth * demandSpreadFactor
    function calculateSpreadFunction(
        uint256 maxNotional,
        uint256 weightedNotional
    ) internal pure returns (uint256 spreadValue) {
        uint256 ratio = IporMath.division(weightedNotional * 1e18, maxNotional);
        if (ratio < INTERVAL_ONE) {
            spreadValue = IporMath.division(SLOPE_ONE * ratio, 1e18) - BASE_ONE;
            /// @dev spreadValue in range < 0%, 1% )
        } else if (ratio < INTERVAL_TWO) {
            spreadValue = IporMath.division(SLOPE_TWO * ratio, 1e18) - BASE_TWO;
            /// @dev spreadValue in range < 1%, 5% )
        } else if (ratio < INTERVAL_THREE) {
            spreadValue = IporMath.division(SLOPE_THREE * ratio, 1e18) - BASE_THREE;
            /// @dev spreadValue in range < 5%, 30% )
        } else {
            spreadValue = 3 * 1e17;
            /// @dev spreadValue is equal to 30%
        }
    }
}

/// @title Offered rate calculation library
library OfferedRateCalculationLibs {
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice Calculates the offered rate for the pay-fixed side based on the provided spread and risk inputs.
    /// @param iporIndexValue The IPOR index value.
    /// @param baseSpreadPerLeg The base spread per leg.
    /// @param demandSpread The demand spread.
    /// @param payFixedMinCap The pay-fixed minimum cap.
    /// @return offeredRate The calculated offered rate for pay-fixed side.
    function calculatePayFixedOfferedRate(
        uint256 iporIndexValue,
        int256 baseSpreadPerLeg,
        uint256 demandSpread,
        uint256 payFixedMinCap
    ) internal pure returns (uint256 offeredRate) {
        int256 baseOfferedRate = iporIndexValue.toInt256() + baseSpreadPerLeg;

        if (baseOfferedRate > payFixedMinCap.toInt256()) {
            offeredRate = baseOfferedRate.toUint256() + demandSpread;
        } else {
            offeredRate = payFixedMinCap + demandSpread;
        }
    }

    /// @notice Calculates the offered rate for the receive-fixed side based on the provided spread and risk inputs.
    /// @param iporIndexValue The IPOR index value.
    /// @param baseSpreadPerLeg The base spread per leg.
    /// @param demandSpread The demand spread.
    /// @param receiveFixedMaxCap The receive-fixed maximum cap.
    /// @return offeredRate The calculated offered rate for receive-fixed side.
    function calculateReceiveFixedOfferedRate(
        uint256 iporIndexValue,
        int256 baseSpreadPerLeg,
        uint256 demandSpread,
        uint256 receiveFixedMaxCap
    ) internal pure returns (uint256 offeredRate) {
        int256 baseOfferedRate = iporIndexValue.toInt256() + baseSpreadPerLeg;

        int256 temp;
        if (baseOfferedRate < receiveFixedMaxCap.toInt256()) {
            temp = baseOfferedRate - demandSpread.toInt256();
        } else {
            temp = receiveFixedMaxCap.toInt256() - demandSpread.toInt256();
        }
        offeredRate = temp < 0 ? 0 : temp.toUint256();
    }
}

/// @dev This contract cannot be used directly, should be used only through SpreadRouter.
contract Spread60Days is ISpread60Days, ISpread60DaysLens {
    using IporContractValidator for address;
    using SafeCast for uint256;
    using SafeCast for int256;

    address internal immutable _dai;
    address internal immutable _usdc;
    address internal immutable _usdt;

    constructor(address dai, address usdc, address usdt) {
        _dai = dai.checkAddress();
        _usdc = usdc.checkAddress();
        _usdt = usdt.checkAddress();
    }

    function calculateAndUpdateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibs.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixedAndUpdateTimeWeightedNotional60Day(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateOfferedRatePayFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibs.calculatePayFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandPayFixed60Day(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateAndUpdateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibs.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandReceiveFixedAndUpdateTimeWeightedNotional60Day(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function calculateOfferedRateReceiveFixed60Days(
        IporTypes.SpreadInputs calldata spreadInputs
    ) external view override returns (uint256 offeredRate) {
        offeredRate = OfferedRateCalculationLibs.calculateReceiveFixedOfferedRate(
            spreadInputs.iporIndexValue,
            spreadInputs.baseSpreadPerLeg,
            _calculateDemandReceiveFixed60Day(spreadInputs),
            spreadInputs.fixedRateCapPerLeg
        );
    }

    function getSupportedAssets() external view returns (address[] memory) {
        address[] memory assets = new address[](3);
        assets[0] = _dai;
        assets[1] = _usdc;
        assets[2] = _usdt;
        return assets;
    }

    function spreadFunction60DaysConfig() external pure returns (uint256[] memory) {
        return DemandSpreadLibs.spreadFunctionConfig();
    }

    function _calculateDemandPayFixed60Day(
        IporTypes.SpreadInputs memory spreadInputs
    ) internal view returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);
        spreadValue = DemandSpreadLibs.calculatePayFixedSpread(inputData);
    }

    function _calculateDemandPayFixedAndUpdateTimeWeightedNotional60Day(
        IporTypes.SpreadInputs memory spreadInputs
    ) internal returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibs.calculatePayFixedSpread(inputData);

        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibs
            .getTimeWeightedNotionalForAssetAndTenor(inputData.timeWeightedNotionalStorageId);

        CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalPayFixed(
            weightedNotional,
            inputData.swapNotional,
            60 days
        );
    }

    function _calculateDemandReceiveFixed60Day(
        IporTypes.SpreadInputs calldata spreadInputs
    ) internal view returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibs.calculateReceiveFixedSpread(inputData);
    }

    function _calculateDemandReceiveFixedAndUpdateTimeWeightedNotional60Day(
        IporTypes.SpreadInputs calldata spreadInputs
    ) internal returns (uint256 spreadValue) {
        DemandSpreadLibs.SpreadInputData memory inputData = _getSpreadConfigForDemand(spreadInputs);

        spreadValue = DemandSpreadLibs.calculateReceiveFixedSpread(inputData);

        SpreadTypes.TimeWeightedNotionalMemory memory weightedNotional = SpreadStorageLibs
            .getTimeWeightedNotionalForAssetAndTenor(inputData.timeWeightedNotionalStorageId);

        CalculateTimeWeightedNotionalLibs.updateTimeWeightedNotionalReceiveFixed(
            weightedNotional,
            inputData.swapNotional,
            60 days
        );
    }

    function _getSpreadConfigForDemand(
        IporTypes.SpreadInputs memory spreadInputs
    ) internal view returns (DemandSpreadLibs.SpreadInputData memory inputData) {
        inputData = DemandSpreadLibs.SpreadInputData({
            totalCollateralPayFixed: spreadInputs.totalCollateralPayFixed,
            totalCollateralReceiveFixed: spreadInputs.totalCollateralReceiveFixed,
            liquidityPoolBalance: spreadInputs.liquidityPoolBalance,
            swapNotional: spreadInputs.swapNotional,
            demandSpreadFactor: spreadInputs.demandSpreadFactor,
            tenorsInSeconds: new uint256[](3),
            timeWeightedNotionalStorageIds: new SpreadStorageLibs.StorageId[](3),
            timeWeightedNotionalStorageId: SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai,
            selectedTenorInSeconds: 60 days
        });

        inputData.tenorsInSeconds[0] = 28 days;
        inputData.tenorsInSeconds[1] = 60 days;
        inputData.tenorsInSeconds[2] = 90 days;

        if (spreadInputs.asset == _usdc) {
            inputData.timeWeightedNotionalStorageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdc;
            inputData.timeWeightedNotionalStorageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdc;
            inputData.timeWeightedNotionalStorageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdc;
            inputData.timeWeightedNotionalStorageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdc;
            return inputData;
        } else if (spreadInputs.asset == _usdt) {
            inputData.timeWeightedNotionalStorageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdt;
            inputData.timeWeightedNotionalStorageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysUsdt;
            inputData.timeWeightedNotionalStorageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysUsdt;
            inputData.timeWeightedNotionalStorageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysUsdt;
            return inputData;
        } else if (spreadInputs.asset == _dai) {
            inputData.timeWeightedNotionalStorageId = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
            inputData.timeWeightedNotionalStorageIds[0] = SpreadStorageLibs.StorageId.TimeWeightedNotional28DaysDai;
            inputData.timeWeightedNotionalStorageIds[1] = SpreadStorageLibs.StorageId.TimeWeightedNotional60DaysDai;
            inputData.timeWeightedNotionalStorageIds[2] = SpreadStorageLibs.StorageId.TimeWeightedNotional90DaysDai;
            return inputData;
        }
        revert(string.concat(IporOracleErrors.ASSET_NOT_SUPPORTED, " ", Strings.toHexString(spreadInputs.asset)));
    }
}