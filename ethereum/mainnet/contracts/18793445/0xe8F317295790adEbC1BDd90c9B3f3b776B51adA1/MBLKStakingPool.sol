/**
 *Submitted for verification at Etherscan.io on 2023-12-15
*/

/**
 *Submitted for verification at Etherscan.io on 2023-12-11
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


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

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;




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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: 1_sLP_1.sol


pragma solidity ^0.8.0;






contract LPStaked is ERC20, Ownable,Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("LPStaked", "sLP") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
     }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
   
    /**
     * @dev Burns a specific amount of tokens from the sender's balance.
     * @param amount The amount of tokens to be burned.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address's balance.
     * @param account The address whose tokens will be burned.
     * @param amount The amount of tokens to be burned.
     */
    function burnFrom(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        _burn(account, amount);
    }

    /**
     * @dev Mints new tokens and assigns them to the target address.
     * @param account The address to which new tokens will be minted.
     * @param amount The amount of tokens to be minted.
     */
    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    /**
     * @dev Grants the minter role to a new address.
     * @param account The address to which the minter role will be granted.
     */
    function grantMinterRole(address account) external onlyOwner {
        grantRole(MINTER_ROLE, account);
    }

    /**
     * @dev Revokes the minter role from an address.
     * @param account The address from which the minter role will be revoked.
     */
    function revokeMinterRole(address account) external onlyOwner {
        revokeRole(MINTER_ROLE, account);
    }
     function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

 
// File: 1_sMBLK_1.sol


pragma solidity ^0.8.0;






contract MBLKStaked is ERC20, Ownable,Pausable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("MBLKStaked", "sMBLK") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
   
    /**
     * @dev Burns a specific amount of tokens from the sender's balance.
     * @param amount The amount of tokens to be burned.
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address's balance.
     * @param account The address whose tokens will be burned.
     * @param amount The amount of tokens to be burned.
     */
    function burnFrom(address account, uint256 amount) external onlyRole(MINTER_ROLE) {
        _burn(account, amount);
    }

    /**
     * @dev Mints new tokens and assigns them to the target address.
     * @param account The address to which new tokens will be minted.
     * @param amount The amount of tokens to be minted.
     */
    function mint(address account, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(account, amount);
    }

    /**
     * @dev Grants the minter role to a new address.
     * @param account The address to which the minter role will be granted.
     */
    function grantMinterRole(address account) external onlyOwner {
        grantRole(MINTER_ROLE, account);
    }

    /**
     * @dev Revokes the minter role from an address.
     * @param account The address from which the minter role will be revoked.
     */
    function revokeMinterRole(address account) external onlyOwner {
        revokeRole(MINTER_ROLE, account);
    }
     function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

 
// File: NewStakingCOntract.sol



pragma solidity 0.8.23;








