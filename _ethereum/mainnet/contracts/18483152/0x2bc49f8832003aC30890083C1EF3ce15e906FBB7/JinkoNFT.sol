// File: @openzeppelin/contracts/utils/math/SignedMath.sol

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

// File: @openzeppelin/contracts/utils/math/Math.sol

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

// File: @openzeppelin/contracts/utils/Strings.sol

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

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: extensions/ERC721Metadata.sol

pragma solidity ^0.8.0;

/**
 * @title ERC721B Burnable Token
 * @dev ERC721B Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Metadata is IERC721Metadata {
  string private _name;
  string private _symbol;

  /**
   * @dev Sets the name, symbol
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual returns(string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual returns(string memory) {
    return _symbol;
  }
}

// File: ERC721B.sol

pragma solidity ^0.8.0;

error InvalidCall();
error BalanceQueryZeroAddress();
error NonExistentToken();
error ApprovalToCurrentOwner();
error ApprovalOwnerIsOperator();
error NotERC721Receiver();
error ERC721ReceiverNotReceived();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] 
 * Non-Fungible Token Standard, including the Metadata extension and 
 * token Auto-ID generation.
 *
 * You must provide `name()` `symbol()` and `tokenURI(uint256 tokenId)`
 * to conform with IERC721Metadata
 */
