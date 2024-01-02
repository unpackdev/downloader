// File: @openzeppelin/contracts@4.5.0/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts@4.5.0/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: contracts/Base64.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}
// File: @openzeppelin/contracts@4.9.0/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts@4.9.0/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts@4.9.0/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;



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

// File: contracts/Ivivi.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface Ivivi  {
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

    function tokenIdBalance(uint tokenId) external view returns(uint);

    function approveTokenIdToken(uint tokenId,address spender) external ;

    function revokeApproveTokenIdToken(uint tokenId,address spender) external ;

    function transferFromBalanceAmount(uint fromTokenId,uint toTokenId,uint amount) external ;

    function transferBalanceAmount(uint fromTokenId,uint toTokenId,uint amount) external ;

    function inscribe(uint _amount) external ;
    
    function name() external view returns (string memory);


}
// File: contracts/data2.sol


pragma solidity ^0.8.0;





contract data is Ownable{

    using Strings for uint256;

    Ivivi vivi;

    mapping(uint =>string[]) public userComments;
    //uintToStringArrayMapping[key].length == 0
    mapping (uint => string[])public ownerComments;


    mapping (uint => bool) public userCommentStatic2;
    mapping (uint => address) public userComment2;
    mapping (uint => string) public ownerComment1;
    mapping (uint => string) public ownerComment2;
    mapping (uint => string) public ownerComment3;

 

    /// @custom:oz-upgrades-unsafe-allow constructor


    function setvivi(address _vivi) public onlyOwner {
        vivi = Ivivi(_vivi);
    }




    

    function generateCharacter(uint256 tokenId) public view returns(string memory){

        return string(
        abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(generateCharacterEnd(tokenId))
        )    
        );
    }

    function generateCharacter1() public view returns(bytes memory){

        bytes memory svg1 = abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 500 500">',
        '<style>.base { fill: yellow; font-family: serif; font-size: 20px; }</style>',
        '<rect width="100%" height="100%" fill="black" />',
        '<text x="50%" y="10%" font-family="Arial" font-size="25" fill = "yellow" text-anchor="middle" alignment-baseline="middle">',"''{''",'</text>'     
        '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">', " '' p '' :"" ","'' svg-20 ''"'</text>'
        '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">'," ""'' tick ''"" : ","''",vivi.name(),"''",'</text>',
        //'<text x="50%" y="60%" class="base" dominant-baseline="middle" text-anchor="middle">', " ""amt"" : ",getLevels(tokenId),'</text>',
        ''
        );
        return svg1;
    }

    function generateCharacter2() public view returns(bytes memory){

        bytes memory svg2;
        svg2 = abi.encodePacked(generateCharacter1(),
        '<text x="50%" y="90%" font-family="Arial" font-size="25" fill = "yellow" text-anchor="middle" alignment-baseline="middle">',"''}''",'</text>'  

        ''
        );
        return svg2;
    }

    function generateCharacter3(uint256 tokenId) public view returns(bytes memory){
        if(userCommentStatic2[tokenId])
        {

            bytes memory svg3;
            svg3 = abi.encodePacked(generateCharacter2(),
            //'<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">', "No: ",addressToString(userComment2[tokenId]),'</text>',
            '<text x="50%" y="85%" font-family="Arial" font-size="15" fill = "red" text-anchor="middle" alignment-baseline="middle">'," ""''signer''"" : ''",addressToString(userComment2[tokenId]),"''",'</text>'
            ''
            );
            return svg3;
        }
        else{
            return generateCharacter2();
        }
    }
    //<text x="10" y="40" style="font-family: Arial; font-size: 20px; fill: black;">Hello, SVG!</text>
    function generateCharacter4(uint256 tokenId) public view returns(bytes memory){
        bytes memory svg4;
        if(userComments[tokenId].length > 0){
            svg4 = abi.encodePacked(generateCharacter3(tokenId),
            '<text x="50%" y="65%" font-family="Arial" font-size="10" fill = "green" text-anchor="middle" alignment-baseline="middle">',"''",userComments[tokenId][0],"''"'</text>'
            ''
            );
        }else{
            svg4 = generateCharacter3(tokenId);

        }
        return svg4;
    }

    function generateCharacter5(uint256 tokenId) public view returns(bytes memory){
        if(bytes(ownerComment1[tokenId]).length !=0)
        {

            bytes memory svg5;
            svg5 = abi.encodePacked(generateCharacter4(tokenId),
            //'<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">', "No: ",addressToString(userComment2[tokenId]),'</text>',
            '<text x="50%" y="25%" font-family="Arial" font-size="15" fill = "pink" text-anchor="middle" alignment-baseline="middle">',"''",ownerComment1[tokenId],"''",'</text>'
            ''
            );
            return svg5;
        }
        else{
            return generateCharacter4(tokenId);
        }
    }
    function generateCharacter6(uint256 tokenId) public view returns(bytes memory){
        if(bytes(ownerComment2[tokenId]).length !=0)
        {

            bytes memory svg6;
            svg6 = abi.encodePacked(generateCharacter5(tokenId),
            '<text x="50%" y="30%" font-family="Arial" font-size="15" fill = "blue" text-anchor="middle" alignment-baseline="middle">',"''",ownerComment2[tokenId],"''",'</text>'
            ''
            );
            return svg6;
        }
        else{
            return generateCharacter5(tokenId);
        }
    }

    function generateCharacter7(uint256 tokenId) public view returns(bytes memory){
        if(bytes(ownerComment3[tokenId]).length !=0)
        {

            bytes memory svg7;
            svg7 = abi.encodePacked(generateCharacter6(tokenId),
            //'<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">', "No: ",addressToString(userComment2[tokenId]),'</text>',
            '<text x="50%" y="35%" font-family="Arial" font-size="15" fill = "purple" text-anchor="middle" alignment-baseline="middle">',"''",ownerComment3[tokenId],"''",'</text>'
            ''
            );
            return svg7;
        }
        else{
            return generateCharacter6(tokenId);
        }
    }

    function generateCharacter8(uint256 tokenId) public view returns(bytes memory){
        if(userComments[tokenId].length > 1)
        {

            bytes memory svg8;
            svg8 = abi.encodePacked(generateCharacter7(tokenId),
            '<text x="50%" y="70%" font-family="Arial" font-size="10" fill = "green" text-anchor="middle" alignment-baseline="middle">',"''",userComments[tokenId][1],"''",'</text>'
            ''
            );
            return svg8;
        }
        else{
            return generateCharacter7(tokenId);
        }
    }
    function generateCharacter9(uint256 tokenId) public view returns(bytes memory){
        if(userComments[tokenId].length > 2)
        {

            bytes memory svg9;
            svg9 = abi.encodePacked(generateCharacter8(tokenId),
            '<text x="50%" y="75%" font-family="Arial" font-size="10" fill = "green" text-anchor="middle" alignment-baseline="middle">',"''",userComments[tokenId][2],"''",'</text>'
            ''
            );
            return svg9;
        }
        else{
            return generateCharacter8(tokenId);
        }
    }
    //        '<text x="50%" y="90%" font-family="Arial" font-size="30" fill = "white" text-anchor="middle" alignment-baseline="middle">',":::}",'</text>'  
        function generateCharacter10(uint256 tokenId) public view returns(bytes memory){

        bytes memory svg10;
        if (getLevels_Num(tokenId) < 100){
            svg10 = abi.encodePacked(generateCharacter9(tokenId),
            '<text x="50%" y="60%" font-family="Arial" font-size="20" fill = "white" text-anchor="middle" alignment-baseline="middle">'" ""''amt''"" : ''",getLevels(tokenId),"''"'</text>'
            ''
            );
            return svg10;
        }else if(getLevels_Num(tokenId) < 1000){
            svg10 = abi.encodePacked(generateCharacter9(tokenId),
            '<text x="50%" y="60%" font-family="Arial" font-size="20" fill = "yellow" text-anchor="middle" alignment-baseline="middle">'" ""''amt''"" : ''",getLevels(tokenId),"''"'</text>'
            ''
            );
            return svg10;          
        }else if(getLevels_Num(tokenId) < 10000){
            svg10 = abi.encodePacked(generateCharacter9(tokenId),
            '<text x="50%" y="60%" font-family="Arial" font-size="20" fill = "green" text-anchor="middle" alignment-baseline="middle">'" ""''amt''"" : ''",getLevels(tokenId),"''"'</text>'
            ''
            );
            return svg10;   

        }else if(getLevels_Num(tokenId) < 100000){
            svg10 = abi.encodePacked(generateCharacter9(tokenId),
            '<text x="50%" y="60%" font-family="Arial" font-size="20" fill = "blue" text-anchor="middle" alignment-baseline="middle">'" ""''amt''"" : ''",getLevels(tokenId),"''"'</text>'
            ''
            );
            return svg10; 

        }else if(getLevels_Num(tokenId) < 1000000){
            svg10 = abi.encodePacked(generateCharacter9(tokenId),
            '<text x="50%" y="60%" font-family="Arial" font-size="20" fill = "purple" text-anchor="middle" alignment-baseline="middle">'" ""''amt''"" : ''",getLevels(tokenId),"''"'</text>'
            ''
            );
            return svg10; 

        }else{
            svg10 = abi.encodePacked(generateCharacter9(tokenId),
            '<text x="50%" y="60%" font-family="Arial" font-size="20" fill = "red" text-anchor="middle" alignment-baseline="middle">'" ""''amt''"" : ''",getLevels(tokenId),"''"'</text>'
            ''
            );
            return svg10; 

        }



        //'<text x="50%" y="20%" class="base" dominant-baseline="middle" text-anchor="middle">', "'' id '': '' ",tokenId.toString()," ''"'</text>',

            

    }

        function generateCharacter11(uint256 tokenId) public view returns(bytes memory){

        bytes memory svg11;
        if (tokenId < 100){
            svg11 = abi.encodePacked(generateCharacter10(tokenId),
            '<text x="50%" y="20%" font-family="Arial" font-size="20" fill = "red" text-anchor="middle" alignment-baseline="middle">'" ""''id''"" : ''",tokenId.toString(),"''"'</text>'
            ''
            );
            return svg11;
        }else if(tokenId < 1000){
            svg11 = abi.encodePacked(generateCharacter10(tokenId),
            '<text x="50%" y="20%" font-family="Arial" font-size="20" fill = "purple" text-anchor="middle" alignment-baseline="middle">'" ""''id''"" : ''",tokenId.toString(),"''"'</text>'
            ''
            );
            return svg11;          
        }else if(tokenId < 10000){
            svg11 = abi.encodePacked(generateCharacter10(tokenId),
            '<text x="50%" y="20%" font-family="Arial" font-size="20" fill = "blue" text-anchor="middle" alignment-baseline="middle">'" ""''id''"" : ''",tokenId.toString(),"''"'</text>'
            ''
            );
            return svg11;   

        }else if(tokenId < 21000){
            svg11 = abi.encodePacked(generateCharacter9(tokenId),
            '<text x="50%" y="20%" font-family="Arial" font-size="20" fill = "green" text-anchor="middle" alignment-baseline="middle">'" ""''id''"" : ''",tokenId.toString(),"''"'</text>'
            ''
            );
            return svg11; 

        }else{

            svg11 = abi.encodePacked(generateCharacter9(tokenId),
            '<text x="50%" y="20%" font-family="Arial" font-size="20" fill = "white" text-anchor="middle" alignment-baseline="middle">'" ""''id''"" : ''",tokenId.toString(),"''"'</text>'
            ''
            );
            return svg11; 

        }
    }




    function generateCharacterEnd(uint256 tokenId) public view returns(bytes memory){
        bytes memory svg;
        svg = abi.encodePacked(generateCharacter11(tokenId),
        '</svg>'
        );
        return svg;
    }

    function addressToString(address _address) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
    //bytes(ownerComment1[tokenId]).length !=0
    function writeComments(uint tokenid,string memory _comments) public {
        userComments[tokenid].push(_comments);
    }







    function addCommentInscr1(uint tokenId,string memory comment) public {
        require(vivi.ownerOf(tokenId) == msg.sender,"not owner");
        //ownerCommentStatic1[tokenId] =true;
        ownerComment1[tokenId] = comment;
    }

    function addCommentInscr2(uint tokenId,string memory comment) public {
        require(vivi.ownerOf(tokenId) == msg.sender,"not owner");
        //ownerCommentStatic2[tokenId] =true;
        ownerComment2[tokenId] = comment;
    }

    function addCommentInscr3(uint tokenId,string memory comment) public {
        require(vivi.ownerOf(tokenId) == msg.sender,"not owner");
        //ownerCommentStatic3[tokenId] =true;
        ownerComment3[tokenId] = comment;
    }

    function addAddrInscr(uint tokenId) public {
        require(vivi.ownerOf(tokenId) == msg.sender,"not owner");
        userCommentStatic2[tokenId] =true;
        userComment2[tokenId] = msg.sender;
    }


    function turnOffAddr(uint tokenId) public {
        require(vivi.ownerOf(tokenId) == msg.sender,"not owner");
        userCommentStatic2[tokenId] =false;
    }

    function addrToString(address addr) public pure returns (string memory) {
        return uint256(uint160(addr)).toString();
    }

    function getLevels(uint256 tokenId) public view returns (string memory) {
        uint256 levels = vivi.tokenIdBalance(tokenId);
        return levels.toString();
    }

    function getLevels_Num(uint256 tokenId) public view returns (uint) {
        uint256 levels = vivi.tokenIdBalance(tokenId);
        return levels;
    }

    function tokenData(uint256 tokenId) public  view returns (string memory){
        bytes memory dataURI = abi.encodePacked(
        '{',
            '"name": "inscription #', tokenId.toString(), '",',
            '"description": "inscription",',
            '"image": "', generateCharacter(tokenId), '"',
        '}'
        );
        return string(
        abi.encodePacked(
            "data:application/json;base64,",
            Base64.encode(dataURI)
        )
        );
    }

    function isInscribed1(uint tokenId) public view returns(bool){
        if(bytes(ownerComment1[tokenId]).length !=0){
            return true;
        }else{
            return false;
        }
    }
    function isInscribed2(uint tokenId) public view returns(bool){
        if(bytes(ownerComment1[tokenId]).length !=0){
            return true;
        }else{
            return false;
        }
    }
    function isInscribed3(uint tokenId) public view returns(bool){
        if(bytes(ownerComment1[tokenId]).length !=0){
            return true;
        }else{
            return false;
        }
    }



}