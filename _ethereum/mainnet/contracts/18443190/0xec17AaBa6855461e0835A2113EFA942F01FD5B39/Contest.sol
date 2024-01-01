// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

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

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

/**
 * @dev Interface of the {Governor} core.
 */
abstract contract IGovernor is IERC165 {
    enum ContestState {
        NotStarted,
        Active,
        Canceled,
        Queued,
        Completed
    }

    uint256 public constant METADATAS_COUNT = uint256(type(Metadatas).max) + 1;

    enum Metadatas {
        Target,
        Safe
    }

    struct TargetMetadata {
        address targetAddress;
    }

    struct SafeMetadata {
        address[] signers;
        uint256 threshold;
    }

    struct ProposalCore {
        address author;
        bool exists;
        string description;
        TargetMetadata targetMetadata;
        SafeMetadata safeMetadata;
    }

    /**
     * @dev Emitted when a jokerace is created.
     */
    event JokeraceCreated(string name, address creator);

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(uint256 proposalId, address proposer);

    /**
     * @dev Emitted when proposals are deleted.
     */
    event ProposalsDeleted(uint256[] proposalIds);

    /**
     * @dev Emitted when a contest is canceled.
     */
    event ContestCanceled();

    /**
     * @dev Emitted when a vote is cast.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 numVotes);

    /**
     * @notice module:core
     * @dev Name of the contest.
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Prompt of the contest.
     */
    function prompt() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the contest contract.
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to build the proposal id from the proposal details.
     */
    function hashProposal(ProposalCore memory proposal) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a Contest, following Compound's convention
     */
    function state() public view virtual returns (ContestState);

    /**
     * @notice module:core
     * @dev Timestamp the contest starts at. Submissions open at the end of this block, so it is not possible to propose
     * during this block.
     */
    function contestStart() public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Timestamp the contest vote begins. Votes open at the end of this block, so it is possible to propose
     * during this block.
     */
    function voteStart() public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Timestamp at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function contestDeadline() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in seconds, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, of delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in seconds, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Creator of the contest, has the power to cancel the contest and delete proposals in it.
     */
    function creator() public view virtual returns (address);

    /**
     * @dev Verifies that `account` is permissioned to propose via merkle proof.
     */
    function verifyProposer(address account, bytes32[] calldata proof) public virtual returns (bool);

    /**
     * @dev Verifies that all of the metadata in the proposal is valid.
     */
    function validateProposalData(ProposalCore memory proposal) public virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(ProposalCore calldata proposal, bytes32[] calldata proof)
        public
        virtual
        returns (uint256 proposalId);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function proposeWithoutProof(ProposalCore calldata proposal) public virtual returns (uint256 proposalId);

    /**
     * @dev Verifies that `account` is permissioned to vote with `totalVotes` via merkle proof.
     */
    function verifyVoter(address account, uint256 totalVotes, bytes32[] calldata proof) public virtual returns (bool);

    /**
     * @dev Cast a vote with a merkle proof.
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support, uint256 totalVotes, uint256 numVotes, bytes32[] calldata proof)
        public
        virtual
        returns (uint256 balance);

    /**
     * @dev Cast a vote without including the merkle proof.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithoutProof(uint256 proposalId, uint8 support, uint256 numVotes)
        public
        virtual
        returns (uint256 balance);
}

/// ============ Imports ============

// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}
 // OZ: MerkleProof

/// @title GovernorMerkleVotes
abstract contract GovernorMerkleVotes {
    /// ============ Immutable storage ============

    /// @notice ERC20-claimee inclusion root
    bytes32 public immutable submissionMerkleRoot;
    bytes32 public immutable votingMerkleRoot;

    /// ============ Errors ============

    /// @notice Thrown if address/amount are not part of Merkle tree
    error NotInMerkle();

    /// ============ Constructor ============

    /// @notice Creates a new GovernorMerkleVotes contract
    /// @param _submissionMerkleRoot of claimees
    /// @param _votingMerkleRoot of claimees
    constructor(bytes32 _submissionMerkleRoot, bytes32 _votingMerkleRoot) {
        submissionMerkleRoot = _submissionMerkleRoot; // Update root
        votingMerkleRoot = _votingMerkleRoot; // Update root
    }

    /// ============ Functions ============

    /// @notice Allows checking of proofs for an address
    /// @param addressToCheck address of claimee
    /// @param amount to check that the claimee has
    /// @param proof merkle proof to prove address and amount are in tree
    /// @param voting true if this is for a voting proof, false if this is for a submission proof
    function checkProof(address addressToCheck, uint256 amount, bytes32[] calldata proof, bool voting)
        public
        view
        returns (bool verified)
    {
        // Verify merkle proof, or revert if not in tree
        bytes32 leaf = keccak256(abi.encodePacked(addressToCheck, amount));
        bool isValidLeaf = voting
            ? MerkleProof.verify(proof, votingMerkleRoot, leaf)
            : MerkleProof.verify(proof, submissionMerkleRoot, leaf);
        if (!isValidLeaf) revert NotInMerkle();
        return true;
    }
}

/**
 * @dev Core of the governance system, designed to be extended though various modules.
 */
abstract contract Governor is Context, ERC165, EIP712, GovernorMerkleVotes, IGovernor {
    using SafeCast for uint256;

    uint256 public constant AMOUNT_FOR_SUMBITTER_PROOF = 10000000000000000000;
    address public constant JK_LABS_ADDRESS = 0xDc652C746A8F85e18Ce632d97c6118e8a52fa738;

    string private _name;
    string private _prompt;

    uint256[] public proposalIds;
    uint256[] public deletedProposalIds;
    mapping(uint256 => bool) public proposalIsDeleted;
    bool public canceled;
    mapping(uint256 => ProposalCore) public proposals;
    mapping(address => uint256) public numSubmissions;
    address[] public proposalAuthors;
    address[] public addressesThatHaveVoted;

    mapping(address => uint256) public addressTotalVotes;
    mapping(address => bool) public addressTotalVotesVerified;
    mapping(address => bool) public addressSubmitterVerified;

    /// @notice Thrown if there is metadata included in a proposal that isn't covered in data validation
    error TooManyMetadatas();

    /**
     * @dev Sets the value for {name} and {version}
     */
    constructor(string memory name_, string memory prompt_, bytes32 submissionMerkleRoot_, bytes32 votingMerkleRoot_)
        GovernorMerkleVotes(submissionMerkleRoot_, votingMerkleRoot_)
        EIP712(name_, version())
    {
        _name = name_;
        _prompt = prompt_;

        emit JokeraceCreated(name_, msg.sender); // emit upon creation to be able to easily find jokeraces on a chain
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IGovernor).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-prompt}.
     */
    function prompt() public view virtual override returns (string memory) {
        return _prompt;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "3.18";
    }

    /**
     * @dev See {IGovernor-hashProposal}.
     */
    function hashProposal(ProposalCore memory proposal) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(proposal)));
    }

    /**
     * @dev See {IGovernor-state}.
     */
    function state() public view virtual override returns (ContestState) {
        if (canceled) {
            return ContestState.Canceled;
        }

        uint256 contestStartTimestamp = contestStart();

        if (contestStartTimestamp >= block.timestamp) {
            return ContestState.NotStarted;
        }

        uint256 voteStartTimestamp = voteStart();

        if (voteStartTimestamp >= block.timestamp) {
            return ContestState.Queued;
        }

        uint256 deadlineTimestamp = contestDeadline();

        if (deadlineTimestamp >= block.timestamp) {
            return ContestState.Active;
        }

        return ContestState.Completed;
    }

    /**
     * @dev Return all proposals.
     */
    function getAllProposalIds() public view virtual returns (uint256[] memory) {
        return proposalIds;
    }

    /**
     * @dev Return all proposal authors.
     */
    function getAllProposalAuthors() public view virtual returns (address[] memory) {
        return proposalAuthors;
    }

    /**
     * @dev Return all addresses that have voted.
     */
    function getAllAddressesThatHaveVoted() public view virtual returns (address[] memory) {
        return addressesThatHaveVoted;
    }

    /**
     * @dev Return all deleted proposals.
     */
    function getAllDeletedProposalIds() public view virtual returns (uint256[] memory) {
        return deletedProposalIds;
    }

    /**
     * @dev See {IGovernor-voteStart}.
     */
    function voteStart() public view virtual override returns (uint256) {
        return contestStart() + votingDelay();
    }

    /**
     * @dev See {IGovernor-contestDeadline}.
     */
    function contestDeadline() public view virtual override returns (uint256) {
        return voteStart() + votingPeriod();
    }

    /**
     * @dev The number of proposals that an address who is qualified to propose can submit for this contest.
     */
    function numAllowedProposalSubmissions() public view virtual returns (uint256) {
        return 1;
    }

    /**
     * @dev Max number of proposals allowed in this contest
     */
    function maxProposalCount() public view virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev If downvoting is enabled in this contest.
     */
    function downvotingAllowed() public view virtual returns (uint256) {
        return 0; // 0 == false, 1 == true
    }

    /**
     * @dev Retrieve proposal data.
     */
    function getProposal(uint256 proposalId) public view virtual returns (ProposalCore memory) {
        return proposals[proposalId];
    }

    /**
     * @dev Get the number of proposal submissions for a given address.
     */
    function getNumSubmissions(address account) public view virtual returns (uint256) {
        return numSubmissions[account];
    }

    /**
     * @dev Returns if a proposal has been deleted or not.
     */
    function isProposalDeleted(uint256 proposalId) public view virtual returns (bool) {
        return proposalIsDeleted[proposalId];
    }

    /**
     * @dev Register a vote with a given support and voting weight.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(uint256 proposalId, address account, uint8 support, uint256 numVotes, uint256 totalVotes)
        internal
        virtual;

    /**
     * @dev See {IGovernor-verifyProposer}.
     */
    function verifyProposer(address account, bytes32[] calldata proof) public override returns (bool verified) {
        if (!addressSubmitterVerified[account]) {
            if (submissionMerkleRoot == 0) {
                // if the submission root is 0, then anyone can submit
                return true;
            }
            checkProof(account, AMOUNT_FOR_SUMBITTER_PROOF, proof, false); // will revert with NotInMerkle if not valid
            addressSubmitterVerified[account] = true;
        }
        return true;
    }

    /**
     * @dev See {IGovernor-validateProposalData}.
     */
    function validateProposalData(ProposalCore memory proposal) public virtual override returns (bool dataValidated) {
        require(proposal.author == msg.sender, "Governor: the proposal author must be msg.sender");
        for (uint256 index = 0; index < METADATAS_COUNT; index++) {
            Metadatas currentMetadata = Metadatas(index);
            if (currentMetadata == Metadatas.Target) {
                continue; // Nothing to check here since strictly typed to address
            } else if (currentMetadata == Metadatas.Safe) {
                require(
                    proposal.safeMetadata.signers.length != 0,
                    "GovernorMetadataValidation: there cannot be zero signers in safeMetadata"
                );
                require(
                    proposal.safeMetadata.threshold != 0,
                    "GovernorMetadataValidation: threshold cannot be zero in safeMetadata"
                );
            } else {
                revert TooManyMetadatas();
            }
        }
        require(bytes(proposal.description).length != 0, "Governor: empty proposal descriptions are not allowed");
        return true;
    }

    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(ProposalCore calldata proposal, bytes32[] calldata proof)
        public
        virtual
        override
        returns (uint256)
    {
        require(verifyProposer(msg.sender, proof), "Governor: address is not permissioned to submit");
        require(validateProposalData(proposal), "Governor: proposal content failed validation");
        return _castProposal(proposal);
    }

    /**
     * @dev See {IGovernor-proposeWithoutProof}.
     */
    function proposeWithoutProof(ProposalCore calldata proposal) public virtual override returns (uint256) {
        if (submissionMerkleRoot != 0) {
            // if the submission root is 0, then anyone can submit; otherwise, this address needs to have been verified
            require(addressSubmitterVerified[msg.sender], "Governor: address is not permissioned to submit");
        }
        require(validateProposalData(proposal), "Governor: proposal content failed validation");
        return _castProposal(proposal);
    }

    function _castProposal(ProposalCore memory proposal) internal virtual returns (uint256) {
        require(state() == ContestState.Queued, "Governor: contest must be queued for proposals to be submitted");
        require(
            numSubmissions[msg.sender] < numAllowedProposalSubmissions(),
            "Governor: the same address cannot submit more than the numAllowedProposalSubmissions for this contest"
        );
        require(
            (proposalIds.length - deletedProposalIds.length) < maxProposalCount(),
            "Governor: the max number of proposals have been submitted"
        );

        uint256 proposalId = hashProposal(proposal);
        require(!proposals[proposalId].exists, "Governor: duplicate proposals not allowed");

        proposalIds.push(proposalId);
        proposals[proposalId] = proposal;
        numSubmissions[msg.sender] += 1;
        proposalAuthors.push(msg.sender);

        emit ProposalCreated(proposalId, msg.sender);

        return proposalId;
    }

    /**
     * @dev Delete proposals.
     *
     * Emits a {IGovernor-ProposalsDeleted} event.
     */
    function deleteProposals(uint256[] calldata proposalIdsToDelete) public virtual {
        require(msg.sender == creator(), "Governor: only the contest creator can delete proposals");
        require(
            state() != ContestState.Completed,
            "Governor: deletion of proposals after the end of a contest is not allowed"
        );

        for (uint256 index = 0; index < proposalIdsToDelete.length; index++) {
            uint256 currentProposalId = proposalIdsToDelete[index];
            if (!proposalIsDeleted[currentProposalId]) {
                // if this proposal hasn't already been deleted
                proposalIsDeleted[currentProposalId] = true;
                // this proposal now won't count towards the total number allowed in the contest
                // it will still count towards the total number of proposals that the user is allowed to submit though
                deletedProposalIds.push(currentProposalId);
            }
        }

        emit ProposalsDeleted(proposalIds);
    }

    /**
     * @dev
     *
     * Emits a {IGovernor-ContestCanceled} event.
     */
    function cancel() public virtual {
        require(
            ((msg.sender == creator()) || (msg.sender == JK_LABS_ADDRESS)),
            "Governor: only creator or jk labs can cancel a contest"
        );

        ContestState status = state();

        require(status != ContestState.Canceled && status != ContestState.Completed, "Governor: contest not active");
        canceled = true;

        emit ContestCanceled();
    }

    /**
     * @dev See {IGovernor-verifyVoter}.
     */
    function verifyVoter(address account, uint256 totalVotes, bytes32[] calldata proof)
        public
        override
        returns (bool verified)
    {
        if (!addressTotalVotesVerified[account]) {
            checkProof(account, totalVotes, proof, true); // will revert with NotInMerkle if not valid
            addressTotalVotes[account] = totalVotes;
            addressTotalVotesVerified[account] = true;
        }
        return true;
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support, uint256 totalVotes, uint256 numVotes, bytes32[] calldata proof)
        public
        virtual
        override
        returns (uint256)
    {
        address voter = msg.sender;
        require(!isProposalDeleted(proposalId), "Governor: you cannot vote on a deleted proposal");
        require(verifyVoter(voter, totalVotes, proof), "Governor: this address is not permissioned to vote");
        return _castVote(proposalId, voter, support, numVotes);
    }

    /**
     * @dev See {IGovernor-castVoteWithoutProof}.
     */
    function castVoteWithoutProof(uint256 proposalId, uint8 support, uint256 numVotes)
        public
        virtual
        override
        returns (uint256)
    {
        address voter = msg.sender;
        require(!isProposalDeleted(proposalId), "Governor: you cannot vote on a deleted proposal");
        require(
            addressTotalVotesVerified[voter],
            "Governor: you need to cast a vote with the proof at least once and you haven't yet"
        );
        return _castVote(proposalId, voter, support, numVotes);
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using addressTotalVotes() and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(uint256 proposalId, address account, uint8 support, uint256 numVotes)
        internal
        virtual
        returns (uint256)
    {
        require(state() == ContestState.Active, "Governor: vote not currently active");
        require(numVotes > 0, "Governor: cannot vote with 0 or fewer votes");

        require(
            addressTotalVotesVerified[account],
            "Governor: you need to verify your number of votes against the merkle root first"
        );
        _countVote(proposalId, account, support, numVotes, addressTotalVotes[account]);

        addressesThatHaveVoted.push(msg.sender);

        emit VoteCast(account, proposalId, support, numVotes);

        return addressTotalVotes[account];
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (utils/Timers.sol)

/**
 * @dev Tooling for timepoints, timers and delays
 *
 * CAUTION: This file is deprecated as of 4.9 and will be removed in the next major release.
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

/**
 * @dev Extension of {Governor} for settings updatable through governance.
 */
abstract contract GovernorSettings is Governor {
    uint256 private _contestStart;
    uint256 private _votingDelay;
    uint256 private _votingPeriod;
    uint256 private _numAllowedProposalSubmissions;
    uint256 private _maxProposalCount;
    uint256 private _downvotingAllowed;
    address private _creator;

    event ContestStartSet(uint256 oldContestStart, uint256 newContestStart);
    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event NumAllowedProposalSubmissionsSet(
        uint256 oldNumAllowedProposalSubmissions, uint256 newNumAllowedProposalSubmissions
    );
    event MaxProposalCountSet(uint256 oldMaxProposalCount, uint256 newMaxProposalCount);
    event DownvotingAllowedSet(uint256 oldDownvotingAllowed, uint256 newDownvotingAllowed);
    event CreatorSet(address oldCreator, address newCreator);

    /**
     * @dev Initialize the governance parameters.
     */
    constructor(
        uint256 initialContestStart,
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialNumAllowedProposalSubmissions,
        uint256 initialMaxProposalCount,
        uint256 initialDownvotingAllowed
    ) {
        _setContestStart(initialContestStart);
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
        _setNumAllowedProposalSubmissions(initialNumAllowedProposalSubmissions);
        _setMaxProposalCount(initialMaxProposalCount);
        _setDownvotingAllowed(initialDownvotingAllowed);
        _setCreator(msg.sender);
    }

    /**
     * @dev See {IGovernor-contestStart}.
     */
    function contestStart() public view virtual override returns (uint256) {
        return _contestStart;
    }

    /**
     * @dev See {IGovernor-votingDelay}.
     */
    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    /**
     * @dev See {IGovernor-votingPeriod}.
     */
    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    /**
     * @dev See {Governor-numAllowedProposalSubmissions}.
     */
    function numAllowedProposalSubmissions() public view virtual override returns (uint256) {
        return _numAllowedProposalSubmissions;
    }

    /**
     * @dev Max number of proposals allowed in this contest
     */
    function maxProposalCount() public view virtual override returns (uint256) {
        return _maxProposalCount;
    }

    /**
     * @dev If downvoting is enabled in this contest
     */
    function downvotingAllowed() public view virtual override returns (uint256) {
        return _downvotingAllowed;
    }

    /**
     * @dev See {IGovernor-creator}.
     */
    function creator() public view virtual override returns (address) {
        return _creator;
    }

    /**
     * @dev Internal setter for the contestStart.
     *
     * Emits a {ContestStartSet} event.
     */
    function _setContestStart(uint256 newContestStart) internal virtual {
        emit ContestStartSet(_contestStart, newContestStart);
        _contestStart = newContestStart;
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _setVotingDelay(uint256 newVotingDelay) internal virtual {
        emit VotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    /**
     * @dev Internal setter for the voting period.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function _setVotingPeriod(uint256 newVotingPeriod) internal virtual {
        // voting period must be at least one block long
        require(newVotingPeriod > 0, "GovernorSettings: voting period too low");
        emit VotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Internal setter for the number of allowed proposal submissions per permissioned address.
     *
     * Emits a {NumAllowedProposalSubmissionsSet} event.
     */
    function _setNumAllowedProposalSubmissions(uint256 newNumAllowedProposalSubmissions) internal virtual {
        emit NumAllowedProposalSubmissionsSet(_numAllowedProposalSubmissions, newNumAllowedProposalSubmissions);
        _numAllowedProposalSubmissions = newNumAllowedProposalSubmissions;
    }

    /**
     * @dev Internal setter for the max proposal count.
     *
     * Emits a {MaxProposalCountSet} event.
     */
    function _setMaxProposalCount(uint256 newMaxProposalCount) internal virtual {
        emit MaxProposalCountSet(_maxProposalCount, newMaxProposalCount);
        _maxProposalCount = newMaxProposalCount;
    }

    /**
     * @dev Internal setter for if downvoting is allowed.
     *
     * Emits a {DownvotingAllowedSet} event.
     */
    function _setDownvotingAllowed(uint256 newDownvotingAllowed) internal virtual {
        emit DownvotingAllowedSet(_downvotingAllowed, newDownvotingAllowed);
        _downvotingAllowed = newDownvotingAllowed;
    }

    /**
     * @dev Internal setter for creator.
     *
     * Emits a {CreatorSet} event.
     */
    function _setCreator(address newCreator) internal virtual {
        emit CreatorSet(_creator, newCreator);
        _creator = newCreator;
    }
}

/**
 * @dev Extension of {Governor} for simple, 3 options, vote counting.
 */
abstract contract GovernorCountingSimple is Governor {
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        For,
        Against
    }

    struct VoteCounts {
        uint256 forVotes;
        uint256 againstVotes;
    }

    struct ProposalVote {
        VoteCounts proposalVoteCounts;
        address[] addressesVoted;
        mapping(address => VoteCounts) addressVoteCounts;
    }

    uint256 public totalVotesCast; // Total votes cast in contest so far
    mapping(address => uint256) public addressTotalCastVoteCounts;
    mapping(uint256 => ProposalVote) public proposalVotesStructs;

    /**
     * @dev Accessor to the internal vote counts for a given proposal.
     */
    function proposalVotes(uint256 proposalId) public view virtual returns (uint256 forVotes, uint256 againstVotes) {
        ProposalVote storage proposalvote = proposalVotesStructs[proposalId];
        return (proposalvote.proposalVoteCounts.forVotes, proposalvote.proposalVoteCounts.againstVotes);
    }

    /**
     * @dev Accessor to how many votes an address has cast for a given proposal.
     */
    function proposalAddressVotes(uint256 proposalId, address userAddress)
        public
        view
        virtual
        returns (uint256 forVotes, uint256 againstVotes)
    {
        ProposalVote storage proposalvote = proposalVotesStructs[proposalId];
        return (
            proposalvote.addressVoteCounts[userAddress].forVotes,
            proposalvote.addressVoteCounts[userAddress].againstVotes
        );
    }

    /**
     * @dev Accessor to which addresses have cast a vote for a given proposal.
     */
    function proposalAddressesHaveVoted(uint256 proposalId) public view virtual returns (address[] memory) {
        ProposalVote storage proposalvote = proposalVotesStructs[proposalId];
        return proposalvote.addressesVoted;
    }

    /**
     * @dev Accessor to how many votes an address has cast total for the contest so far.
     */
    function contestAddressTotalVotesCast(address userAddress)
        public
        view
        virtual
        returns (uint256 userTotalVotesCast)
    {
        return addressTotalCastVoteCounts[userAddress];
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(uint256 proposalId, address account, uint8 support, uint256 numVotes, uint256 totalVotes)
        internal
        virtual
        override
    {
        ProposalVote storage proposalvote = proposalVotesStructs[proposalId];

        require(
            numVotes <= (totalVotes - addressTotalCastVoteCounts[account]),
            "GovernorVotingSimple: not enough votes left to cast"
        );

        bool firstTimeVoting = (
            proposalvote.addressVoteCounts[account].forVotes == 0
                && proposalvote.addressVoteCounts[account].againstVotes == 0
        );

        if (support == uint8(VoteType.For)) {
            proposalvote.proposalVoteCounts.forVotes += numVotes;
            proposalvote.addressVoteCounts[account].forVotes += numVotes;
        } else if (support == uint8(VoteType.Against)) {
            require(downvotingAllowed() == 1, "GovernorVotingSimple: downvoting is not enabled for this Contest");
            proposalvote.proposalVoteCounts.againstVotes += numVotes;
            proposalvote.addressVoteCounts[account].againstVotes += numVotes;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }

        if (firstTimeVoting) {
            proposalvote.addressesVoted.push(account);
        }
        addressTotalCastVoteCounts[account] += numVotes;
        totalVotesCast += numVotes;
    }
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

/**
 * @dev Extension of {GovernorCountingSimple} for sorting and ranking.
 *
 * _Available since v4.3._
 */
abstract contract GovernorSorting is GovernorCountingSimple {
    bool public setSortedAndTiedProposalsHasBeenRun = false;
    mapping(uint256 => uint256) public tiedAdjustedRankingPosition; // key is ranking, value is index of the last iteration of that ranking's value in the _sortedProposalIds array taking ties into account

    mapping(uint256 => bool) private _isTied; // whether a ranking is tied. key is ranking.
    uint256[] private _sortedProposalIds;
    uint256 private _lowestRanking; // worst ranking (1 is the best possible ranking, 8 is a lower/worse ranking than 1)
    uint256 private _highestTiedRanking; // best (1 is better than 8) ranking that is tied

    /**
     * @dev Getter if a given ranking is tied.
     */
    function isTied(uint256 ranking) public view returns (bool) {
        require(
            setSortedAndTiedProposalsHasBeenRun, "RewardsModule: run setSortedAndTiedProposals() to populate this value"
        );
        return _isTied[ranking];
    }

    /**
     * @dev Getter for tiedAdjustedRankingPosition of a ranking.
     */
    function rankingPosition(uint256 ranking) public view returns (uint256) {
        require(
            setSortedAndTiedProposalsHasBeenRun, "RewardsModule: run setSortedAndTiedProposals() to populate this value"
        );
        return tiedAdjustedRankingPosition[ranking];
    }

    /**
     * @dev Getter for _sortedProposalIds.
     */
    function sortedProposalIds() public view returns (uint256[] memory) {
        require(
            setSortedAndTiedProposalsHasBeenRun, "RewardsModule: run setSortedAndTiedProposals() to populate this value"
        );
        return _sortedProposalIds;
    }

    /**
     * @dev Getter for the lowest ranking.
     */
    function lowestRanking() public view returns (uint256) {
        require(
            setSortedAndTiedProposalsHasBeenRun, "RewardsModule: run setSortedAndTiedProposals() to populate this value"
        );
        return _lowestRanking;
    }

    /**
     * @dev Getter for highest tied ranking.
     */
    function highestTiedRanking() public view returns (uint256) {
        require(
            setSortedAndTiedProposalsHasBeenRun, "RewardsModule: run setSortedAndTiedProposals() to populate this value"
        );
        return _highestTiedRanking;
    }

    /**
     * @dev Accessor to the internal vote counts for a given proposal.
     */
    function allProposalTotalVotes()
        public
        view
        virtual
        returns (uint256[] memory proposalIdsReturn, VoteCounts[] memory proposalVoteCountsArrayReturn)
    {
        uint256[] memory proposalIdsMemVar = proposalIds;
        VoteCounts[] memory proposalVoteCountsArray = new VoteCounts[](proposalIdsMemVar.length);
        for (uint256 i = 0; i < proposalIdsMemVar.length; i++) {
            proposalVoteCountsArray[i] = proposalVotesStructs[proposalIdsMemVar[i]].proposalVoteCounts;
        }
        return (proposalIdsMemVar, proposalVoteCountsArray);
    }

    /**
     * @dev Accessor to the internal vote counts for a given proposal that excludes deleted proposals.
     */
    function allProposalTotalVotesWithoutDeleted()
        public
        view
        virtual
        returns (uint256[] memory proposalIdsReturn, VoteCounts[] memory proposalVoteCountsArrayReturn)
    {
        uint256[] memory proposalIdsMemVar = proposalIds;
        uint256[] memory proposalIdsWithoutDeleted = new uint256[](proposalIdsMemVar.length);
        VoteCounts[] memory proposalVoteCountsArray = new VoteCounts[](proposalIdsMemVar.length);

        uint256 newArraysIndexCounter = 0;
        for (uint256 i = 0; i < proposalIdsMemVar.length; i++) {
            if (!isProposalDeleted(proposalIdsMemVar[i])) {
                proposalIdsWithoutDeleted[newArraysIndexCounter] = proposalIdsMemVar[i];
                proposalVoteCountsArray[newArraysIndexCounter] =
                    proposalVotesStructs[proposalIdsMemVar[i]].proposalVoteCounts;
                newArraysIndexCounter += 1;
            }
        }
        return (proposalIdsWithoutDeleted, proposalVoteCountsArray);
    }

    function _sortItem(uint256 pos, int256[] memory netProposalVotes, uint256[] memory proposalIds)
        internal
        pure
        returns (bool)
    {
        uint256 wMin = pos;
        for (uint256 i = pos; i < netProposalVotes.length; i++) {
            if (netProposalVotes[i] < netProposalVotes[wMin]) {
                wMin = i;
            }
        }
        if (wMin == pos) return false;
        int256 votesTmp = netProposalVotes[pos];
        netProposalVotes[pos] = netProposalVotes[wMin];
        netProposalVotes[wMin] = votesTmp;
        uint256 proposalIdsTmp = proposalIds[pos];
        proposalIds[pos] = proposalIds[wMin];
        proposalIds[wMin] = proposalIdsTmp;
        return true;
    }

    /**
     * @dev Accessor to sorted list of proposalIds in ascending order.
     */
    function sortedProposals(bool excludeDeletedProposals)
        public
        view
        virtual
        returns (uint256[] memory sortedProposalIdsReturn)
    {
        (uint256[] memory proposalIdList, VoteCounts[] memory proposalVoteCountsArray) =
            excludeDeletedProposals ? allProposalTotalVotesWithoutDeleted() : allProposalTotalVotes();
        require(proposalIdList.length > 0, "GovernorSorting: cannot sort a list of zero length");
        int256[] memory netProposalVotes = new int256[](proposalIdList.length);
        for (uint256 i = 0; i < proposalVoteCountsArray.length; i++) {
            netProposalVotes[i] = SafeCast.toInt256(proposalVoteCountsArray[i].forVotes)
                - SafeCast.toInt256(proposalVoteCountsArray[i].againstVotes);
        }
        for (uint256 i = 0; i < proposalIdList.length - 1; i++) {
            // Only goes to length minus 1 because sorting the last item would be redundant
            _sortItem(i, netProposalVotes, proposalIdList);
        }
        return proposalIdList;
    }

    /**
     * @dev Setter for _sortedProposalIds, tiedAdjustedRankingPosition, _isTied, _lowestRanking,
     * and _highestTiedRanking. Will only be called once and only needs to be called once because once the contest
     * is complete these values don't change. Determines if a ranking is tied and also where the last
     * iteration of a ranking is in the _sortedProposalIds list taking ties into account.
     */
    function setSortedAndTiedProposals() public virtual {
        require(
            state() == IGovernor.ContestState.Completed,
            "GovernorSorting: contest must be to calculate sorted and tied proposals"
        );
        require(
            !setSortedAndTiedProposalsHasBeenRun,
            "GovernorSorting: setSortedAndTiedProposals() has already been run and its respective values set"
        );

        _sortedProposalIds = sortedProposals(true);

        int256 lastTotalVotes;
        uint256 rankingBeingChecked = 1;
        _highestTiedRanking = _sortedProposalIds.length + 1; // set as default so that it isn't 0 if no ties are found
        uint256 sortedProposalIdsLength = _sortedProposalIds.length;
        for (uint256 i = 0; i < sortedProposalIdsLength; i++) {
            uint256 lastSortedItemIndex = _sortedProposalIds.length - 1;

            // decrement through the ascending sorted list
            (uint256 currentForVotes, uint256 currentAgainstVotes) =
                proposalVotes(_sortedProposalIds[lastSortedItemIndex - i]);
            int256 currentTotalVotes = SafeCast.toInt256(currentForVotes) - SafeCast.toInt256(currentAgainstVotes);

            // if on first item, set lastTotalVotes and continue
            if (i == 0) {
                lastTotalVotes = currentTotalVotes;

                // if on last item, then the value at the current index is
                // the last iteration of the last ranking's value
                if (_sortedProposalIds.length == 1) {
                    tiedAdjustedRankingPosition[rankingBeingChecked] = lastSortedItemIndex;
                    _lowestRanking = rankingBeingChecked;
                }

                continue;
            }

            // if there is a tie, mark that this ranking is tied
            if (currentTotalVotes == lastTotalVotes) {
                if (!_isTied[rankingBeingChecked]) {
                    // if this is not already set
                    _isTied[rankingBeingChecked] = true;
                }
                if (_highestTiedRanking == _sortedProposalIds.length + 1) {
                    // if this is the first tie found, set it as the highest tied ranking
                    _highestTiedRanking = rankingBeingChecked;
                }
            } else {
                // otherwise, mark that the last iteration of this ranking's value is at the index
                // above the current index in the sorted list, then increment the ranking being checked

                // index we last decremented from is the last iteration of the current rank's value
                tiedAdjustedRankingPosition[rankingBeingChecked] = lastSortedItemIndex - i + 1;
                rankingBeingChecked++;
            }

            // if on last item, then the value at the current index is the last iteration of the last ranking's value
            if (i + 1 == _sortedProposalIds.length) {
                tiedAdjustedRankingPosition[rankingBeingChecked] = lastSortedItemIndex - i;
                _lowestRanking = rankingBeingChecked;
            }

            lastTotalVotes = currentTotalVotes;
        }

        setSortedAndTiedProposalsHasBeenRun = true;
    }
}

/**
 * @title RewardsModule
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned. The distribution of shares is set at the
 * time of contract deployment and can't be updated thereafter.
 *
 * `RewardsModule` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract RewardsModule is Context {
    event PayeeAdded(uint256 ranking, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event RewardWithdrawn(address by, uint256 amount);
    event ERC20RewardWithdrawn(IERC20 indexed token, address by, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(uint256 => uint256) private _shares;
    mapping(uint256 => uint256) private _released;
    uint256[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(uint256 => uint256)) private _erc20Released;

    GovernorSorting private immutable _underlyingContest;
    address private immutable _creator;
    bool private immutable _paysOutTarget; // if true, pay out target address; if false, pay out proposal author

    /**
     * @dev Creates an instance of `RewardsModule` where each ranking in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All rankings in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(
        uint256[] memory payees,
        uint256[] memory shares_,
        GovernorSorting underlyingContest_,
        bool paysOutTarget_
    ) payable {
        require(payees.length == shares_.length, "RewardsModule: payees and shares length mismatch");
        require(payees.length > 0, "RewardsModule: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }

        require(_totalShares != 0, "RewardsModule: the total number of shares cannot equal 0");

        _paysOutTarget = paysOutTarget_;
        _underlyingContest = underlyingContest_;
        _creator = msg.sender;
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     */
    receive() external payable virtual {
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * @dev Version of the rewards module. Default: "1"
     */
    function version() public view virtual returns (string memory) {
        return "3.18";
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the creator of this rewards contract.
     */
    function creator() public view returns (address) {
        return _creator;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by a ranking.
     */
    function shares(uint256 ranking) public view returns (uint256) {
        return _shares[ranking];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(uint256 ranking) public view returns (uint256) {
        return _released[ranking];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, uint256 ranking) public view returns (uint256) {
        return _erc20Released[token][ranking];
    }

    /**
     * @dev Getter for list of rankings that will be paid out.
     */
    function getPayees() public view returns (uint256[] memory) {
        return _payees;
    }

    /**
     * @dev Getter for whether this pays out the target address or author of a proposal.
     */
    function paysOutTarget() public view returns (bool) {
        return _paysOutTarget;
    }

    /**
     * @dev Getter for the underlying contest.
     */
    function underlyingContest() public view returns (GovernorCountingSimple) {
        return _underlyingContest;
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(uint256 ranking) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + totalReleased();
        return _pendingPayment(ranking, totalReceived, released(ranking));
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, uint256 ranking) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(ranking, totalReceived, released(token, ranking));
    }

    /**
     * @dev Triggers a transfer to `ranking` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(uint256 ranking) public virtual {
        require(ranking != 0, "RewardsModule: ranking must be 1 or greater");
        require(
            _underlyingContest.state() == IGovernor.ContestState.Completed,
            "RewardsModule: contest must be completed for rewards to be paid out"
        );
        require(_shares[ranking] > 0, "RewardsModule: ranking has no shares");

        uint256 payment = releasable(ranking);

        require(
            payment != 0,
            "RewardsModule: account isn't due payment as there isn't any native currency in the module to pay out"
        );

        // _totalReleased is the sum of all values in _released.
        // If "_totalReleased += payment" does not overflow, then "_released[account] += payment" cannot overflow.
        _totalReleased += payment;
        unchecked {
            _released[ranking] += payment;
        }

        // if not already set, set _sortedProposalIds, _tiedAdjustedRankingPosition, _isTied,
        // _lowestRanking, and _highestTiedRanking
        if (!_underlyingContest.setSortedAndTiedProposalsHasBeenRun()) {
            _underlyingContest.setSortedAndTiedProposals();
        }

        require(
            ranking <= _underlyingContest.lowestRanking(),
            "RewardsModule: there are not enough proposals for that ranking to exist, taking ties into account"
        );

        IGovernor.ProposalCore memory rankingProposal = _underlyingContest.getProposal(
            _underlyingContest.sortedProposalIds()[_underlyingContest.tiedAdjustedRankingPosition(ranking)]
        );

        // send rewards to winner only if the ranking is higher than the highest tied ranking
        address payable addressToPayOut = ranking < _underlyingContest.highestTiedRanking()
            ? _paysOutTarget ? payable(rankingProposal.targetMetadata.targetAddress) : payable(rankingProposal.author)
            : payable(creator());

        require(addressToPayOut != address(0), "RewardsModule: account is the zero address");

        emit PaymentReleased(addressToPayOut, payment);
        Address.sendValue(addressToPayOut, payment);
    }

    /**
     * @dev Triggers a transfer to `ranking` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, uint256 ranking) public virtual {
        require(ranking != 0, "RewardsModule: ranking must be 1 or greater");
        require(
            _underlyingContest.state() == IGovernor.ContestState.Completed,
            "RewardsModule: contest must be completed for rewards to be paid out"
        );
        require(_shares[ranking] > 0, "RewardsModule: ranking has no shares");

        uint256 payment = releasable(token, ranking);

        require(
            payment != 0,
            "RewardsModule: account isn't due payment as there isn't any native currency in the module to pay out"
        );

        // _erc20TotalReleased[token] is the sum of all values in _erc20Released[token].
        // If "_erc20TotalReleased[token] += payment" does not overflow, then "_erc20Released[token][account] += payment" cannot overflow.
        _erc20TotalReleased[token] += payment;
        unchecked {
            _erc20Released[token][ranking] += payment;
        }

        // if not already set, set _sortedProposalIds, _tiedAdjustedRankingPosition, _isTied,
        // _lowestRanking, and _highestTiedRanking
        if (!_underlyingContest.setSortedAndTiedProposalsHasBeenRun()) {
            _underlyingContest.setSortedAndTiedProposals();
        }

        require(
            ranking <= _underlyingContest.lowestRanking(),
            "RewardsModule: there are not enough proposals for that ranking to exist, taking ties into account"
        );

        IGovernor.ProposalCore memory rankingProposal = _underlyingContest.getProposal(
            _underlyingContest.sortedProposalIds()[_underlyingContest.tiedAdjustedRankingPosition(ranking)]
        );

        // send rewards to winner only if the ranking is higher than the highest tied ranking
        address payable addressToPayOut = ranking < _underlyingContest.highestTiedRanking()
            ? _paysOutTarget ? payable(rankingProposal.targetMetadata.targetAddress) : payable(rankingProposal.author)
            : payable(creator());

        require(addressToPayOut != address(0), "RewardsModule: account is the zero address");

        emit ERC20PaymentReleased(token, addressToPayOut, payment);
        SafeERC20.safeTransfer(token, addressToPayOut, payment);
    }

    function withdrawRewards() public virtual {
        require(msg.sender == creator(), "RewardsModule: only the creator can withdraw rewards");

        emit RewardWithdrawn(creator(), address(this).balance);
        Address.sendValue(payable(creator()), address(this).balance);
    }

    function withdrawRewards(IERC20 token) public virtual {
        require(msg.sender == creator(), "RewardsModule: only the creator can withdraw rewards");

        emit ERC20RewardWithdrawn(token, creator(), token.balanceOf(address(this)));
        SafeERC20.safeTransfer(token, payable(creator()), token.balanceOf(address(this)));
    }

    /**
     * @dev internal logic for computing the pending payment of a `ranking` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(uint256 ranking, uint256 totalReceived, uint256 alreadyReleased)
        private
        view
        returns (uint256)
    {
        return (totalReceived * _shares[ranking]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param ranking The ranking of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(uint256 ranking, uint256 shares_) private {
        require(ranking > 0, "RewardsModule: ranking is 0, must be greater");
        require(shares_ > 0, "RewardsModule: shares are 0");
        require(_shares[ranking] == 0, "RewardsModule: account already has shares");

        _payees.push(ranking);
        _shares[ranking] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(ranking, shares_);
    }
}

/**
 * @dev Extension of {Governor} for module management.
 *
 */
abstract contract GovernorModuleRegistry is Governor {
    event OfficialRewardsModuleSet(RewardsModule oldOfficialRewardsModule, RewardsModule newOfficialRewardsModule);

    RewardsModule public officialRewardsModule;

    /**
     * @dev Get the official rewards module contract for this contest (effectively reverse record).
     */
    function setOfficialRewardsModule(RewardsModule officialRewardsModule_) public virtual {
        require(msg.sender == creator(), "GovernorModuleRegistry: only the creator can set the official rewards module");
        RewardsModule oldOfficialRewardsModule = officialRewardsModule;
        officialRewardsModule = officialRewardsModule_;
        emit OfficialRewardsModuleSet(oldOfficialRewardsModule, officialRewardsModule_);
    }
}

contract Contest is Governor, GovernorSettings, GovernorSorting, GovernorModuleRegistry {
    constructor(
        string memory _name,
        string memory _prompt,
        bytes32 _submissionMerkleRoot,
        bytes32 _votingMerkleRoot,
        uint256[] memory _constructorIntParams
    )
        Governor(_name, _prompt, _submissionMerkleRoot, _votingMerkleRoot)
        GovernorSettings(
            _constructorIntParams[0], // _initialContestStart
            _constructorIntParams[1], // _initialVotingDelay,
            _constructorIntParams[2], // _initialVotingPeriod,
            _constructorIntParams[3], // _initialNumAllowedProposalSubmissions,
            _constructorIntParams[4], // _initialMaxProposalCount
            _constructorIntParams[5] // _initialDownvotingAllowed
        )
    {}

    // The following functions are overrides required by Solidity.

    function contestStart() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.contestStart();
    }

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function numAllowedProposalSubmissions() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.numAllowedProposalSubmissions();
    }

    function maxProposalCount() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.maxProposalCount();
    }

    function downvotingAllowed() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.downvotingAllowed();
    }

    function creator() public view override(IGovernor, GovernorSettings) returns (address) {
        return super.creator();
    }
}