abstract contract ERC721B is Context, ERC165, IERC721 {

  // ============ Storage ============

  // Total NFT quantity mintable
  uint256 private _maxSupply;
  // The last token id minted
  uint256 private _lastTokenId;
  // Mapping from token ID to owner address
  mapping(uint256 => address) internal _owners;
  // Mapping owner address to token count
  mapping(address => uint256) internal _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;
  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // ============ Read Methods ============

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) 
    public view virtual override returns(uint256) 
  {
    if (owner == address(0)) revert BalanceQueryZeroAddress();
    return _balances[owner];
  }

  function totalSupply() public view virtual returns(uint256) {
    return _maxSupply;
  }

  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalCirculatingSupply() public view virtual returns(uint256) {
    return _lastTokenId;
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) 
    public view virtual override returns(address) 
  {
    unchecked {
      //this is the situation when _owners normalized
      uint256 id = tokenId;
      if (_owners[id] != address(0)) {
        return _owners[id];
      }
      //this is the situation when _owners is not normalized
      if (id > 0 && id <= _lastTokenId) {
        //there will never be a case where token 1 is address(0)
        while(true) {
          id--;
          if (id == 0) {
            break;
          } else if (_owners[id] != address(0)) {
            return _owners[id];
          }
        }
      }
    }

    revert NonExistentToken();
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC165, IERC165) returns(bool) 
  {
    return interfaceId == type(IERC721).interfaceId
      || super.supportsInterface(interfaceId);
  }

  // ============ Approval Methods ============

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721B.ownerOf(tokenId);
    if (to == owner) revert ApprovalToCurrentOwner();

    address sender = _msgSender();
    if (sender != owner && !isApprovedForAll(owner, sender)) 
      revert ApprovalToCurrentOwner();

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) 
    public view virtual override returns(address) 
  {
    if (!_exists(tokenId)) revert NonExistentToken();
    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator) 
    public view virtual override returns (bool) 
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) 
    public virtual override 
  {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
  function _approve(address to, uint256 tokenId, address owner) 
    internal virtual 
  {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  /**
   * @dev transfers token considering approvals
   */
  function _approveTransfer(
    address spender, 
    address from, 
    address to, 
    uint256 tokenId
  ) internal virtual {
    if (!_isApprovedOrOwner(spender, tokenId, from)) 
      revert InvalidCall();

    _transfer(from, to, tokenId);
  }

  /**
   * @dev Safely transfers token considering approvals
   */
  function _approveSafeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _approveTransfer(_msgSender(), from, to, tokenId);
    //see: @openzep/utils/Address.sol
    if (to.code.length > 0
      && !_checkOnERC721Received(from, to, tokenId, _data)
    ) revert ERC721ReceiverNotReceived();
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(
    address spender, 
    uint256 tokenId, 
    address owner
  ) internal view virtual returns(bool) {
    return spender == owner 
      || getApproved(tokenId) == spender 
      || isApprovedForAll(owner, spender);
  }

  /**
   * @dev Approve `operator` to operate on all of `owner` tokens
   *
   * Emits a {ApprovalForAll} event.
   */
  function _setApprovalForAll(
    address owner,
    address operator,
    bool approved
  ) internal virtual {
    if (owner == operator) revert ApprovalOwnerIsOperator();
    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  function _setMaxSupply(uint256 supply) internal {
    _maxSupply = supply;
  }

  // ============ Mint Methods ============

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} 
   * whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(
    address to,
    uint256 amount,
    bytes memory _data,
    bool safeCheck
  ) private {
    if(amount == 0 || to == address(0)) revert InvalidCall();
    require(_lastTokenId + amount <= _maxSupply, "max supply exceed");
    uint256 startTokenId = _lastTokenId + 1;
    
    _beforeTokenTransfers(address(0), to, startTokenId, amount);
    
    unchecked {
      _lastTokenId += amount;
      _balances[to] += amount;
      _owners[startTokenId] = to;

      _afterTokenTransfers(address(0), to, startTokenId, amount);

      uint256 updatedIndex = startTokenId;
      uint256 endIndex = updatedIndex + amount;
      //if do safe check and,
      //check if contract one time (instead of loop)
      //see: @openzep/utils/Address.sol
      if (safeCheck && to.code.length > 0) {
        //loop emit transfer and received check
        do {
          emit Transfer(address(0), to, updatedIndex);
          if (!_checkOnERC721Received(address(0), to, updatedIndex++, _data))
            revert ERC721ReceiverNotReceived();
        } while (updatedIndex != endIndex);
        return;
      }

      do {
        emit Transfer(address(0), to, updatedIndex++);
      } while (updatedIndex != endIndex);
    }
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC721Receiver-onERC721Received}, which is called upon a 
   *   safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 amount) internal virtual {
    _safeMint(to, amount, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], 
   * with an additional `data` parameter which is forwarded in 
   * {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 amount,
    bytes memory _data
  ) internal virtual {
    _mint(to, amount, _data, true);
  }

  // ============ Transfer Methods ============

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    _approveTransfer(_msgSender(), from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    _approveSafeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} 
   * on a target address. The call is not executed if the target address 
   * is not a contract.
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    try IERC721Receiver(to).onERC721Received(
      _msgSender(), from, tokenId, _data
    ) returns (bytes4 retval) {
      return retval == IERC721Receiver.onERC721Received.selector;
    } catch (bytes memory reason) {
      if (reason.length == 0) {
        revert NotERC721Receiver();
      } else {
        assembly {
          revert(add(32, reason), mload(reason))
        }
      }
    }
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via 
   * {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return tokenId > 0 && tokenId <= _lastTokenId;
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking 
   * first that contract recipients are aware of the ERC721 protocol to 
   * prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is 
   * sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can 
   * be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as 
   * signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement 
   *   {IERC721Receiver-onERC721Received}, which is called upon a 
   *   safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    //see: @openzep/utils/Address.sol
    if (to.code.length > 0
      && !_checkOnERC721Received(from, to, tokenId, _data)
    ) revert ERC721ReceiverNotReceived();
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`. As opposed to 
   * {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(address from, address to, uint256 tokenId) private {
    //if transfer to null or not the owner
    if (to == address(0) || from != ERC721B.ownerOf(tokenId)) 
      revert InvalidCall();

    _beforeTokenTransfers(from, to, tokenId, 1);
    
    // Clear approvals from the previous owner
    _approve(address(0), tokenId, from);

    unchecked {
      //this is the situation when _owners are normalized
      _balances[to] += 1;
      _balances[from] -= 1;
      _owners[tokenId] = to;
      //this is the situation when _owners are not normalized
      uint256 nextTokenId = tokenId + 1;
      if (nextTokenId <= _lastTokenId && _owners[nextTokenId] == address(0)) {
        _owners[nextTokenId] = from;
      }
    }

    _afterTokenTransfers(from, to, tokenId, 1);
    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids 
   * are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * amount - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` 
   *   will be transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 amount
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids 
   * have been transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * amount - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 amount
  ) internal virtual {}
}

// File: extensions/ERC721BBaseTokenURI.sol

pragma solidity ^0.8.0;

/**
 * @dev ERC721B token where token URIs are determined with a base URI
 */
abstract contract ERC721BBaseTokenURI is ERC721B, IERC721Metadata {
  using Strings for uint256;
  string private _baseTokenURI;

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual returns(string memory) {
    if(!_exists(tokenId)) revert NonExistentToken();
    string memory baseURI = _baseTokenURI;
    return bytes(baseURI).length > 0 ? string(
      abi.encodePacked(baseURI, tokenId.toString(), ".json")
    ) : "";
  }
  
  /**
   * @dev The base URI for token data ex. https://creatures-api.opensea.io/api/creature/
   * Example Usage: 
   *  Strings.strConcat(baseTokenURI(), Strings.uint2str(tokenId))
   */
  function baseTokenURI() public view returns (string memory) {
    return _baseTokenURI;
  }

  /**
   * @dev Setting base token uri would be acceptable if using IPFS CIDs
   */
  function _setBaseURI(string memory uri) internal virtual {
    _baseTokenURI = uri;
  }
}

// File: presets/ERC721BPresetStandard.sol

pragma solidity ^0.8.0;

contract ERC721BPresetStandard is 
  Ownable(msg.sender), 
  ERC721Metadata, 
  ERC721BBaseTokenURI
{ 
  mapping(address => bool) public access_permission;

  modifier hasAccessPermission() {
    require(access_permission[msg.sender], "no access permission");
    _;
  }

  event SetHasAccessPermission(address _address, bool status);

  /**
   * @dev Sets the name, symbol
   */
  constructor(string memory name, string memory symbol) 
    ERC721Metadata(name, symbol) {
    access_permission[msg.sender] = true;
  }

  /**
   * @dev Allows owner to mint
   */
  function mint(address to, uint256 quantity) external hasAccessPermission {
    _safeMint(to, quantity);
  }

  function setAccessPermission(address _address, bool status) external onlyOwner {
    access_permission[_address] = status;
    emit SetHasAccessPermission(_address, status);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC721B, IERC165) returns(bool) 
  {
    return interfaceId == type(IERC721Metadata).interfaceId
      || super.supportsInterface(interfaceId);
  }
}
// File: extensions/ERC721BContractURIStorage.sol

pragma solidity ^0.8.0;

/**
 * @dev ERC721B contract with a URI descriptor
 */
abstract contract ERC721BContractURIStorage is ERC721B {
  //immutable contract uri
  string private _contractURI;

  /**
   * @dev The URI for contract data ex. https://creatures-api.opensea.io/contract/opensea-creatures/contract.json
   * Example Format:
   * {
   *   "name": "OpenSea Creatures",
   *   "description": "OpenSea Creatures are adorable aquatic beings primarily for demonstrating what can be done using the OpenSea platform. Adopt one today to try out all the OpenSea buying, selling, and bidding feature set.",
   *   "image": "https://openseacreatures.io/image.png",
   *   "external_link": "https://openseacreatures.io",
   *   "seller_fee_basis_points": 100, # Indicates a 1% seller fee.
   *   "fee_recipient": "0xA97F337c39cccE66adfeCB2BF99C1DdC54C2D721" # Where seller fees will be paid to.
   * }
   */
  function contractURI() external view returns (string memory) {
    return _contractURI;
  }

  /**
   * @dev Sets contract uri
   */
  function _setContractURI(string memory uri) internal virtual {
    _contractURI = uri;
  }
}

// File: extensions/ERC721BStaticTokenURI.sol

pragma solidity ^0.8.0;

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721BStaticTokenURI is ERC721B, IERC721Metadata {
  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) public view virtual returns(string memory) {
    return staticTokenURI(tokenId);
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function staticTokenURI(uint256 tokenId) public view virtual returns(string memory) {
    if(!_exists(tokenId)) revert NonExistentToken();
    return _tokenURIs[tokenId];
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
    if(!_exists(tokenId)) revert NonExistentToken();
    _tokenURIs[tokenId] = _tokenURI;
  }
}

// File: extensions/ERC721BPausable.sol

pragma solidity ^0.8.0;

/**
 * @dev ERC721B token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721BPausable is Pausable, ERC721B {
  /**
   * @dev Hook that is called before a set of serially-ordered token ids 
   * are about to be transferred. This includes minting.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 amount
  ) internal virtual override {
    if (paused()) revert InvalidCall();
    super._beforeTokenTransfers(from, to, startTokenId, amount);
  }
}

// File: extensions/ERC721BBurnable.sol

pragma solidity ^0.8.0;

/**
 * @title ERC721B Burnable Token
 * @dev ERC721B Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721BBurnable is Context, ERC721B {

  // ============ Storage ============

  //mapping of token id to burned?
  mapping(uint256 => bool) private _burned;
  //count of how many burned
  uint256 private _totalBurned;

  // ============ Read Methods ============

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) 
    public view virtual override returns(address) 
  {
    if (_burned[tokenId]) revert NonExistentToken();
    return super.ownerOf(tokenId);
  }

  /**
   * @dev Shows the overall amount of tokens generated in the contract
   */
  function totalCirculatingSupply() public virtual view override returns(uint256) {
    return super.totalCirculatingSupply() - _totalBurned;
  }

  // ============ Write Methods ============

  /**
   * @dev Burns `tokenId`. See {ERC721B-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    address owner = ERC721B.ownerOf(tokenId);
    if (!_isApprovedOrOwner(_msgSender(), tokenId, owner)) 
      revert InvalidCall();

    _beforeTokenTransfers(owner, address(0), tokenId, 1);
    
    // Clear approvals
    _approve(address(0), tokenId, owner);

    unchecked {
      //this is the situation when _owners are normalized
      _balances[owner] -= 1;
      _burned[tokenId] = true;
      _owners[tokenId] = address(0);
      _totalBurned++;

      //this is the situation when _owners are not normalized
      uint256 nextTokenId = tokenId + 1;
      uint256 _totalSupply = super.totalCirculatingSupply() - _totalBurned;
      if (nextTokenId <= _totalSupply && _owners[nextTokenId] == address(0)) {
        _owners[nextTokenId] = owner;
      }
    }

    _afterTokenTransfers(owner, address(0), tokenId, 1);

    emit Transfer(owner, address(0), tokenId);
  }

  // ============ Internal Methods ============

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via 
   * {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) 
    internal view virtual override returns(bool) 
  {
    return !_burned[tokenId] && super._exists(tokenId);
  }
}

// File: presets/ERC721BPresetAll.sol

pragma solidity ^0.8.0;

contract JinkoNFT is 
  Ownable, 
  ERC721BPresetStandard,
  ERC721BBurnable,
  ERC721BPausable,
  ERC721BStaticTokenURI,
  ERC721BContractURIStorage
{ 
  using Strings for uint256;

  string private _uriExt;

  /**
   * @dev Sets the name, symbol, contract URI
   */
  constructor(
    string memory name, 
    string memory symbol, 
    string memory uri
  ) ERC721BPresetStandard(name, symbol) {
    _setBaseURI(uri);
    _setMaxSupply(3000);
  }

  function totalSupply() public override view returns (uint) {
    return super.totalSupply();
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() public virtual onlyOwner {
    _pause();
  }

  /**
   * @dev Allows curators to set the base token uri
   */
  function setBaseTokenURI(string memory uri) 
    external virtual onlyOwner
  {
    _setBaseURI(uri);
  }

  /**
   * @dev Allows curators to set a token uri
   */
  function setTokenURI(uint256 tokenId, string memory uri) 
    external virtual onlyOwner
  {
    _setTokenURI(tokenId, uri);
  }

  /**
   * @dev Allows curators to set a contract uri
   */
  function setContractURI(string memory uri) external onlyOwner {
    _setContractURI(uri);
  }

  /**
    * @dev Update base uri extension
    */
  function setUriExt(string memory value) external onlyOwner {
      _uriExt = value;
  }

  /**
     * @dev URI Extension
     */
    function uriExt() public view virtual returns (string memory) {
        return _uriExt;
    }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId) 
    public 
    view 
    virtual 
    override(ERC721BStaticTokenURI, ERC721BBaseTokenURI, IERC721Metadata)
    returns(string memory) 
  {
    if(!_exists(tokenId)) revert InvalidCall();

    string memory _tokenURI = staticTokenURI(tokenId);
    string memory base = baseTokenURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }

    if (keccak256(abi.encodePacked(_uriExt)) == keccak256(abi.encodePacked("."))) {
      return string(abi.encodePacked(base, tokenId.toString())); 
    }
  
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }

    return bytes(base).length > 0 ? string(
      abi.encodePacked(base, tokenId.toString(), _uriExt)
    ) : "";
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC721Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() public virtual onlyOwner {
    _unpause();
  }

  // ============ Overrides ============

  /**
   * @dev Describes linear override for `ownerOf` used in 
   * both `ERC721B`, `ERC721BBurnable` and `IERC721`
   */
  function ownerOf(uint256 tokenId) 
    public 
    view 
    virtual 
    override(ERC721B, ERC721BBurnable, IERC721)
    returns(address) 
  {
    return super.ownerOf(tokenId);
  }

  /**
   * @dev Describes linear override for `supportsInterface` used in 
   * both `ERC721B` and `ERC721BPresetStandard`
   */
  function supportsInterface(bytes4 interfaceId) 
    public view virtual override(ERC721B, ERC721BPresetStandard, IERC165) returns(bool) 
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * @dev Describes linear override for `totalSupply` used in 
   * both `ERC721B` and `ERC721BBurnable`
   */
  function totalCirculatingSupply() 
    public 
    virtual 
    view 
    override(ERC721B, ERC721BBurnable) 
    returns(uint256) 
  {
    return super.totalCirculatingSupply();
  }

  /**
   * @dev Describes linear override for `_beforeTokenTransfers` used in 
   * both `ERC721B` and `ERC721BPausable`
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 amount
  ) internal virtual override(ERC721B, ERC721BPausable) {
    super._beforeTokenTransfers(from, to, startTokenId, amount);
  }

  /**
   * @dev Describes linear override for `_exists` used in 
   * both `ERC721B` and `ERC721BBurnable`
   */
  function _exists(uint256 tokenId) 
    internal 
    view 
    virtual 
    override(ERC721B, ERC721BBurnable) 
    returns(bool) 
  {
    return super._exists(tokenId);
  }
}