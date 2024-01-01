// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts@5.0.0/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts@5.0.0/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// File: @openzeppelin/contracts@5.0.0/utils/Strings.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;



/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
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
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: contracts/LiquidityLockV2.sol


pragma solidity ^0.8.21;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    }
interface IUniswapV3PoolState {
    function feeGrowthGlobal0X128() external view returns (uint256);
    function feeGrowthGlobal1X128() external view returns (uint256);
    function liquidity() external view returns (uint128);
    }
interface INonfungiblePositionManager {
    struct PositionData {
        uint96 nonce;
        address operator;
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }
    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }
    function positions(uint256 tokenId) external view returns (PositionData memory);
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);
    function transferFrom(address from, address to, uint256 tokenId) external;
    }




//********************************************************************************************
//***********************      HERE STARTS THE CODE OF CONTRACT     **************************
//********************************************************************************************

contract UniswapNFTpositionLocker {

// simplified version of ownable (to save gas)
    address private _owner;
    constructor() {_owner = msg.sender;}
    modifier onlyOwner() {require(_owner == msg.sender, "Ownable: caller is not the owner"); _;}

// variables
    INonfungiblePositionManager private UniswapManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    IERC20 public EQT;
    address public PoolWallet = 0x79C08ce94676106f3a11c561D893F9fb26dd007C;
    address private TeamWallet;
    address[] public Partners;
    uint256 public RequiredUnlockTime_90days = 7776000;      // time since the requested unlock of tokens required to pass before the tokens can be withdrawn (90 days in seconds)
    uint256 public RequiredUnlockTime_30days = 2592000;      // time since the requested unlock of tokens required to pass before the tokens can be withdrawn (30 days in seconds)
    uint256 public RequiredUnlockTime_1day = 86400;          // time since the requested unlock of tokens required to pass before the tokens can be withdrawn (1 day in seconds)
    mapping(uint8 => IUniswapV3PoolState) public Pool;
    mapping(uint8 => uint256) public Pool_NFT_ID;
    mapping(uint8 => uint256) internal Pool_Timestamp;
    mapping(uint8 => uint8) public Pool_LockDays;
    mapping(uint8 => uint256) internal Pool_feeGrowth0;
    mapping(uint8 => uint256) internal Pool_feeGrowth1;
    mapping(uint8 => string) public Pool_priceRange;
    bool public EQTaddressLocked = false;
    error Withdrawing_EQT();
    error Not_Enough_To_Withdraw();
    error Locked();
    error AlreadyExist();
    error IncorrectLockTime();

// internal functions
    function uint256toString(uint256 value, uint8 decimals) internal pure returns (string memory) {
        if (value == 0) {return "0";}
        if (decimals == 0) {return Strings.toString(value);}
        string memory IntPart = Strings.toString(value / (10**decimals));
        string memory DecPart = Strings.toString(value % (10**decimals));
        bytes memory DecPartBytes = bytes(DecPart);
        if (DecPartBytes.length == decimals) {return string(abi.encodePacked(IntPart, ".", DecPart));}
        if (DecPartBytes.length > decimals) {return "ERROR";}
        string memory Zeros = "0";
        uint256 counter = (DecPartBytes.length + 1);
        while (counter < decimals) {Zeros = string(abi.encodePacked(Zeros, "0")); counter++;}
        return string(abi.encodePacked(IntPart, ".", Zeros, DecPart));
    }

// onlyOwner functions
    function setPool(uint8 Pool_Number, IUniswapV3PoolState Pool_Address, uint256 NFT_ID, uint8 LockDays, string calldata priceRange) external onlyOwner {
        if (LockDays != 1 && LockDays != 30 && LockDays != 90) {revert IncorrectLockTime();}
        if ((Pool_Timestamp[Pool_Number] == 0) && (Pool_LockDays[Pool_Number] != 0)) {revert Locked();}
        if((Pool_LockDays[Pool_Number] == 1) && ((block.timestamp - Pool_Timestamp[Pool_Number]) <= RequiredUnlockTime_1day)) {revert Locked();}
        if((Pool_LockDays[Pool_Number] == 30) && ((block.timestamp - Pool_Timestamp[Pool_Number]) <= RequiredUnlockTime_30days)) {revert Locked();}
        if((Pool_LockDays[Pool_Number] == 90) && ((block.timestamp - Pool_Timestamp[Pool_Number]) <= RequiredUnlockTime_90days)) {revert Locked();}
        for (uint8 i = 0; i <= 254; i++) {if (Pool_NFT_ID[i] == NFT_ID) {revert AlreadyExist();}}
        if (Pool_NFT_ID[255] == NFT_ID) {revert AlreadyExist();}
        Pool[Pool_Number] = Pool_Address;
        Pool_NFT_ID[Pool_Number] = NFT_ID;
        Pool_LockDays[Pool_Number] = LockDays;
        Pool_priceRange[Pool_Number] = priceRange;
        Pool_Timestamp[Pool_Number] = 0;
        Pool_feeGrowth0[Pool_Number] = Pool_Address.feeGrowthGlobal0X128();
        Pool_feeGrowth1[Pool_Number] = Pool_Address.feeGrowthGlobal1X128();
    }
    function setTeamWallet(address _addr) external onlyOwner {TeamWallet = _addr;}
    function addPartnerWallet(address _addr) external onlyOwner {
        for (uint256 i = 0; i < Partners.length; i++) {
            if (Partners[i] == _addr) {revert AlreadyExist();}
        }
        Partners.push(_addr);
        }
    function removePartnerWallet(address _addr) external onlyOwner {
        for (uint256 i = 0; i < Partners.length; i++) {
            if (Partners[i] == _addr) {
                Partners[i] = Partners[Partners.length - 1];
                Partners.pop();
            }
        }
    }
    function setEQT(IERC20 _addr) external onlyOwner {if (EQTaddressLocked) {revert Locked();} else {EQT = _addr;}}
    function lockEQTaddress(bool confirm) external onlyOwner {if (confirm) {EQTaddressLocked = true;}}
    function lockPool(uint8 Pool_Number, uint8 LockDays) external onlyOwner {
        if (LockDays != 1 && LockDays != 30 && LockDays != 90) {revert IncorrectLockTime();}
        if (Pool_LockDays[Pool_Number] > LockDays) {
            if (Pool_Timestamp[Pool_Number] == 0) {revert Locked();}
            if((Pool_LockDays[Pool_Number] == 1) && ((block.timestamp - Pool_Timestamp[Pool_Number]) <= RequiredUnlockTime_1day)) {revert Locked();}
            if((Pool_LockDays[Pool_Number] == 30) && ((block.timestamp - Pool_Timestamp[Pool_Number]) <= RequiredUnlockTime_30days)) {revert Locked();}
            if((Pool_LockDays[Pool_Number] == 90) && ((block.timestamp - Pool_Timestamp[Pool_Number]) <= RequiredUnlockTime_90days)) {revert Locked();}
            }
        Pool_Timestamp[Pool_Number] = 0; Pool_LockDays[Pool_Number] = LockDays;
    }
    function unlockPool(uint8 Pool_Number) external onlyOwner {Pool_Timestamp[Pool_Number] = block.timestamp;}
    function withdrawUnlockedPool (uint8 Pool_Number) external onlyOwner {
        if ((Pool_LockDays[Pool_Number] == 1) && (Pool_Timestamp[Pool_Number] != 0) && ((block.timestamp - Pool_Timestamp[Pool_Number]) >= RequiredUnlockTime_1day)) {UniswapManager.transferFrom(address(this), PoolWallet, Pool_NFT_ID[Pool_Number]);}
        if ((Pool_LockDays[Pool_Number] == 30) && (Pool_Timestamp[Pool_Number] != 0) && ((block.timestamp - Pool_Timestamp[Pool_Number]) >= RequiredUnlockTime_30days)) {UniswapManager.transferFrom(address(this), PoolWallet, Pool_NFT_ID[Pool_Number]);}
        if ((Pool_LockDays[Pool_Number] == 90) && (Pool_Timestamp[Pool_Number] != 0) && ((block.timestamp - Pool_Timestamp[Pool_Number]) >= RequiredUnlockTime_90days)) {UniswapManager.transferFrom(address(this), PoolWallet, Pool_NFT_ID[Pool_Number]);}
    }

// view functions
    function checkRemainingLockTime(uint8 Pool_Number) external view returns (uint256 RemainingSeconds, string memory Status) {
        if (Pool_Timestamp[Pool_Number] == 0) {return (99999999999, "Locked");}
        else {
            if (Pool_LockDays[Pool_Number] == 1){
                if ((block.timestamp - Pool_Timestamp[Pool_Number]) >= RequiredUnlockTime_1day) {return (0, "Unlocked");}
                else {return ((RequiredUnlockTime_1day - (block.timestamp - Pool_Timestamp[Pool_Number])), "Unlocking");}
            }
            if (Pool_LockDays[Pool_Number] == 30){
                if ((block.timestamp - Pool_Timestamp[Pool_Number]) >= RequiredUnlockTime_30days) {return (0, "Unlocked");}
                else {return ((RequiredUnlockTime_30days - (block.timestamp - Pool_Timestamp[Pool_Number])), "Unlocking");}
            }
            if (Pool_LockDays[Pool_Number] == 90){
                if ((block.timestamp - Pool_Timestamp[Pool_Number]) >= RequiredUnlockTime_90days) {return (0, "Unlocked");}
                else {return ((RequiredUnlockTime_90days - (block.timestamp - Pool_Timestamp[Pool_Number])), "Unlocking");}
            }
        }
    }
    function getPartnerNumber(address _addr) external view returns (uint256) {
        for (uint256 i = 0; i < Partners.length; i++) {
            if (Partners[i] == _addr) {return i;}
        }
        return 0;
    }
    function checkPoolData(uint8 Pool_Number) external view returns (string memory Token0_Symbol, address Token0_Address, string memory Token1_Symbol, address Token1_Address, string memory EQT_Price_Range) {
        INonfungiblePositionManager.PositionData memory positionData = UniswapManager.positions(Pool_NFT_ID[Pool_Number]);
        return (IERC20(positionData.token0).symbol(), positionData.token0, IERC20(positionData.token1).symbol(), positionData.token1, Pool_priceRange[Pool_Number]);
    }
    function checkAccumulatedFees(uint8 Pool_Number) public view returns (string memory AccumulatedFees){
        INonfungiblePositionManager.PositionData memory positionData = UniswapManager.positions(Pool_NFT_ID[Pool_Number]);
        uint256 feeGrowth_0 = (Pool[Pool_Number].feeGrowthGlobal0X128() - Pool_feeGrowth0[Pool_Number]);
        uint256 feeGrowth_1 = (Pool[Pool_Number].feeGrowthGlobal1X128() - Pool_feeGrowth1[Pool_Number]);
        uint256 estimatedFees0;
        uint256 estimatedFees1;
        if (feeGrowth_0 < 340282366920938463463374607431768211456) {estimatedFees0 = (feeGrowth_0 * positionData.liquidity) / 340282366920938463463374607431768211456;}
        else {estimatedFees0 = ((feeGrowth_0 / 3402823669209384634633746074317682114) * (positionData.liquidity / 100));}
        if (feeGrowth_1 < 340282366920938463463374607431768211456) {estimatedFees1 = (feeGrowth_1 * positionData.liquidity) / 340282366920938463463374607431768211456;}
        else {estimatedFees1 = ((feeGrowth_1 / 3402823669209384634633746074317682114) * (positionData.liquidity / 100));}
        string memory output = string(abi.encodePacked("\nPool: ", Strings.toString(Pool_Number), " ... ", uint256toString(estimatedFees0, IERC20(positionData.token0).decimals()), " ", IERC20(positionData.token0).symbol(), " + ", uint256toString(estimatedFees1, IERC20(positionData.token1).decimals()), " ", IERC20(positionData.token1).symbol()));
        return (output);
    }
    function checkAccumulatedFees_batch(uint8 batchStart, uint8 batchEnd) external view returns (string memory AccumulatedFees_Batch) {
        require (batchStart < batchEnd, "Incorrect range");
        string memory AccumulatedFeesBatch;
        for (uint8 i = batchStart; i < batchEnd; i++) {
            if (Pool[i] != IUniswapV3PoolState(address(0))) {
                AccumulatedFeesBatch = string(abi.encodePacked(AccumulatedFeesBatch, checkAccumulatedFees(i)));
            }
        }
        if (Pool[batchEnd] != IUniswapV3PoolState(address(0))) {
            AccumulatedFeesBatch = string(abi.encodePacked(AccumulatedFeesBatch, checkAccumulatedFees(batchEnd)));
        }
        return AccumulatedFeesBatch;
    }

// fee collection
    function collectFees(uint8 Pool_Number) external {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: Pool_NFT_ID[Pool_Number],
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });
        UniswapManager.collect(params);
        Pool_feeGrowth0[Pool_Number] = Pool[Pool_Number].feeGrowthGlobal0X128();
        Pool_feeGrowth1[Pool_Number] = Pool[Pool_Number].feeGrowthGlobal1X128();
    }
    function withdrawFees (IERC20 token) external {
        if (token == EQT) {revert Withdrawing_EQT();}
        uint256 balance = token.balanceOf(address(this));
        if ((2*Partners.length >= balance) || (1 >= balance)) {revert Not_Enough_To_Withdraw();}
        uint256 amount;
        if (Partners.length == 0) {
            amount = balance/2;
            token.transfer(TeamWallet, amount);
            token.transfer(_owner, balance - amount);
        } else {
            if (Partners.length == 1) {
                amount = balance/3;
                token.transfer(TeamWallet, amount);
                token.transfer(Partners[0], amount);
                token.transfer(_owner, (balance - (2*amount)));
            } else {
                amount = balance/4;
                uint256 PartnerAmount = (balance/(2*Partners.length));
                token.transfer(TeamWallet, amount);
                token.transfer(_owner, amount);
                for (uint256 i = 0; i < Partners.length; i++) {
                    token.transfer(Partners[i], PartnerAmount);
                }
            }
        }
        if (EQT.balanceOf(address(this)) >= 10**21) {EQT.burn(EQT.balanceOf(address(this)));}
    }
}