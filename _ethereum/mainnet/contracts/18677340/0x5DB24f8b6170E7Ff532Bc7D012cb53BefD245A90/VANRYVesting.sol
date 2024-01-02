// Sources flattened with hardhat v2.19.0 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/access/IAccessControl.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/Context.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/introspection/ERC165.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/math/Math.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/math/SignedMath.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/Strings.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/access/AccessControl.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File contracts/VANRYVestingContract.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * 
 * Only minimum required functions are mentioned to reduce the size.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

/**
* @title VANRY Vesting Contract
* @author Naeem Ahmed
* @notice This contract allows to deploy an admin access controlled vesting contract for an ERC20 token on any EVM compatible chain.
* 
* The contract has following features:
* - The contract supports initial token release, cliff and then even token distribution over the vesting period.
* - The contract assumes that the enough supply will be provided after the contract deployment so that the 
*   beneficiary faces no issues with the release of vested tokens. There are no rules encoded in the contract to
*   ensure there are enough funds deposited before the contract gets into an active state.
* - The admin of the contract has the right to pause and activate the contract in case it is required.
* - The admin can also withdraw the deposited tokens when needed.
*
* @dev The token address for vesting is defined as a constant to make it gas friendly.
*      You need to replace the ERC20 contract address with the one required. Refer to the contant defined as VESTED_TOKEN in the code.
*/
contract VANRYVesting is AccessControl {

    enum State {
        //Initialized, // contract is initialized and pending funds before it can be activated
        ACTIVE, // users can claim their vested tokens
        PAUSED, // contract is paused for all functionalities except admin only operations
        COMPLETED // when all the tokens are claimed
        //Frozen // contact is locked for all
    }

    IERC20 public constant VESTED_TOKEN = IERC20(0x8DE5B80a0C1B02Fe4976851D030B36122dbb8624);// Replace the token address with correct one per network
    bytes32 public constant ROLE_ADMIN = bytes32("ROLE_ADMIN");
    bytes32 public constant ROLE_FUNDS_MANAGER = bytes32("ROLE_FUNDS_MANAGER");

    State public contractState;

    address public immutable beneficiary; // beneficiary address
    uint256 public immutable totalAmount; // the amount of tokens without 18 decimals. Conversion to ether value is being done in the contract
    uint256 public immutable startTime; // start time of the vesting period
    uint256 public immutable vestingStartTime; // additional time on top of start time when user can start claiming their tokens
    uint256 public immutable duration; // total duration of vesting
    uint256 public immutable initialUnlockPercentage; // percentage of tokens to release at the begining
    uint256 public immutable tokensPerSecond; // amount of tokens to be released per unit/sec of time excluding initial unlock
    
    uint256 public immutable initialUnlockTokenAmount; // tokens to be unlocked initially
    uint256 public immutable vestingEndTime; // end time of the vesting period

    uint256 public totalAmountClaimed; // amount of tokens that have been claimed by the beneficiary
    uint256 public vestingClaimedUntil; // timestamp of the last claim
    uint256 public blockClaimFrom; // the timestamp after which tokens will be locked and won't be availale to claim

    bool public isInitialUnlockedTokensClaimed;

    //Events

    /**
     * @dev emitted when a user claims some vested tokens
     * 
     * @param beneficiary address of the beneficiary to receive the vested tokens
     * @param amount the amount of tokens claimed
     */
    event TokensClaimed(address indexed beneficiary, uint256 amount);
    /**
     * @dev emitted when a user claims all the vested tokens
     * 
     * @param beneficiary address of the beneficiary to receive the vested tokens
     * @param totalAmountClaimed the total amount of tokens claimed
     */
    event VestingCompleted(address indexed beneficiary, uint256 totalAmountClaimed);
    /**
     * @dev emitted when the funds manager withdraws some deposited tokens
     * 
     * @param beneficiary address of the beneficiary to receive the withdrawal amount
     * @param amount the amount of tokens withdrawn
     */
    event TokensWithdrawnByFundsManager(address indexed beneficiary, uint256 amount);
    /**
     * @dev emitted when the state of the contract is changed by admin or the contract itself
     * 
     * @param oldState the old state of the contract
     * @param newState the old state of the contract
     * @param context the context of state change
     */
    event ContractStateChanged(State oldState, State newState, string context);

    /**
     * @param admin address with the admin role
     * @param blockClaimFrom the time from which claim of vesting tokens is disabled
     * @param vestingEndTime the end time of the vesting duration
     * @param lockDuration the duration of the locked period
     */
    event BlockedVestingDuration(address indexed admin, uint256 blockClaimFrom, uint256 vestingEndTime, uint256 lockDuration);
    /**
     * 
     * @param timestamp the time when blockage is removed
     */
    event UnlockedVestingDuration(uint256 timestamp);

    /**
     * @dev sets the values for state variables based on the arguments
     * 
     * @param _admin address of the admin to manage the vesting contract 
     * @param _fundsManager address of the account to manage the funds in the vesting contract 
     * @param _beneficiary  address of the beneficiary to receive the vested tokens
     * @param _totalAmount total amount of tokens vested for the beneficiary
     * @param _start the start time of the vesting period
     * @param _cliffDuration cliff duration after which the beneficiary can start claiming their vested tokens
     * @param _vestingDuration total duration for the vesting
     * @param _initialUnlockPercentage the percentage of tokens to be released at the begining. All the remaining tokens are released over vesting duration
     */
    constructor(
        address _admin,
        address _fundsManager,
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _start,
        uint256 _cliffDuration,
        uint256 _vestingDuration,
        uint256 _initialUnlockPercentage
    ) {
        require(_admin != address(0), "Invalid address");
        require(_fundsManager != address(0), "Invalid address");
        require(_beneficiary != address(0), "Invalid address");
        require(_vestingDuration > 0 && _cliffDuration < _vestingDuration, "Invalid duration");
        require(_totalAmount > 0, "Invalid total amount");
        require(_start >= block.timestamp, "Start time must be in the future");
        require(_initialUnlockPercentage <= 100, "Invalid value for initial unlock percentage");

        uint256 totalAmountInEther = _totalAmount * 1 ether;

        contractState = State.ACTIVE;

        beneficiary = _beneficiary;
        startTime = _start;
        vestingStartTime = _start + _cliffDuration;
        duration = _vestingDuration;
        vestingEndTime = _start + _cliffDuration + _vestingDuration;
        totalAmount = totalAmountInEther;
        initialUnlockPercentage = _initialUnlockPercentage;

        initialUnlockTokenAmount = (_initialUnlockPercentage * totalAmountInEther) / 100;
        tokensPerSecond = (totalAmountInEther - initialUnlockTokenAmount) / _vestingDuration;

        vestingClaimedUntil = _start + _cliffDuration;

        if(msg.sender != tx.origin){
            _setupRole(DEFAULT_ADMIN_ROLE, tx.origin);
            _setupRole(ROLE_ADMIN, tx.origin);
        }else{
            _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
            _setupRole(ROLE_ADMIN, msg.sender);
        }

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(ROLE_ADMIN, _admin);

        _setupRole(ROLE_FUNDS_MANAGER, _fundsManager);
    }

    /**
     * @dev ensures that the contract state is active
     */
    modifier activeContractOnly() {
        require(contractState == State.ACTIVE, "Contract is not in active state");
        _;
    }
    /**
     * @dev ensures that the caller has the admin role
     */
    modifier onlyAdmin() {
        require(hasRole(ROLE_ADMIN, msg.sender), "Caller is not an admin");
        _;
    }
    /**
     * @dev ensures that the caller has the funds manager role
     */
    modifier onlyFundsManager() {
        require(hasRole(ROLE_FUNDS_MANAGER, msg.sender), "Caller is not a valid funds manager");
        _;
    }
    /**
     * @dev ensures that the validity of the vesting period
     */
    modifier inVestingPeriod(){
        require(startTime <= block.timestamp, "Vesting has not started yet");
        require((initialUnlockTokenAmount > 0 && !isInitialUnlockedTokensClaimed) || (block.timestamp >= vestingStartTime), "Vesting has not started yet");
        _;
    }

    /**
     * @notice  it returns the amount of tokens which are available to claim/release.
     *          This also includes the amount of the tokens which are supposed to be unlocked in the begining if any.
     * 
     * 
     * @return returns the amount of tokens available to claim
     */
    function vestedAmountAvailableForClaim() public view returns (uint256, uint256) {
        uint256 vestedTokens;
        uint256 claimSliceEndBound;

        if(block.timestamp >= startTime){ // when contract start time is reached
            if (block.timestamp < vestingStartTime) { // when vesting time not reached yet
                vestedTokens = (initialUnlockTokenAmount - totalAmountClaimed);
            } else { // when in vesting duration
                if (block.timestamp > vestingEndTime) {// when time is past vesting end time
                    claimSliceEndBound = (blockClaimFrom > 0) ? blockClaimFrom : vestingEndTime;
                }else  {
                    claimSliceEndBound = (blockClaimFrom > 0 && block.timestamp > blockClaimFrom) ? blockClaimFrom : block.timestamp;
                }

                vestedTokens = ((claimSliceEndBound - vestingClaimedUntil) * tokensPerSecond);

                if(initialUnlockPercentage > 0 && !isInitialUnlockedTokensClaimed){
                    vestedTokens += initialUnlockTokenAmount;
                }

                // Delta check: where total amount of available tokens are slightly less than the total amount due to mathematical limitation
                // This will work fine when there is no vesting period blocked for claim and that serves the purpose
                // e.g. 99,999.9999999999999998 released instead of 10,0000. Duration 600, initial unlock 20%, 80% released in 600 sec with 133.333333333333333333 tokens/sec
                if((vestedTokens + totalAmountClaimed + 1 gwei) > totalAmount){
                    vestedTokens = totalAmount - totalAmountClaimed;
                }
            }
        }

        return (vestedTokens, claimSliceEndBound);
    }

    /**
     * @notice this function allows the beneficiary to claim the vested tokens (if any)
     * 
     * Requirements:
     * 
     * - The caller must be the beneficiary
     * - The contract should be in active state
     * - There should be some tokens available to be claimed
     * 
     * 
     * @return returns the amount of tokens claimed
     */
    function releaseTokens() external activeContractOnly inVestingPeriod returns(uint256) {
        require(msg.sender == beneficiary, "Caller must be the beneficiary");
        require(totalAmountClaimed < totalAmount, "All the tokens have been claimed");

        (uint256 amount, uint256 _vestingClaimedUntil) = vestedAmountAvailableForClaim();
        require(amount > 0, "No vested amount available to release");

        require(getBalance() >= amount, "Insufficient funds in the contract");

        //update initial claim on first claim
        if(initialUnlockPercentage > 0 && !isInitialUnlockedTokensClaimed){
            isInitialUnlockedTokensClaimed = true;
        }

        totalAmountClaimed += amount;

        //update vestingClaimedUntil only when claiming during vesting and excluding initial unlock. This is verified in the function vestedAmountAvailableForClaim()
        if(_vestingClaimedUntil > 0){
            vestingClaimedUntil = _vestingClaimedUntil;
        }

        // Transfer vested amount to beneficiary
        VESTED_TOKEN.transfer(beneficiary, amount);

        emit TokensClaimed(beneficiary, amount);

        if(totalAmount == totalAmountClaimed){
            emit ContractStateChanged(contractState, State.COMPLETED, "All tokens claimed by the beneficiary");
            contractState = State.COMPLETED;
            emit VestingCompleted(beneficiary, totalAmountClaimed);
        }

        return amount;
    }

    /**
    * @dev Allows the admin to withdraw funds from the contract.
    * @param _beneficiary The address of the beneficiary to receive the withdrawn funds.
    * @param _amount The amount of tokens to withdraw.
    */
    function withdrawTokens(address _beneficiary, uint256 _amount) external onlyFundsManager {
        require(_amount > 0, "Invalid amount");
        require(getBalance() >= _amount, "Insufficient funds in the contract");

        VESTED_TOKEN.transfer(_beneficiary, _amount);

        emit TokensWithdrawnByFundsManager(_beneficiary, _amount);
    }

    /**
    * @notice allows the admin to block a vesting duration in future
    * 
    * @param _blockClaimFrom the time after which vested tokens will be locked and won't be available to claim
    */
    function blockVestingDurationForClaim(uint256 _blockClaimFrom) external onlyAdmin {
        require(_blockClaimFrom >= block.timestamp, "Locking time can't be in past for locking the claim of vested tokens"); // The locking of the claim of vested tokens can be done for a future date/time only
        require(_blockClaimFrom < vestingEndTime, "Locking time can't be greater than the end time of the vesting duration");

        blockClaimFrom = _blockClaimFrom;

        emit BlockedVestingDuration(msg.sender, _blockClaimFrom, vestingEndTime, vestingEndTime - blockClaimFrom);
    }

    /**
    * @notice allows the admin to block the claiming of the tokens to be vested in the future time
    */
    function unblockVestingDurationForClaim() external onlyAdmin {
        require(contractState != State.COMPLETED, "Contract state must not be COMPLETED to unblock the claim");
        require(blockClaimFrom > 0, "The claim is not disabled for any duration");

        blockClaimFrom = 0;

        emit UnlockedVestingDuration(block.timestamp);
    }

    /**
     * @notice allows the admin to change the contract state
     * 
     * @param _state the new state to change the contract to
     * @param context the reason of chaing the state
     */
    function changeContractState(State _state, string memory context) external onlyAdmin {
        require(contractState != _state, "Contract already in this state");
        require(contractState != State.COMPLETED, "The state can't be changed once vesting is completed");
        require(_state != State.COMPLETED, "Admin can't set this state");

        emit ContractStateChanged(contractState, _state, context);

        contractState = _state;
    }

    /**
     * @notice Returns the amount of tokens owned by the contract.
     */
    function getBalance() public view returns (uint256) {
        return VESTED_TOKEN.balanceOf(address(this));
    }
}