contract MBLKStakingPool is  Ownable,ReentrancyGuard {
    
    using SafeERC20 for IERC20;
    IERC20 public immutable mblkToken;     
    MBLKStaked public immutable smblkToken;  
    LPStaked public immutable slpToken;  
    IERC20 public immutable lpToken;       
  
    // Struct to represent MBLK staking details for a user
    struct MBLKStake {
        uint256 mblkAmount;           // Amount of MBLK tokens staked
        uint256 startTimestamp;       // Timestamp when the staking started
        uint256 endTime;              // Timestamp when the staking ends
        uint256 claimedReward;        // Amount of claimed rewards by the user
        uint256 lastClaimedTimeStamp; // Timestamp of the last claimed reward
        uint256 smblkMinted;          // Amount of sMBLK (staking MBLK) tokens minted as rewards
        uint256 cycleId;              // Identifier of the staking cycle
        // uint256 withdrawPeriod;
        uint256 lastEndTime;
    }
    
    // Struct representing the LP staking details for a user
    struct LPStake {
        uint256 lpAmount;               // Amount of liquidity provider tokens staked
        uint256 startTimestamp;         // Timestamp when the LP staking started
        uint256 endTime;                // Timestamp when the LP staking ends
        uint256 claimedReward;          // Amount of claimed rewards by the LP
        uint256 lastClaimedTimeStamp;   // Timestamp of the last claimed reward by the LP
        uint256 slpMinted;              // Amount of sLP (staking LP) tokens minted as rewards
        uint256 cycleId;                // Identifier of the staking cycle for LPs
        // uint256 withdrawPeriod;
        uint256 lastEndTime;
    }

   // Struct representing information related to a staking cycle
    struct StakingInfo {
        uint256 cycleId;           // Identifier for the staking cycle
        uint256 blockTimeStamp;    // Timestamp of the block when the staking cycle was created
        uint256 totalReward;       // Total reward allocated for current cycle 
        uint256 totalLpStaked;     // Total amount of Liquidity Provider (LP) tokens staked in this cycle
        uint256 totalMblkStaked;   // Total amount of MBLK tokens staked in this cycle
    }

    // Mapping to store MBLKStake struct information associated with user addresses
    mapping(address => MBLKStake) public userMblkStakes;

    // Mapping to store LPStake struct information associated with user addresses
    mapping(address => LPStake) public userLpStakes;

    // Mapping to manage administrator privileges for specific addresses
    mapping(address => bool) public isAdmin;

    // Mapping to maintain StakingInfo struct data corresponding to specific cycle IDs
    mapping(uint256 => StakingInfo) public stakingInfo;

    // Total amount of MBLK tokens staked 
    uint256 public totalMblkStaked;

    // Total amount of LP tokens staked 
    uint256 public totalLpStaked;

    uint256 totalClaimedRewards;

    // Total amount of sMBLK tokens minted  
    uint256 public totalSmblkMinted;

    // Total amount of sLP tokens minted  
    uint256 public totalSlpMinted;

    // Current cycle identifier
    uint256 public currentCycleId;

    // Timestamp of the last dynamic reward set
    uint256 public lastDynamicRewardSet;

    // Minimum time required to calculate rewards
    uint256 public calculateRewardMinimumTime;

    // Time allocated for fixed rewards
    uint256 public  timeForFixedReward;

    // Time allocated for dynamic rewards
    uint256 public  timeForDynamicReward;

    // Timestamp of the last fixed reward setting
    uint256 public lastFixedRewardSet;

    // Timestamp of the last total reward setting
    uint256 public lastTotalRewardSetTimestamp;

    // Fixed reward amount
    uint256 public fixedReward;

    // Dynamic reward amount
    uint256 public dynamicReward;

    // Total rewards across the platform
    uint256 public totalRewards;

    // Minimum duration for stake locking
    uint256 public minimumStakeDuration;

    // Boolean to check if rewards are set or not
//bool isRewardSent;

    //Boolean for Pause and unpause
    bool isPaused;

    // Wallet address for collecting fees
    address public feesCollectionWallet;

    // Percentage of fees charged  
    uint256 public feesPercentage;

    // mblk Reward percentage
    uint256 public constant mblkRewardPercentage = 30;

    // Lp Reward Percentage
    uint256 public constant lpRewardPercentage = 70;

    uint256 public unstakingPeriod;

    
    
 
    //Events
    event StakeMblk(address indexed user,uint256 mblkAmount);
    event StakeLp(address indexed user,uint256 lpAmount);
    event ClaimedRewardsMblk(address indexed user,uint256 rewardsAmount);
    event ClaimedRewardsLp(address indexed user,uint256 rewardsAmount);
    event MblkStakeUpdated(address userAddress, uint256 amount);
    event LpStakeUpdated(address userAddress, uint256 amount);
    event WithdrawnMblk(address indexed user, uint256 rewardsAmount);
    event WithdrawnLp(address indexed user, uint256 rewardsAmount); 
    event FeesPercentageSet(uint256 percentage);
    event TotalRewardSet(uint256 totalReward);
    event DynamicRewardSet(uint256 dynamicReward);
    event FixedRewardSet(uint256 newFixedReward);
    event MinimumStakeDurationSet(uint256 duration);
    event AdminRemoved( address adminToRemove);
    event AdminAdded( address adminAddress);
    event UpdatedCycleId(uint256 currentCycleId);
    event WithDrawnAll(address owner,uint256 BalanceMBLK);
    event FeesWalletSet(address feesCollectionWallet);
    event MinimumCalculateRewardTimeSet(uint256 time);
    event PausedStaking();
    event UnpausedStaking();

    /*
    * @dev Modifer which allows ADMIN LIST TO ACCESS THE FUNCTION
    */ 
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admins can call this function");
        _;
    } 

    constructor(
        address mblkTokenAddress,              // Address of the MBLK token contract
        address lptokenAddress,                // Address of the LP token contract
        address feesCollectionWalletAddress    // Address to collect fees or rewards
    ) payable {
        mblkToken = IERC20(mblkTokenAddress);  // Initializing MBLK token contract interface
        lpToken = IERC20(lptokenAddress);      // Initializing LP token contract interface
        feesCollectionWallet = feesCollectionWalletAddress; // Assigning the fees collection wallet address
        smblkToken = new MBLKStaked();         // Deploying a new instance of MBLKStaked contract
        slpToken = new LPStaked();             // Deploying a new instance of LPStaked contract
        // isRewardSent = false;                  // Setting the initial state for isRewardSent
        //calculateRewardMinimumTime = 6 hours;    // Setting the calculateRewardMinimumTime as 6 hours
        isPaused = false; 
        feesPercentage = 30;
        unstakingPeriod = 3 days;
        isAdmin[msg.sender] = true;
    }

    /**
     * @dev Stake a specified amount of MBLK tokens.
     * @param mblkAmount The amount of MBLK tokens to stake.
     *
     * Requirements:
     * - The staked amount must be greater than 0.
     * - The user must not have an active MBLK stake (mblkAmount must be 0).
     * - Transfer MBLK tokens from the sender to the staking contract.
     * - Record stake-related information including start and end times, rewards, and cycle ID.
     * - Mint and distribute SMBLK tokens to the staker.
     * - Update the total MBLK staked and total SMBLK minted.
     *
     * Emits a StakeMBLK event to log the staking action.
    */
    function stakeMBLK(uint256 mblkAmount) nonReentrant external {
        require(isPaused == false,"Contract is paused");
        require(mblkAmount > 0, "Amount must be greater than 0");
        require(
            mblkToken.balanceOf(msg.sender) >= mblkAmount,
            "Not enough Balance"
        );
        require(
            userMblkStakes[msg.sender].mblkAmount == 0,
            "Existing active stake found"
        ); 
        MBLKStake memory userStake = userMblkStakes[msg.sender];    

        mblkToken.safeTransferFrom(msg.sender, address(this), mblkAmount);
        uint256 blockTimeStamp = block.timestamp;   
        totalMblkStaked += mblkAmount;
        userStake.mblkAmount = mblkAmount;
        userStake.startTimestamp = blockTimeStamp;
        userStake.endTime = blockTimeStamp + minimumStakeDuration;
        
        userStake.lastEndTime = blockTimeStamp + minimumStakeDuration;
       // userStake.withdrawPeriod = blockTimeStamp + minimumStakeDuration + unstakingPeriod;

        userStake.lastClaimedTimeStamp = blockTimeStamp;
        smblkToken.mint(msg.sender,mblkAmount);  
        totalSmblkMinted += mblkAmount;
        userStake.cycleId = currentCycleId + 1;
        userStake.smblkMinted += mblkAmount;
        userMblkStakes[msg.sender] = userStake;
        emit StakeMblk(msg.sender,mblkAmount);
    }

    /**
     * @dev Stake a specified amount of LP (Liquidity Provider) tokens.
     * @param lpAmount The amount of LP tokens to stake.
     *
     * Requirements:
     * - The staked amount must be greater than 0.
     * - The sender must have a sufficient balance of LP tokens to stake.
     * - The user must not have an active LP stake (lpAmount must be 0).
     * - Transfer LP tokens from the sender to the staking contract.
     * - Record stake-related information including start and end times, rewards, and cycle ID.
     * - Mint and distribute SLP tokens to the staker.
     * - Update the total LP tokens staked and total SLP tokens minted.
     *
     * Emits a StakeLP event to log the staking action.
    */  
    function stakeLP(uint256 lpAmount) nonReentrant external {
        require(isPaused == false,"Contract is paused");
        require(lpAmount > 0, "Amount must be greater than 0 " );
        require(
            lpToken.balanceOf(msg.sender) >= lpAmount,
            "Not enough Balance"
        );
        require(
            userLpStakes[msg.sender].lpAmount == 0,
            "Existing LP Stake Found"
        );
        LPStake memory userStake = userLpStakes[msg.sender];
        lpToken.safeTransferFrom(msg.sender,address(this), lpAmount);
        totalLpStaked += lpAmount;
        uint256 blockTimeStamp = block.timestamp;
        userStake.lpAmount += lpAmount;
        userStake.startTimestamp = blockTimeStamp;
        userStake.endTime = blockTimeStamp + minimumStakeDuration;
        userStake.lastEndTime = blockTimeStamp + minimumStakeDuration;
       // userStake.withdrawPeriod = blockTimeStamp + minimumStakeDuration + unstakingPeriod;

        userStake.lastClaimedTimeStamp = blockTimeStamp;
        slpToken.mint(msg.sender,lpAmount);          //Staked LP Token MInted to User Address
        totalSlpMinted += lpAmount;
        userStake.slpMinted += lpAmount;
        userStake.cycleId = currentCycleId + 1; 
        userLpStakes[msg.sender] = userStake;
        emit StakeLp(msg.sender, lpAmount); 
    }

     /**
     * @dev Update a user's stake with additional tokens.
     * @param amount The amount of tokens to add to the user's stake.
     * @param isMblk A boolean indicating whether the stake is for MBLK (true) or LP (false).
     *
     * Requirements:
     * - The added amount must be greater than 0.
     * - The calculated rewards must be claimed first (calculatedRewards must be 0).
     * - If the stake is for MBLK, the user must have an existing active MBLK stake; if the stake is for LP, the user must have an existing active LP stake.
     * - Transfer tokens from the sender to the staking contract.
     * - Update stake-related information, including start and end times, rewards, and cycle ID.
     *
     * Emits an MblkStakeUpdated event if updating an MBLK stake, or an LpStakeUpdated event if updating an LP stake, to log the stake update.
    */
    function updateStake(uint256 amount, bool isMblk) public {
        require(isPaused == false,"Contract is paused");
        require(amount > 0, "Amount must be greater than 0");
        if(isMblk){
            require(
                mblkToken.balanceOf(msg.sender)>= amount,
                "Not enough balance"
            );
            MBLKStake memory userStake = userMblkStakes[msg.sender];    
            uint256 calculatedRewards = calculateReward(msg.sender,0,true);
            require(calculatedRewards == 0, "Please claim the rewards first");
            require(userStake.mblkAmount > 0,"Existing active stake not found");
            mblkToken.safeTransferFrom(msg.sender, address(this), amount);
            totalMblkStaked += amount;
            userStake.mblkAmount += amount;
            uint256 blockTimeStamp = block.timestamp; 
            userStake.startTimestamp = blockTimeStamp;
            userStake.endTime = blockTimeStamp + minimumStakeDuration;
            userStake.lastEndTime = blockTimeStamp + minimumStakeDuration;
            smblkToken.mint(msg.sender, amount);   
            totalSmblkMinted += amount;
            //userStake.withdrawPeriod = blockTimeStamp + minimumStakeDuration + unstakingPeriod;
            userStake.smblkMinted += amount;
            userStake.cycleId = currentCycleId + 1; 
            userMblkStakes[msg.sender] = userStake;
            emit MblkStakeUpdated(msg.sender,amount);   
        } else {
            require(
                lpToken.balanceOf(msg.sender)>= amount,
                "Not enough balance"
            );
            LPStake memory userStake = userLpStakes[msg.sender];
            uint256 calculatedRewards = calculateReward(msg.sender,0,false);
            require(calculatedRewards == 0, "Please claim the rewards first");
            require(userStake.lpAmount > 0, "Existing active stake not found");
            lpToken.safeTransferFrom(msg.sender,address(this), amount);  
            totalLpStaked += amount;
            userStake.lpAmount += amount;
            uint256 blockTimeStamp = block.timestamp; 
            userStake.startTimestamp = blockTimeStamp;
            userStake.endTime = blockTimeStamp + minimumStakeDuration;
            userStake.lastEndTime = blockTimeStamp + minimumStakeDuration;
           // userStake.withdrawPeriod = blockTimeStamp + minimumStakeDuration + unstakingPeriod;

            slpToken.mint(msg.sender, amount);  
            totalSlpMinted += amount;
            userStake.slpMinted += amount;
            userStake.cycleId = currentCycleId + 1;
            userLpStakes[msg.sender] = userStake;

            emit LpStakeUpdated(msg.sender,amount);
        }
    }

    /**
     * @dev Calculate the rewards for a user based on their staking Parcentage.
     * @param userAddress The address of the user.
     * @param isMblk A boolean indicating whether the user has MBLK staked (true) or LP staked (false).
     * @return The calculated reward amount for the user 
     *
     * Requirements:
     * - The user must have a staking amount greater than 0.
     * - The owner/admin must have set the minimum time for calculating rewards (calculateRewardMinimumTime).
     *
     * The function calculates rewards by iterating through cycles, determining the user's stake percentage, and applying it to the total rewards.
     * The calculated reward is based on the User Stake Percentage each cycle.
    */
    function calculateReward(address userAddress,uint256 uptoCycleId, bool isMblk) public view returns(uint256){ 
        require(isPaused == false,"Contract is paused");
        require(
            uptoCycleId <= currentCycleId,
            "uptoCycleId is out of range"
        );
        // require(
        //     calculateRewardMinimumTime > 0,
        //     "Owner Haven't Set calculate Reward minimum Time"
        // );
        uint256 totalRewardsCalculated;
        uint256 _iether = 10**18;
        uint256 terminationValue;
       // uint256 blockTimeStamp = block.timestamp;

        if( uptoCycleId == 0){
            terminationValue = currentCycleId;
        }else{
            terminationValue = uptoCycleId;
        }

        if(isMblk){
            MBLKStake memory userStake = userMblkStakes[userAddress];
            require(
                userStake.mblkAmount > 0,
                "No Stakes Found"
            ); 
            //uint256 elapsedTimeFromLastClaimed = blockTimeStamp - userStake.lastClaimedTimeStamp;
            // if(elapsedTimeFromLastClaimed >= calculateRewardMinimumTime){
                for(uint256 i = userStake.cycleId; i <= terminationValue; i++){
                    if(stakingInfo[i].totalMblkStaked == 0 ){ continue; }
                    uint256 totalRewardFromStakeInfo = stakingInfo[i].totalReward;
                    uint256 totalMblkStakedFromStakeInfo = stakingInfo[i].totalMblkStaked;
                    uint256 mblkStakePercentage = (userStake.mblkAmount * 100 * _iether)/(totalMblkStakedFromStakeInfo);
                    uint256 numerator = mblkStakePercentage * totalRewardFromStakeInfo * _iether * mblkRewardPercentage;
                    uint256 denominator = _iether * 10000 * _iether; 
                    uint256 totalRewardsPerCycle = numerator/denominator;
                    totalRewardsCalculated += totalRewardsPerCycle;
                }
                return totalRewardsCalculated;
            // } else {
            //     return 0;
            // }
        } else {
            LPStake memory userStake = userLpStakes[userAddress];
            require(
                userStake.lpAmount > 0,
                "No Stakes Found"
            );
           // uint256 elapsedTimeFromLastClaimed = blockTimeStamp - userStake.lastClaimedTimeStamp;
          //  if(elapsedTimeFromLastClaimed >= calculateRewardMinimumTime){
                for(uint256 i = userStake.cycleId; i <= terminationValue; i++){
                    if(stakingInfo[i].totalLpStaked == 0 ) { continue; }
                    uint256 totalRewardFromStakeInfo = stakingInfo[i].totalReward;
                    uint256 totalLpStakedFromStakeInfo = stakingInfo[i].totalLpStaked;
                    uint256 lpStakePercentage = ( userStake.lpAmount * 100 * _iether )/(totalLpStakedFromStakeInfo);
                    uint256 numerator = lpStakePercentage * totalRewardFromStakeInfo * _iether * lpRewardPercentage;
                    uint256 denominator = _iether * 10000 * _iether;  
                    uint256 totalRewardsPerCycle = numerator/denominator;
                    totalRewardsCalculated += totalRewardsPerCycle;
                }
            return totalRewardsCalculated;
            // }else{
            //     return 0;
            // }
        }
    }

    function getUserFees(uint256 amount) public view returns(uint256) {
        if(amount == 0 ) return 0;
        uint256 numerator  = (amount * feesPercentage * 1e18);
        uint256 denominator = ( 10000 * 1e18);
        uint256 feeAmount = numerator/denominator;
        return feeAmount;
    }

    function getMinimumWithdrawableAmount(bool isMblk)  public view returns(uint256){
        if(isMblk){
        //MBLKStake memory userStake = userMblkStakes[msg.sender];
        uint256 minimumWithdrawableAmount = (userMblkStakes[msg.sender].mblkAmount * 10)/ 100;
        return minimumWithdrawableAmount;
        }else{
       // LPStake memory userStake = userLpStakes[msg.sender];
        uint256 minimumWithdrawbleAmount = (userLpStakes[msg.sender].lpAmount * 10)/100;
        return minimumWithdrawbleAmount;
        }
        // if(userMblkStakes[msg.sender].mblkAmount > 0){
        //     return (userMblkStakes[msg.sender].mblkAmount * 10)/100;
        // }else if(userLpStakes[msg.sender].lpAmount > 0){
        //     return (userLpStakes[msg.sender].lpAmount / 10);
        // }else{
        //     return 0;
        // }
    }

    /**
     * @dev Claim MBLK rewards for a user.
     *
     * This function allows a user to claim their MBLK rewards based on their staking Parcentage. The rewards are calculated using the 'calculateReward' function.
     * A fee is deducted from the total rewards, and the remaining amount is transferred to the user. The fee amount is also transferred to a specified feesCollectionWallet.
     *
     * Requirements:
     * - The user must have an active MBLK stake.
     * - The calculated reward must be greater than 0.
     *
     * Emits a ClaimedRewardsMblk event to log the claimed rewards.
     * 
     * 
     * 
    */

    function claimRewardsMBLK(uint256 uptoCycleId) nonReentrant public{
        require(isPaused == false,"Contract is paused");
        uint256 cycleIdConsidered;
        MBLKStake memory userStake = userMblkStakes[msg.sender];
        require(
            uptoCycleId <= currentCycleId,
            "uptoCycleId is greated than currentCycleId"
        );
        require(
            userStake.mblkAmount > 0,
            "No single MBLK stake found"
        );
        if( uptoCycleId == 0){
            cycleIdConsidered = currentCycleId;
        }else {
            cycleIdConsidered = uptoCycleId;
        }
        uint256 blockTimeStamp = block.timestamp;

        if( userStake.endTime < blockTimeStamp){
            if( (userStake.endTime + unstakingPeriod) == blockTimeStamp){
                userStake.endTime = userStake.lastEndTime + minimumStakeDuration;
                userStake.lastEndTime = userStake.endTime;
            }
            if( (userStake.endTime + unstakingPeriod) > blockTimeStamp){
                userStake.lastEndTime = userStake.endTime;
                userStake.endTime = userStake.lastEndTime + minimumStakeDuration;
             }
            if((userStake.endTime + unstakingPeriod) < blockTimeStamp){
                uint256 diff = blockTimeStamp - userStake.endTime;
                uint256 res = (diff / minimumStakeDuration) + 1;
                uint256 daysPassed = minimumStakeDuration * res; 
                userStake.endTime = userStake.endTime + daysPassed; 
             
                uint256 value = userStake.endTime - minimumStakeDuration;
                if (blockTimeStamp >= (userStake.startTimestamp + value + unstakingPeriod)){
                    userStake.lastEndTime = userStake.endTime;
                }else{
                    userStake.lastEndTime = userStake.endTime - minimumStakeDuration;
                }
            }
        }
        uint256 rewards = calculateReward(msg.sender,uptoCycleId,true);
        require( rewards > 0, "No rewards to claim");
        require(
            mblkToken.balanceOf(address(this)) - (totalMblkStaked) >= rewards,
            "not enough balance in the contract"
        ); 
  
         mblkToken.safeTransfer(msg.sender, rewards); 
        userStake.lastClaimedTimeStamp = blockTimeStamp;
        userStake.claimedReward += rewards;
        userStake.cycleId = cycleIdConsidered + 1;
        totalClaimedRewards += rewards;
        userMblkStakes[msg.sender] = userStake;

        emit ClaimedRewardsMblk(msg.sender, rewards);
    }

 

    /**
     * @dev Claim LP token rewards for a user.
     *
     * This function allows a user to claim their LP token rewards based on their staking Parcentage. The rewards are calculated using the 'calculateReward' function.
     * A fee is deducted from the total rewards, and the remaining amount is transferred to the user. The fee amount is also transferred to a specified feesCollectionWallet.
     *
     * Requirements:
     * - The user must have an active LP token stake.
     * - The calculated reward must be greater than 0.
     * - the rewards must be less then or equal to balanceOf totalRewards
     *
     * Emits a ClaimedRewardsLp event to log the claimed rewards.
    */
    function claimRewardsLP(uint256 uptoCycleId) nonReentrant public{
        require(isPaused == false,"Contract is paused");
        uint256 cycleIdConsidered;
        LPStake memory userStake = userLpStakes[msg.sender];
        require(
            uptoCycleId <= currentCycleId,
            "uptoCycleId is greated than currentCycleId"
        );
        require(
            userStake.lpAmount > 0,
            "No LP Stake found"
        );
        if(uptoCycleId == 0){
            cycleIdConsidered = currentCycleId;
        }else {
            cycleIdConsidered = uptoCycleId;
        }
        uint256 blockTimeStamp = block.timestamp;
        if( userStake.endTime < blockTimeStamp){
            if( (userStake.endTime + unstakingPeriod) == blockTimeStamp){
                userStake.endTime = userStake.lastEndTime + minimumStakeDuration;
                userStake.lastEndTime = userStake.endTime;
            }
            if( (userStake.endTime + unstakingPeriod) > blockTimeStamp){
                userStake.lastEndTime = userStake.endTime;
                userStake.endTime = userStake.lastEndTime + minimumStakeDuration;
             }
            if((userStake.endTime + unstakingPeriod) < blockTimeStamp){
                uint256 diff = blockTimeStamp - userStake.endTime;
                uint256 res = (diff / minimumStakeDuration) + 1;
                uint256 daysPassed = minimumStakeDuration * res; 
                userStake.endTime = userStake.endTime + daysPassed; 
             
                uint256 value = userStake.endTime - minimumStakeDuration;
                if (blockTimeStamp >= (userStake.startTimestamp + value + unstakingPeriod)){
                    userStake.lastEndTime = userStake.endTime;
                }else{
                    userStake.lastEndTime = userStake.endTime - minimumStakeDuration;
                }
            }
        }
        uint256 rewards = calculateReward(msg.sender,cycleIdConsidered,false);
        require( rewards > 0 , "No rewards to claim");
        require(
            mblkToken.balanceOf(address(this)) - totalMblkStaked >= rewards,
            "not enough balance in the contract"
        );
         
         mblkToken.safeTransfer(msg.sender, rewards);
         userStake.claimedReward += rewards;
        userStake.cycleId = cycleIdConsidered + 1;
        userStake.lastClaimedTimeStamp = block.timestamp;
        totalClaimedRewards += rewards;
        userLpStakes[msg.sender] = userStake;

        emit ClaimedRewardsLp(msg.sender, rewards);
    }

    /**
     * @dev Withdraw a specified amount of MBLK tokens from the user's stake.
     * @param amountTowithdraw The amount of MBLK tokens to withdraw.
     *
     * Requirements:
     * - The user must have an active MBLK stake.
     * - The calculated rewards must be claimed first (calculatedRewards must be 0).
     * - The withdrawal can only occur after the minimum stake duration has passed.
     * - The contract must have a sufficient balance of MBLK tokens.
     *
     * Effects:
     * - Transfers the specified amount of MBLK tokens to the user.
     * - Burns an equivalent amount of SMBLK tokens from the user's balance.
     * - Updates the user's stake and total MBLK and SMBLK minted values.
     *
     * Emits a WithdrawnMblk event to log the MBLK withdrawal.
    */
    function withdrawMBLK(uint256 amountTowithdraw) nonReentrant external {
        MBLKStake memory userStake = userMblkStakes[msg.sender];
        uint256 blockTimeStamp = block.timestamp;
       require(blockTimeStamp >= userStake.lastEndTime && blockTimeStamp <= (userStake.lastEndTime + unstakingPeriod),"Can withdraw only in unstaking period");
        require(amountTowithdraw > 0,"Amount to withdraw should be greater than 0");
        if( isPaused == false){
                require(
                        userStake.lastEndTime < block.timestamp,
                        "Can not withdraw before Minimum Stake Duration"
                );
                uint256 calculatedRewards = calculateReward(msg.sender,0,true);   
                require(calculatedRewards == 0,"Please claim the rewards first");
        } 
        require(userStake.mblkAmount > 0,"No active stake found");
        require(
            userStake.mblkAmount >= amountTowithdraw,
            "Not enough MBLK Staked"
        );
        require(
            mblkToken.balanceOf(address(this)) >= amountTowithdraw,
            "Contract balance is not enough"
        );
        
        uint256 feeAmount = getUserFees(amountTowithdraw);
        require(feeAmount > 0, "Please add more Amount to withdraw");
        require(amountTowithdraw > ((userStake.mblkAmount * 9) / 100),"Cannot withdraw less than 10 %");
        uint256 amountToSend = amountTowithdraw - feeAmount;
        
        mblkToken.safeTransfer(msg.sender, amountToSend);
        mblkToken.safeTransfer(feesCollectionWallet,feeAmount);
       // mblkToken.safeTransfer(msg.sender, amountTowithdraw);  
        smblkToken.burnFrom(msg.sender, amountTowithdraw);
            userStake.mblkAmount -= amountTowithdraw;
            userStake.smblkMinted -= amountTowithdraw;
            totalSmblkMinted -= amountTowithdraw;
            totalMblkStaked -= amountTowithdraw;
            userMblkStakes[msg.sender] = userStake;
            emit WithdrawnMblk(msg.sender,amountTowithdraw); 
    }

    /**
     * @dev Withdraw a specified amount of LP (Liquidity Provider) tokens from the user's stake.
     * @param amountToWithdraw The amount of LP tokens to withdraw.
     *
     * Requirements:
     * - The user must have an active LP token stake.
     * - The calculated rewards must be claimed first (calculatedRewards must be 0).
     * - The withdrawal can only occur after the minimum stake duration has passed.
     * - The contract must have a sufficient balance of LP tokens and SMBLK tokens.
     *
     * Effects:
     * - Transfers the specified amount of LP tokens to the user.
     * - Burns an equivalent amount of SMBLK tokens from the user's balance.
     * - Updates the user's stake, total LP staked, and total SLP minted values.
     *
     * Emits a WithdrawnLp event to log the LP token withdrawal.
    */
    function withdrawLP(uint256 amountToWithdraw) nonReentrant external {
        LPStake memory userStake = userLpStakes[msg.sender];
        uint256 blockTimeStamp = block.timestamp;
          require(blockTimeStamp >= userStake.lastEndTime && blockTimeStamp <= (userStake.lastEndTime + unstakingPeriod),"Can withdraw only in unstaking period");
        require(amountToWithdraw > 0,"Amount to withdraw should be greater than 0");
        if( isPaused == false){
                require(
                        userStake.lastEndTime < block.timestamp,
                        "Can not withdraw before Minimum Stake Duration"
                );
                uint256 calculatedRewards = calculateReward(msg.sender,0,false);   
                require(calculatedRewards == 0,"Please claim the rewards first");
        } 
        require(userStake.lpAmount > 0,"No active stake found");
        require(userStake.lpAmount >= amountToWithdraw,"Not enough LP Staked");
        require(
            userStake.lpAmount >= amountToWithdraw, 
            "Contract balance is not enough"
        );
        require(
            slpToken.balanceOf(msg.sender) >= amountToWithdraw,
            "user smblk Balance is not enough"
        );
        require(
            lpToken.balanceOf(address(this)) >= amountToWithdraw,
            "Contract Balance is not enough"
        );

        slpToken.burnFrom(msg.sender,amountToWithdraw);

        uint256 feeAmount = getUserFees(amountToWithdraw);
        require(feeAmount > 0, "Please add more Amount to withdraw");
        require(amountToWithdraw > ((userStake.lpAmount * 9) / 100),"Cannot withdraw less than 10 %");
        uint256 amountToSend = amountToWithdraw - feeAmount;
        
        lpToken.safeTransfer(msg.sender, amountToSend);
        lpToken.safeTransfer(feesCollectionWallet,feeAmount);
        userStake.lpAmount -= amountToWithdraw;
        totalLpStaked -= amountToWithdraw;
        totalSlpMinted -= amountToWithdraw;
        userStake.slpMinted -= amountToWithdraw;
        userLpStakes[msg.sender] = userStake;
        emit WithdrawnLp(msg.sender, amountToWithdraw);
    }
 
    /**
     * @dev Update the current staking cycle information.
     *
     * This function increments the currentCycleId, records the block timestamp, and updates the staking information for the new cycle, including total rewards, LP tokens staked, and MBLK tokens staked.
     *
     * Requirements:
     * - Only the admin can call this function.
     *
     * Emits an UpdatedCycleId event with the new cycle's identifier.
    */  
    function updateCycleId() public onlyAdmin{
       // require(isRewardSent == true,"Rewards are not set");
        currentCycleId++;
        uint256 blockTimeStamp = block.timestamp;
        StakingInfo memory currentStakeInfo = stakingInfo[currentCycleId];
        currentStakeInfo.cycleId =  currentCycleId;
        currentStakeInfo.blockTimeStamp = blockTimeStamp;
        currentStakeInfo.totalReward = totalRewards;
        currentStakeInfo.totalLpStaked = totalLpStaked;
        currentStakeInfo.totalMblkStaked = totalMblkStaked;
        stakingInfo[currentCycleId] = currentStakeInfo;
       // isRewardSent = false;

        emit UpdatedCycleId(currentCycleId);
    }
 
    /**
     * @dev Set a fixed reward value for staking.
     * @param newFixedReward The fixed reward value to be set.
     *
     * Requirements:
     * - Only the admin can call this function.
     * - The time since the last fixed reward update must be greater than or equal to 'timeForFixedReward'.
     *
     * Effects:
     * - Updates the 'fixedReward' value.
     * - Calls 'setTotalRewards' to set total rewards based on the fixed reward.
     *
     * Emits a FixedRewardSet event to log the update of the fixed reward value.
    */
    function setFixedReward(address vestingAddress, uint256 newFixedReward) external onlyAdmin{
        uint256 blocktimeStamp = block.timestamp;
        uint256 timeSpent = blocktimeStamp - lastFixedRewardSet; 
        require(timeSpent >= timeForFixedReward, "Can not set before Minimum Time");
        mblkToken.safeTransferFrom(vestingAddress,address(this),newFixedReward);
        lastFixedRewardSet = blocktimeStamp;
        fixedReward = newFixedReward;
        setTotalRewards();

        emit FixedRewardSet(newFixedReward);
    }


    /**
     * @dev Set the dynamic reward value, but only if enough time has passed since the last update.
     * @param newDynamicReward The new dynamic reward value to set.
     *
     * Requirements:
     * - The function can only be called by the admin.
     * - The time elapsed since the last dynamic reward update must be greater than or equal to `   timeForDynamicReward`.
     * - If the time requirement is met, the dynamic reward value is updated, and `setTotalRewards` is called.
     *
     * Emits a DynamicRewardSet event with the new dynamic reward value.
    */
    function setDynamicReward(address vestingAddress, uint256 newDynamicReward) external onlyAdmin{
        uint256 blocktimeStamp = block.timestamp;
        uint256 timeSpent = blocktimeStamp - lastDynamicRewardSet;
        require(timeSpent >= timeForDynamicReward,"Can not set Before minimum time");
        mblkToken.safeTransferFrom(vestingAddress,address(this),newDynamicReward);
        lastDynamicRewardSet = blocktimeStamp;
        dynamicReward = newDynamicReward; 
        setTotalRewards();
        emit DynamicRewardSet(newDynamicReward);
    }

    /**
     * @dev Set the total rewards for staking.
     *
     * Effects:
     * - Calculates the 'totalRewards' by adding the 'fixedReward' and 'dynamicReward'.
     * - Records the timestamp when the total rewards were last set.
     *
     * Emits a TotalRewardSet event to log the update of the total rewards.
    */
    function setTotalRewards() internal {
        totalRewards = fixedReward + dynamicReward;
        lastTotalRewardSetTimestamp = block.timestamp;
        emit TotalRewardSet(totalRewards);
    }
 
    function setRewards(uint256 newFixedReward, uint256 newDynamicReward) public onlyAdmin{
        require(newFixedReward > 0 , "newFixedReward cannot be 0");
        require(newDynamicReward > 0 , "newDynamicReward cannot be 0");
        fixedReward = newFixedReward;
        dynamicReward = newDynamicReward;
        totalRewards = fixedReward + dynamicReward;
        emit TotalRewardSet(totalRewards);
    }
 

    function setRewardTime(uint256 timeForRewards) public onlyOwner{
        timeForDynamicReward = timeForRewards;
        timeForFixedReward = timeForRewards;
    }
    /**
     * @dev Set the fees percentage for reward distribution.
     * @param percentage The fees percentage to be set (0-10000, where 10000 represents 100%).
     *
     * Requirements:
     * - Only the admin can call this function.
     * - The provided percentage must be within the valid range (0-10000).
     *
     * Effects:
     * - Updates the 'feesPercentage' for fee calculations.
     *
     * Emits a FeesPercentageSet event to log the update of the fees percentage.
    */
    function setFeesPercentage(uint256 percentage) external onlyOwner{
        require(percentage > 0 && percentage <= 1500, "Percentage out of range (0-1500)");
        feesPercentage = percentage;
        emit FeesPercentageSet(percentage);
    } 

    /**
     * @dev Add a new address as an admin.
     * @param newAdmin The address to be added as a new admin.
     *
     * Requirements:
     * - Only the contract owner can call this function.
     *
     * Effects:
     * - Grants administrative privileges to the specified address by setting 'isAdmin[newAdmin]' to true.
     *
     * Emits an AdminAdded event to log the addition of a new admin.
    */
    function addAdmin(address newAdmin) public onlyOwner {
        isAdmin[newAdmin] = true;
        emit AdminAdded(newAdmin);
    }

    /**
     * @dev Remove an address from the list of admins.
     * @param adminAddress The address to be removed from the list of admins.
     *
     * Requirements:
     * - Only the contract owner can call this function.
     *
     * Effects:
     * - Revokes administrative privileges from the specified address by setting 'isAdmin[adminAddress]' to false.
     *
     * Emits an AdminRemoved event to log the removal of an admin.
     */
    function removeAdmin(address adminAddress) public onlyOwner{
        isAdmin[adminAddress] = false; 
        emit AdminRemoved(adminAddress);
    }

    /**
     * @dev Set the minimum stake duration in minutes.
     * @param durationInMinutes The minimum stake duration in minutes to be set.
     *
     * Requirements:
     * - The provided duration must be greater than 0.
     *
     * Effects:
     * - Converts the input duration in minutes to seconds and updates the 'minimumStakeDuration' variable.
     *
     * Emits a MinimumStakeDurationSet event to log the update of the minimum stake duration.
    */
    function setMinimumStakeDuration(uint256 durationInMinutes) external onlyOwner{
        require(durationInMinutes > 0, "Given Value is 0"); 
        minimumStakeDuration = durationInMinutes * 60;
        emit MinimumStakeDurationSet(durationInMinutes);
    }

    /**
     * @dev Set the address where collected fees will be sent.
     * @param walletAddress The address where collected fees will be transferred to.
     *
     * Requirements:
     * - Only the contract owner can call this function.
     *
     * Effects:
     * - Updates the 'feesCollectionWallet' with the provided wallet address.
    */
    function setFeeWalletAddress(address walletAddress) public onlyOwner{
        feesCollectionWallet = walletAddress;
        emit FeesWalletSet(walletAddress);
    }

    /**
     * @dev Set the minimum time duration for calculating rewards.
     * @param durationInMinutes The minimum time duration in minutes for calculating rewards.
     *
     * Requirements:
     * - Only the contract owner can call this function.
     *
     * Effects:
     * - Converts the input duration in minutes to seconds and updates 'calculateRewardMinimumTime'.
    */
    function setMinimumCalculateRewardTime(uint256 durationInMinutes) public onlyOwner{  
        require(durationInMinutes > 0, "calculate reward minimum time can not be 0");    
        calculateRewardMinimumTime = durationInMinutes * 60;
        emit MinimumCalculateRewardTimeSet(calculateRewardMinimumTime);
    }


    function setUnStakingPeriod(uint256 durationInMinutes) public onlyOwner{
        require(durationInMinutes > 0,"cannot be 0");
        unstakingPeriod = durationInMinutes * 60;       
    }

    /**
     * @dev Withdraw MBLK from the contract by the owner.
     *
     * Requirements:
     * - Only the contract owner can call this function.
     *
     * Effects:
     * - Transfers the amount of Rewards Deposited of MBLK by owner from the contract to the owner's address.
     *
     * Emits a WithDrawnAll event to log the withdrawal of MBLK 
    */ 
    function withdrawOnlyOwner() public onlyOwner{
        uint256 ownersDepositedFundsAsRewards = mblkToken.balanceOf(address(this)) - totalMblkStaked;
        mblkToken.safeTransfer(msg.sender, ownersDepositedFundsAsRewards);
        emit WithDrawnAll(msg.sender,ownersDepositedFundsAsRewards );
    }

    function pauseStaking() public onlyOwner{
        require( isPaused == false, "Already Paused");
        isPaused = true;
        emit PausedStaking();
    }

    function unPauseStaking() public onlyOwner {
        require( isPaused == true,"Already Unpaused");
        isPaused = false;
        emit UnpausedStaking();
    }
    /**
     * @dev Get the total amount of SMBLK (Staked MBLK) minted.
     * @return The total number of SMBLK tokens that have been minted as rewards.
    */
    function totalSMBLK()public view returns(uint256){
        return totalSmblkMinted;
    }
 
    /**
     * @dev Get the total amount of SLP (Staked LP) tokens minted.
     * @return The total number of SLP tokens that have been minted as rewards.
    */
    function totalSLP()public view returns(uint256){
        return totalSlpMinted;
    }

    /**
     * @dev Get information about a user's MBLK stake.
     * @param userAddress The address of the user.
     * @return (
     *   1. The amount of MBLK staked by the user,
     *   2. The start timestamp of the stake,
     *   3. The end timestamp of the stake,
     *   4. The claimed reward amount,
     *   5. The last claimed timestamp,
     *   6. The amount of Staked MBLK minted,
     * )
    */
    function userMBLKStakeInformation( 
        address userAddress
    ) 
        public 
        view 
        returns(
            uint256,
            uint256,
            uint256,
            uint256, 
            uint256,
            uint256
        )
    {
        MBLKStake memory userStake = userMblkStakes[userAddress];
        return(
            userStake.mblkAmount,
            userStake.startTimestamp,
            userStake.endTime,
            userStake.claimedReward, 
            userStake.lastClaimedTimeStamp,
            userStake.smblkMinted
        );
    }

    /**
     * @dev Get information about a user's LP stake.
     * @param userAddress The address of the user.
     * @return (
     *   1. The amount of LP tokens staked by the user,
     *   2. The start timestamp of the stake,
     *   3. The end timestamp of the stake,
     *   4. The claimed reward amount,
     *   5. The last claimed timestamp,
     *   6. The amount of Staked LP tokens minted,
     * )
    */
    function userLPStakesInformation( 
        address userAddress
    ) 
        public 
        view 
        returns(
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
         
        )
    {
        LPStake memory userStake = userLpStakes[userAddress]; 
        return(
            userStake.lpAmount,
            userStake.startTimestamp,
            userStake.endTime,
            userStake.claimedReward, 
            userStake.lastClaimedTimeStamp, 
            userStake.slpMinted
           
        ); 
    }

    /**
     * @dev Get the total amount of rewards available for distribution.
     * @return The total number of rewards 
     */

    function getTotalRewards()public view returns(uint256) {
        return totalRewards;
    } 

    function getTotalClaimedRewards() public view returns (uint256 ){
        return totalClaimedRewards;
    }
 
    /**
     * @dev Get staking information for a specific cycle.
     * @param _cycleId The identifier of the staking cycle to retrieve information for.
     * @return (
     *   1. The cycle ID,
     *   2. The block timestamp when the cycle was updated,
     *   3. The total amount of MBLK tokens staked in the cycle,
     *   4. The total reward associated with the cycle,
     *   5. The total amount of LP tokens staked in the cycle.
     * )
     *
     * Requirements:
     * - The provided _cycleId must be within a valid range (not exceeding currentCycleId).
     */
    function getStakingInfo(
        uint256 _cycleId
    ) 
        public 
        view 
        returns(
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    { 
        require(_cycleId <= currentCycleId, "Cycle Id is out of Range");
        return(
            stakingInfo[_cycleId].cycleId,
            stakingInfo[_cycleId].blockTimeStamp,
            stakingInfo[_cycleId].totalMblkStaked,
            stakingInfo[_cycleId].totalReward, 
            stakingInfo[_cycleId].totalLpStaked
        ); 
    } 
   
}