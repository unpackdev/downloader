// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// For compatibility, we're keeping the same function names as in the original Curve code, including the mixed-case
// naming convention.
// solhint-disable func-name-mixedcase

interface IVotingEscrow {
    struct Point {
        int128 bias;
        int128 slope; // - dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    function MAXTIME() external view returns (uint256);

    function MINTIME() external view returns (uint256);

    function token() external view returns (address);

    function supply() external view returns (uint256);

    function unlocked() external view returns (bool);

    function locked(address) external view returns (int128, uint256);

    function epoch() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function balanceOfAt(address user, uint256 _block) external view returns (uint256);

    function balanceOfAtT(address user, uint256 timestamp) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAt(uint256 _block) external view returns (uint256);

    function totalSupplyAtT(uint256 timestamp) external view returns (uint256);

    function user_point_epoch(address user) external view returns (uint256);

    function slope_changes(uint256 i) external view returns (int128);

    function point_history(uint256 timestamp) external view returns (int128, int128, uint256, uint256);

    function user_point_history(
        address user,
        uint256 timestamp
    )
        external
        view
        returns (int128, int128, uint256, uint256);

    function unlock() external;

    function checkpoint() external;

    function locked__end(address user) external view returns (uint256);

    function deposit_for(address _addr, uint256 _value) external;

    function create_lock(uint256 _value, uint256 _unlock_time) external;

    function create_lock_for(address _addr, uint256 _value, uint256 _unlock_time) external;

    function increase_amount(uint256 _value) external;

    function withdraw() external;

    function add_to_whitelist(address _addr) external;

    function remove_from_whitelist(address _addr) external;
}

/**
 * @title Fee Distributor
 * @notice Distributes any tokens transferred to the contract (e.g. Protocol fees) among veRAFT
 * holders proportionally based on a snapshot of the week at which the tokens are sent to the FeeDistributor contract.
 * @dev Supports distributing arbitrarily many different tokens. In order to start distributing a new token to veRAFT
 * holders simply transfer the tokens to the `FeeDistributor` contract and then call `checkpointToken`.
 */
interface IFeeDistributor {
    event TokenCheckpointed(IERC20 token, uint256 amount, uint256 lastCheckpointTimestamp);
    event TokensClaimed(address user, IERC20 token, uint256 amount, uint256 userTokenTimeCursor);
    event TokenWithdrawn(IERC20 token, uint256 amount, address recipient);
    event TokenClaimingEnabled(IERC20 token, bool enabled);
    event OnlyVeHolderClaimingEnabled(address user, bool enabled);

    /**
     * @notice Returns the VotingEscrow (veRAFT) token contract
     */
    function getVotingEscrow() external view returns (IVotingEscrow);

    /**
     * @notice Returns the time when fee distribution starts.
     */
    function getStartTime() external view returns (uint256);

    /**
     * @notice Returns the global time cursor representing the most earliest uncheckpointed week.
     */
    function getTimeCursor() external view returns (uint256);

    /**
     * @notice Returns the user-level time cursor representing the most earliest uncheckpointed week.
     * @param user - The address of the user to query.
     */
    function getUserTimeCursor(address user) external view returns (uint256);

    /**
     * @notice Returns the user-level start time representing the first week they're eligible to claim tokens.
     * @param user - The address of the user to query.
     */
    function getUserStartTime(address user) external view returns (uint256);

    /**
     * @notice True if the given token can be claimed, false otherwise.
     * @param token - The ERC20 token address to query.
     */
    function canTokenBeClaimed(IERC20 token) external view returns (bool);

    /**
     * @notice Returns the token-level start time representing the timestamp users could start claiming this token
     * @param token - The ERC20 token address to query.
     */
    function getTokenStartTime(IERC20 token) external view returns (uint256);

    /**
     * @notice Returns the token-level time cursor storing the timestamp at up to which tokens have been distributed.
     * @param token - The ERC20 token address to query.
     */
    function getTokenTimeCursor(IERC20 token) external view returns (uint256);

    /**
     * @notice Returns the token-level cached balance.
     * @param token - The ERC20 token address to query.
     */
    function getTokenCachedBalance(IERC20 token) external view returns (uint256);

    /**
     * @notice Returns the user-level last checkpointed epoch.
     * @param user - The address of the user to query.
     */
    function getUserLastEpochCheckpointed(address user) external view returns (uint256);

    /**
     * @notice Returns the user-level time cursor storing the timestamp of the latest token distribution claimed.
     * @param user - The address of the user to query.
     * @param token - The ERC20 token address to query.
     */
    function getUserTokenTimeCursor(address user, IERC20 token) external view returns (uint256);

    /**
     * @notice Returns the user's cached balance of veRAFT as of the provided timestamp.
     * @dev Only timestamps which fall on Thursdays 00:00:00 UTC will return correct values.
     * This function requires `user` to have been checkpointed past `timestamp` so that their balance is cached.
     * @param user - The address of the user of which to read the cached balance of.
     * @param timestamp - The timestamp at which to read the `user`'s cached balance at.
     */
    function getUserBalanceAtTimestamp(address user, uint256 timestamp) external view returns (uint256);

    /**
     * @notice Returns the cached total supply of veRAFT as of the provided timestamp.
     * @dev Only timestamps which fall on Thursdays 00:00:00 UTC will return correct values.
     * This function requires the contract to have been checkpointed past `timestamp` so that the supply is cached.
     * @param timestamp - The timestamp at which to read the cached total supply at.
     */
    function getTotalSupplyAtTimestamp(uint256 timestamp) external view returns (uint256);

    /**
     * @notice Returns the FeeDistributor's cached balance of `token`.
     */
    function getTokenLastBalance(IERC20 token) external view returns (uint256);

    /**
     * @notice Returns the amount of `token` which the FeeDistributor received in the week beginning at `timestamp`.
     * @param token - The ERC20 token address to query.
     * @param timestamp - The timestamp corresponding to the beginning of the week of interest.
     */
    function getTokensDistributedInWeek(IERC20 token, uint256 timestamp) external view returns (uint256);

    // Preventing third-party claiming

    /**
     * @notice Enables / disables rewards claiming only by the VotingEscrow holder for the message sender.
     * @param enabled - True if only the VotingEscrow holder can claim their rewards, false otherwise.
     */
    function enableOnlyVeHolderClaiming(bool enabled) external;

    /**
     * @notice Returns true if only the VotingEscrow holder can claim their rewards, false otherwise.
     */
    function onlyVeHolderClaimingEnabled(address user) external view returns (bool);

    // Depositing

    /**
     * @notice Deposits tokens to be distributed in the current week.
     * @dev Sending tokens directly to the FeeDistributor instead of using `depositTokens` may result in tokens being
     * retroactively distributed to past weeks, or for the distribution to carry over to future weeks.
     *
     * If for some reason `depositTokens` cannot be called, in order to ensure that all tokens are correctly
     * distributed
     * manually call `checkpointToken` before and after the token transfer.
     * @param token - The ERC20 token address to distribute.
     * @param amount - The amount of tokens to deposit.
     */
    function depositToken(IERC20 token, uint256 amount) external;

    /**
     * @notice Deposits tokens to be distributed in the current week.
     * @dev A version of `depositToken` which supports depositing multiple `tokens` at once.
     * See `depositToken` for more details.
     * @param tokens - An array of ERC20 token addresses to distribute.
     * @param amounts - An array of token amounts to deposit.
     */
    function depositTokens(IERC20[] calldata tokens, uint256[] calldata amounts) external;

    // Checkpointing

    /**
     * @notice Caches the total supply of veRAFT at the beginning of each week.
     * This function will be called automatically before claiming tokens to ensure the contract is properly updated.
     */
    function checkpoint() external;

    /**
     * @notice Caches the user's balance of veRAFT at the beginning of each week.
     * This function will be called automatically before claiming tokens to ensure the contract is properly updated.
     * @param user - The address of the user to be checkpointed.
     */
    function checkpointUser(address user) external;

    /**
     * @notice Assigns any newly-received tokens held by the FeeDistributor to weekly distributions.
     * @dev Any `token` balance held by the FeeDistributor above that which is returned by `getTokenLastBalance`
     * will be distributed evenly across the time period since `token` was last checkpointed.
     *
     * This function will be called automatically before claiming tokens to ensure the contract is properly updated.
     * @param token - The ERC20 token address to be checkpointed.
     */
    function checkpointToken(IERC20 token) external;

    /**
     * @notice Assigns any newly-received tokens held by the FeeDistributor to weekly distributions.
     * @dev A version of `checkpointToken` which supports checkpointing multiple tokens.
     * See `checkpointToken` for more details.
     * @param tokens - An array of ERC20 token addresses to be checkpointed.
     */
    function checkpointTokens(IERC20[] calldata tokens) external;

    // Claiming

    /**
     * @notice Claims all pending distributions of the provided token for a user.
     * @dev It's not necessary to explicitly checkpoint before calling this function, it will ensure the FeeDistributor
     * is up to date before calculating the amount of tokens to be claimed.
     * @param user - The user on behalf of which to claim.
     * @param token - The ERC20 token address to be claimed.
     * @return The amount of `token` sent to `user` as a result of claiming.
     */
    function claimToken(address user, IERC20 token) external returns (uint256);

    /**
     * @notice Claims a number of tokens on behalf of a user.
     * @dev A version of `claimToken` which supports claiming multiple `tokens` on behalf of `user`.
     * See `claimToken` for more details.
     * @param user - The user on behalf of which to claim.
     * @param tokens - An array of ERC20 token addresses to be claimed.
     * @return An array of the amounts of each token in `tokens` sent to `user` as a result of claiming.
     */
    function claimTokens(address user, IERC20[] calldata tokens) external returns (uint256[] memory);

    // Governance

    /**
     * @notice Withdraws the specified `amount` of the `token` from the contract to the `recipient`. Can be called only
     * by Stargate DAO.
     * @param token - The token to withdraw.
     * @param amount - The amount to withdraw.
     * @param recipient - The address to transfer the tokens to.
     */
    function withdrawToken(IERC20 token, uint256 amount, address recipient) external;

    /**
     * @notice Enables or disables claiming of the given token. Can be called only by Stargate DAO.
     * @param token - The token to enable or disable claiming.
     * @param enable - True if the token can be claimed, false otherwise.
     */
    function enableTokenClaiming(IERC20 token, bool enable) external;
}

// solhint-disable not-rely-on-time

/**
 * @title Fee Distributor
 * @author Balancer Labs. Original version
 * https://github.com/balancer/balancer-v2-monorepo/blob/master/pkg/liquidity-mining/contracts/fee-distribution/FeeDistributor.sol
 * @notice Distributes any tokens transferred to the contract (e.g. Protocol fees) among veRAFT
 * holders proportionally based on a snapshot of the week at which the tokens are sent to the FeeDistributor contract.
 * @dev Supports distributing arbitrarily many different tokens. In order to start distributing a new token to veRAFT
 * holders call `depositToken`.
 */
contract FeeDistributor is IFeeDistributor, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // gas optimization
    uint256 private constant WEEK_MINUS_SECOND = 1 weeks - 1;

    IVotingEscrow private immutable _votingEscrow;

    uint256 private immutable _startTime;

    // Global State
    uint256 private _timeCursor;
    mapping(uint256 => uint256) private _veSupplyCache;

    // Token State

    // `startTime` and `timeCursor` are both timestamps so comfortably fit in a uint64.
    // `cachedBalance` will comfortably fit the total supply of any meaningful token.
    // Should more than 2^128 tokens be sent to this contract then checkpointing this token will fail until enough
    // tokens have been claimed to bring the total balance back below 2^128.
    struct TokenState {
        uint64 startTime;
        uint64 timeCursor;
        uint128 cachedBalance;
    }

    mapping(IERC20 => TokenState) private _tokenState;
    mapping(IERC20 => mapping(uint256 => uint256)) private _tokensPerWeek;
    mapping(IERC20 => bool) private _tokenClaimingEnabled;

    // User State

    // `startTime` and `timeCursor` are timestamps so will comfortably fit in a uint64.
    // For `lastEpochCheckpointed` to overflow would need over 2^128 transactions to the VotingEscrow contract.
    struct UserState {
        uint64 startTime;
        uint64 timeCursor;
        uint128 lastEpochCheckpointed;
    }

    mapping(address => UserState) internal _userState;
    mapping(address => mapping(uint256 => uint256)) private _userBalanceAtTimestamp;
    mapping(address => mapping(IERC20 => uint256)) private _userTokenTimeCursor;
    mapping(address => bool) private _onlyVeHolderClaimingEnabled;

    /**
     * @dev Reverts if only the VotingEscrow holder can claim their rewards and the given address is a third-party
     * caller.
     * @param user - The address to validate as the only allowed caller.
     */
    modifier userAllowedToClaim(address user) {
        if (_onlyVeHolderClaimingEnabled[user]) {
            require(msg.sender == user, "Claiming is not allowed");
        }
        _;
    }

    /**
     * @dev Reverts if the given token cannot be claimed.
     * @param token - The token to check.
     */
    modifier tokenCanBeClaimed(IERC20 token) {
        _checkIfClaimingEnabled(token);
        _;
    }

    /**
     * @dev Reverts if the given tokens cannot be claimed.
     * @param tokens - The tokens to check.
     */
    modifier tokensCanBeClaimed(IERC20[] calldata tokens) {
        uint256 tokensLength = tokens.length;
        for (uint256 i = 0; i < tokensLength; ++i) {
            _checkIfClaimingEnabled(tokens[i]);
        }
        _;
    }

    constructor(IVotingEscrow votingEscrow, uint256 startTime) {
        _votingEscrow = votingEscrow;

        startTime = _roundDownTimestamp(startTime);
        uint256 currentWeek = _roundDownTimestamp(block.timestamp);
        require(startTime >= currentWeek, "Cannot start before current week");

        (int128 bias, int128 slope, uint256 ts, uint256 blk) = votingEscrow.point_history(0);
        IVotingEscrow.Point memory pt = IVotingEscrow.Point(bias, slope, ts, blk);
        require(startTime > pt.ts, "Cannot start before VotingEscrow first epoch");

        _startTime = startTime;
        _timeCursor = startTime;
    }

    /**
     * @notice Returns the VotingEscrow (veRAFT) token contract
     */
    function getVotingEscrow() external view override returns (IVotingEscrow) {
        return _votingEscrow;
    }

    /**
     * @notice Returns the time when fee distribution starts.
     */
    function getStartTime() external view override returns (uint256) {
        return _startTime;
    }

    /**
     * @notice Returns the global time cursor representing the most earliest uncheckpointed week.
     */
    function getTimeCursor() external view override returns (uint256) {
        return _timeCursor;
    }

    /**
     * @notice Returns the user-level start time representing the first week they're eligible to claim tokens.
     * @param user - The address of the user to query.
     */
    function getUserStartTime(address user) external view override returns (uint256) {
        return _userState[user].startTime;
    }

    /**
     * @notice Returns the user-level time cursor representing the most earliest uncheckpointed week.
     * @param user - The address of the user to query.
     */
    function getUserTimeCursor(address user) external view override returns (uint256) {
        return _userState[user].timeCursor;
    }

    /**
     * @notice Returns the user-level last checkpointed epoch.
     * @param user - The address of the user to query.
     */
    function getUserLastEpochCheckpointed(address user) external view override returns (uint256) {
        return _userState[user].lastEpochCheckpointed;
    }

    /**
     * @notice True if the given token can be claimed, false otherwise.
     * @param token - The ERC20 token address to query.
     */
    function canTokenBeClaimed(IERC20 token) external view override returns (bool) {
        return _tokenClaimingEnabled[token];
    }

    /**
     * @notice Returns the token-level start time representing the timestamp users could start claiming this token
     * @param token - The ERC20 token address to query.
     */
    function getTokenStartTime(IERC20 token) external view override returns (uint256) {
        return _tokenState[token].startTime;
    }

    /**
     * @notice Returns the token-level time cursor storing the timestamp at up to which tokens have been distributed.
     * @param token - The ERC20 token address to query.
     */
    function getTokenTimeCursor(IERC20 token) external view override returns (uint256) {
        return _tokenState[token].timeCursor;
    }

    /**
     * @notice Returns the token-level cached balance.
     * @param token - The ERC20 token address to query.
     */
    function getTokenCachedBalance(IERC20 token) external view override returns (uint256) {
        return _tokenState[token].cachedBalance;
    }

    /**
     * @notice Returns the user-level time cursor storing the timestamp of the latest token distribution claimed.
     * @param user - The address of the user to query.
     * @param token - The ERC20 token address to query.
     */
    function getUserTokenTimeCursor(address user, IERC20 token) external view override returns (uint256) {
        return _getUserTokenTimeCursor(user, token);
    }

    /**
     * @notice Returns the user's cached balance of veRAFT as of the provided timestamp.
     * @dev Only timestamps which fall on Thursdays 00:00:00 UTC will return correct values.
     * This function requires `user` to have been checkpointed past `timestamp` so that their balance is cached.
     * @param user - The address of the user of which to read the cached balance of.
     * @param timestamp - The timestamp at which to read the `user`'s cached balance at.
     */
    function getUserBalanceAtTimestamp(address user, uint256 timestamp) external view override returns (uint256) {
        return _userBalanceAtTimestamp[user][timestamp];
    }

    /**
     * @notice Returns the cached total supply of veRAFT as of the provided timestamp.
     * @dev Only timestamps which fall on Thursdays 00:00:00 UTC will return correct values.
     * This function requires the contract to have been checkpointed past `timestamp` so that the supply is cached.
     * @param timestamp - The timestamp at which to read the cached total supply at.
     */
    function getTotalSupplyAtTimestamp(uint256 timestamp) external view override returns (uint256) {
        return _veSupplyCache[timestamp];
    }

    /**
     * @notice Returns the FeeDistributor's cached balance of `token`.
     */
    function getTokenLastBalance(IERC20 token) external view override returns (uint256) {
        return _tokenState[token].cachedBalance;
    }

    /**
     * @notice Returns the amount of `token` which the FeeDistributor received in the week beginning at `timestamp`.
     * @param token - The ERC20 token address to query.
     * @param timestamp - The timestamp corresponding to the beginning of the week of interest.
     */
    function getTokensDistributedInWeek(IERC20 token, uint256 timestamp) external view override returns (uint256) {
        return _tokensPerWeek[token][timestamp];
    }

    // Preventing third-party claiming

    /**
     * @notice Enables / disables rewards claiming only by the VotingEscrow holder for the message sender.
     * @param enabled - True if only the VotingEscrow holder can claim their rewards, false otherwise.
     */
    function enableOnlyVeHolderClaiming(bool enabled) external override {
        _onlyVeHolderClaimingEnabled[msg.sender] = enabled;
        emit OnlyVeHolderClaimingEnabled(msg.sender, enabled);
    }

    /**
     * @notice Returns true if only the VotingEscrow holder can claim their rewards, false otherwise.
     */
    function onlyVeHolderClaimingEnabled(address user) external view override returns (bool) {
        return _onlyVeHolderClaimingEnabled[user];
    }

    // Depositing

    /**
     * @notice Deposits tokens to be distributed in the current week.
     * @dev Sending tokens directly to the FeeDistributor instead of using `depositToken` may result in tokens being
     * retroactively distributed to past weeks, or for the distribution to carry over to future weeks.
     *
     * If for some reason `depositToken` cannot be called, in order to ensure that all tokens are correctly distributed
     * manually call `checkpointToken` before and after the token transfer.
     * @param token - The ERC20 token address to distribute.
     * @param amount - The amount of tokens to deposit.
     */
    function depositToken(IERC20 token, uint256 amount) external override nonReentrant tokenCanBeClaimed(token) {
        _checkpointToken(token, false);
        token.safeTransferFrom(msg.sender, address(this), amount);
        _checkpointToken(token, true);
    }

    /**
     * @notice Deposits tokens to be distributed in the current week.
     * @dev A version of `depositToken` which supports depositing multiple `tokens` at once.
     * See `depositToken` for more details.
     * @param tokens - An array of ERC20 token addresses to distribute.
     * @param amounts - An array of token amounts to deposit.
     */
    function depositTokens(IERC20[] calldata tokens, uint256[] calldata amounts) external override nonReentrant {
        require(tokens.length == amounts.length, "Input length mismatch");

        uint256 length = tokens.length;
        for (uint256 i = 0; i < length; ++i) {
            _checkIfClaimingEnabled(tokens[i]);
            _checkpointToken(tokens[i], false);
            tokens[i].safeTransferFrom(msg.sender, address(this), amounts[i]);
            _checkpointToken(tokens[i], true);
        }
    }

    // Checkpointing

    /**
     * @notice Caches the total supply of veRAFT at the beginning of each week.
     * This function will be called automatically before claiming tokens to ensure the contract is properly updated.
     */
    function checkpoint() external override nonReentrant {
        _checkpointTotalSupply();
    }

    /**
     * @notice Caches the user's balance of veRAFT at the beginning of each week.
     * This function will be called automatically before claiming tokens to ensure the contract is properly updated.
     * @param user - The address of the user to be checkpointed.
     */
    function checkpointUser(address user) external override nonReentrant {
        _checkpointUserBalance(user);
    }

    /**
     * @notice Assigns any newly-received tokens held by the FeeDistributor to weekly distributions.
     * @dev Any `token` balance held by the FeeDistributor above that which is returned by `getTokenLastBalance`
     * will be distributed evenly across the time period since `token` was last checkpointed.
     *
     * This function will be called automatically before claiming tokens to ensure the contract is properly updated.
     * @param token - The ERC20 token address to be checkpointed.
     */
    function checkpointToken(IERC20 token) external override nonReentrant tokenCanBeClaimed(token) {
        _checkpointToken(token, true);
    }

    /**
     * @notice Assigns any newly-received tokens held by the FeeDistributor to weekly distributions.
     * @dev A version of `checkpointToken` which supports checkpointing multiple tokens.
     * See `checkpointToken` for more details.
     * @param tokens - An array of ERC20 token addresses to be checkpointed.
     */
    function checkpointTokens(IERC20[] calldata tokens) external override nonReentrant {
        uint256 tokensLength = tokens.length;
        for (uint256 i = 0; i < tokensLength; ++i) {
            _checkIfClaimingEnabled(tokens[i]);
            _checkpointToken(tokens[i], true);
        }
    }

    // Claiming

    /**
     * @notice Claims all pending distributions of the provided token for a user.
     * @dev It's not necessary to explicitly checkpoint before calling this function, it will ensure the FeeDistributor
     * is up to date before calculating the amount of tokens to be claimed.
     * @param user - The user on behalf of which to claim.
     * @param token - The ERC20 token address to be claimed.
     * @return The amount of `token` sent to `user` as a result of claiming.
     */
    function claimToken(
        address user,
        IERC20 token
    )
        external
        override
        nonReentrant
        userAllowedToClaim(user)
        tokenCanBeClaimed(token)
        returns (uint256)
    {
        _checkpointTotalSupply();
        _checkpointUserBalance(user);
        _checkpointToken(token, false);

        return _claimToken(user, token);
    }

    /**
     * @notice Claims a number of tokens on behalf of a user.
     * @dev A version of `claimToken` which supports claiming multiple `tokens` on behalf of `user`.
     * See `claimToken` for more details.
     * @param user - The user on behalf of which to claim.
     * @param tokens - An array of ERC20 token addresses to be claimed.
     * @return An array of the amounts of each token in `tokens` sent to `user` as a result of claiming.
     */
    function claimTokens(
        address user,
        IERC20[] calldata tokens
    )
        external
        override
        nonReentrant
        userAllowedToClaim(user)
        tokensCanBeClaimed(tokens)
        returns (uint256[] memory)
    {
        _checkpointTotalSupply();
        _checkpointUserBalance(user);

        uint256 tokensLength = tokens.length;
        uint256[] memory amounts = new uint256[](tokensLength);
        for (uint256 i = 0; i < tokensLength; ++i) {
            _checkpointToken(tokens[i], false);
            amounts[i] = _claimToken(user, tokens[i]);
        }

        return amounts;
    }

    // Governance

    /**
     * @notice Withdraws the specified `amount` of the `token` from the contract to the `recipient`. Can be called only
     * by Raft DAO.
     * @param token - The token to withdraw.
     * @param amount - The amount to withdraw.
     * @param recipient - The address to transfer the tokens to.
     */
    function withdrawToken(IERC20 token, uint256 amount, address recipient) external override onlyOwner {
        token.safeTransfer(recipient, amount);
        emit TokenWithdrawn(token, amount, recipient);
    }

    /**
     * @notice Enables or disables claiming of the given token. Can be called only by Raft DAO.
     * @param token - The token to enable or disable claiming.
     * @param enable - True if the token can be claimed, false otherwise.
     */
    function enableTokenClaiming(IERC20 token, bool enable) external override onlyOwner {
        _tokenClaimingEnabled[token] = enable;
        emit TokenClaimingEnabled(token, enable);
    }

    // Internal functions

    /**
     * @dev It is required that both the global, token and user state have been properly checkpointed
     * before calling this function.
     */
    function _claimToken(address user, IERC20 token) internal returns (uint256) {
        TokenState storage tokenState = _tokenState[token];
        uint256 nextUserTokenWeekToClaim = _getUserTokenTimeCursor(user, token);

        // The first week which cannot be correctly claimed is the earliest of:
        // - A) The global or user time cursor (whichever is earliest), rounded up to the end of the week.
        // - B) The token time cursor, rounded down to the beginning of the week.
        //
        // This prevents the two failure modes:
        // - A) A user may claim a week for which we have not processed their balance, resulting in tokens being
        // locked.
        // - B) A user may claim a week which then receives more tokens to be distributed. However the user has
        //      already claimed for that week so their share of these new tokens are lost.
        uint256 firstUnclaimableWeek = Math.min(
            _roundUpTimestamp(Math.min(_timeCursor, _userState[user].timeCursor)),
            _roundDownTimestamp(tokenState.timeCursor)
        );

        mapping(uint256 => uint256) storage tokensPerWeek = _tokensPerWeek[token];
        mapping(uint256 => uint256) storage userBalanceAtTimestamp = _userBalanceAtTimestamp[user];

        uint256 amount;
        for (uint256 i = 0; i < 20; ++i) {
            // We clearly cannot claim for `firstUnclaimableWeek` and so we break here.
            if (nextUserTokenWeekToClaim >= firstUnclaimableWeek) break;

            amount += (tokensPerWeek[nextUserTokenWeekToClaim] * userBalanceAtTimestamp[nextUserTokenWeekToClaim])
                / _veSupplyCache[nextUserTokenWeekToClaim];
            nextUserTokenWeekToClaim += 1 weeks;
        }
        // Update the stored user-token time cursor to prevent this user claiming this week again.
        _userTokenTimeCursor[user][token] = nextUserTokenWeekToClaim;

        if (amount > 0) {
            // For a token to be claimable it must have been added to the cached balance so this is safe.
            tokenState.cachedBalance = uint128(tokenState.cachedBalance - amount);
            token.safeTransfer(user, amount);
            emit TokensClaimed(user, token, amount, nextUserTokenWeekToClaim);
        }

        return amount;
    }

    /**
     * @dev Calculate the amount of `token` to be distributed to `_votingEscrow` holders since the last checkpoint.
     */
    function _checkpointToken(IERC20 token, bool force) internal {
        TokenState storage tokenState = _tokenState[token];
        uint256 lastTokenTime = tokenState.timeCursor;
        uint256 timeSinceLastCheckpoint;
        if (lastTokenTime == 0) {
            // Prevent someone from assigning tokens to an inaccessible week.
            require(block.timestamp > _startTime, "Fee distribution has not started yet");

            // If it's the first time we're checkpointing this token then start distributing from now.
            // Also mark at which timestamp users should start attempts to claim this token from.
            lastTokenTime = block.timestamp;
            tokenState.startTime = uint64(_roundDownTimestamp(block.timestamp));
        } else {
            timeSinceLastCheckpoint = block.timestamp - lastTokenTime;

            if (!force) {
                // Checkpointing N times within a single week is completely equivalent to checkpointing once at the
                // end.
                // We then want to get as close as possible to a single checkpoint every Wed 23:59 UTC to save gas.

                // We then skip checkpointing if we're in the same week as the previous checkpoint.
                bool alreadyCheckpointedThisWeek =
                    _roundDownTimestamp(block.timestamp) == _roundDownTimestamp(lastTokenTime);
                // However we want to ensure that all of this week's fees are assigned to the current week without
                // overspilling into the next week. To mitigate this, we checkpoint if we're near the end of the week.
                bool nearingEndOfWeek = _roundUpTimestamp(block.timestamp) - block.timestamp < 1 days;

                // This ensures that we checkpoint once at the beginning of the week and again for each user
                // interaction
                // towards the end of the week to give an accurate final reading of the balance.
                if (alreadyCheckpointedThisWeek && !nearingEndOfWeek) {
                    return;
                }
            }
        }

        tokenState.timeCursor = uint64(block.timestamp);

        uint256 tokenBalance = token.balanceOf(address(this));
        uint256 newTokensToDistribute = tokenBalance - tokenState.cachedBalance;
        if (newTokensToDistribute == 0) return;
        require(tokenBalance <= type(uint128).max, "Maximum token balance exceeded");
        tokenState.cachedBalance = uint128(tokenBalance);

        uint256 firstIncompleteWeek = _roundDownTimestamp(lastTokenTime);
        uint256 nextWeek = 0;

        // Distribute `newTokensToDistribute` evenly across the time period from `lastTokenTime` to now.
        // These tokens are assigned to weeks proportionally to how much of this period falls into each week.
        mapping(uint256 => uint256) storage tokensPerWeek = _tokensPerWeek[token];
        for (uint256 i = 0; i < 20; ++i) {
            // This is safe as we're incrementing a timestamp.
            nextWeek = firstIncompleteWeek + 1 weeks;
            if (block.timestamp < nextWeek) {
                // `firstIncompleteWeek` is now the beginning of the current week, i.e. this is the final iteration.
                if (timeSinceLastCheckpoint == 0 && block.timestamp == lastTokenTime) {
                    tokensPerWeek[firstIncompleteWeek] += newTokensToDistribute;
                } else {
                    // block.timestamp >= lastTokenTime by definition.
                    tokensPerWeek[firstIncompleteWeek] +=
                        (newTokensToDistribute * (block.timestamp - lastTokenTime)) / timeSinceLastCheckpoint;
                }
                // As we've caught up to the present then we should now break.
                break;
            } else {
                // We've gone a full week or more without checkpointing so need to distribute tokens to previous weeks.
                if (timeSinceLastCheckpoint == 0 && nextWeek == lastTokenTime) {
                    // It shouldn't be possible to enter this block
                    tokensPerWeek[firstIncompleteWeek] += newTokensToDistribute;
                } else {
                    // nextWeek > lastTokenTime by definition.
                    tokensPerWeek[firstIncompleteWeek] +=
                        (newTokensToDistribute * (nextWeek - lastTokenTime)) / timeSinceLastCheckpoint;
                }
            }

            // We've now "checkpointed" up to the beginning of next week so must update timestamps appropriately.
            lastTokenTime = nextWeek;
            firstIncompleteWeek = nextWeek;
        }

        emit TokenCheckpointed(token, newTokensToDistribute, lastTokenTime);
    }

    /**
     * @dev Cache the `user`'s balance of `_votingEscrow` at the beginning of each new week
     */
    function _checkpointUserBalance(address user) internal {
        uint256 maxUserEpoch = _votingEscrow.user_point_epoch(user);

        // If user has no epochs then they have never locked RAFT.
        // They clearly will not then receive fees.
        require(maxUserEpoch > 0, "veRAFT balance is zero");

        UserState storage userState = _userState[user];

        // `nextWeekToCheckpoint` represents the timestamp of the beginning of the first week
        // which we haven't checkpointed the user's VotingEscrow balance yet.
        uint256 nextWeekToCheckpoint = userState.timeCursor;

        uint256 userEpoch;
        if (nextWeekToCheckpoint == 0) {
            // First checkpoint for user so need to do the initial binary search
            userEpoch = _findTimestampUserEpoch(user, _startTime, 0, maxUserEpoch);
        } else {
            if (nextWeekToCheckpoint >= block.timestamp) {
                // User has checkpointed the current week already so perform early return.
                // This prevents a user from processing epochs created later in this week, however this is not an issue
                // as if a significant number of these builds up then the user will skip past them with a binary
                // search.
                return;
            }

            // Otherwise use the value saved from last time
            userEpoch = userState.lastEpochCheckpointed;

            // This optimizes a scenario common for power users, which have frequent `VotingEscrow` interactions in
            // the same week. We assume that any such user is also claiming fees every week, and so we only perform
            // a binary search here rather than integrating it into the main search algorithm, effectively skipping
            // most of the week's irrelevant checkpoints.
            // The slight tradeoff is that users who have multiple infrequent `VotingEscrow` interactions and also
            // don't
            // claim frequently will also perform the binary search, despite it not leading to gas savings.
            if (maxUserEpoch - userEpoch > 20) {
                userEpoch = _findTimestampUserEpoch(user, nextWeekToCheckpoint, userEpoch, maxUserEpoch);
            }
        }

        // Epoch 0 is always empty so bump onto the next one so that we start on a valid epoch.
        if (userEpoch == 0) {
            userEpoch = 1;
        }

        IVotingEscrow.Point memory nextUserPoint;
        {
            (int128 bias, int128 slope, uint256 ts, uint256 blk) = _votingEscrow.user_point_history(user, userEpoch);
            nextUserPoint = IVotingEscrow.Point(bias, slope, ts, blk);
        }

        // If this is the first checkpoint for the user, calculate the first week they're eligible for.
        // i.e. the timestamp of the first Thursday after they locked.
        // If this is earlier then the first distribution then fast forward to then.
        if (nextWeekToCheckpoint == 0) {
            // Disallow checkpointing before `startTime`.
            require(block.timestamp > _startTime, "Fee distribution has not started yet");
            nextWeekToCheckpoint = Math.max(_startTime, _roundUpTimestamp(nextUserPoint.ts));
            userState.startTime = uint64(nextWeekToCheckpoint);
        }

        // It's safe to increment `userEpoch` and `nextWeekToCheckpoint` in this loop as epochs and timestamps
        // are always much smaller than 2^256 and are being incremented by small values.
        IVotingEscrow.Point memory currentUserPoint;
        for (uint256 i = 0; i < 50; ++i) {
            if (nextWeekToCheckpoint >= nextUserPoint.ts && userEpoch <= maxUserEpoch) {
                // The week being considered is contained in a user epoch after that described by `currentUserPoint`.
                // We then shift `nextUserPoint` into `currentUserPoint` and query the Point for the next user epoch.
                // We do this in order to step though epochs until we find the first epoch starting after
                // `nextWeekToCheckpoint`, making the previous epoch the one that contains `nextWeekToCheckpoint`.
                userEpoch += 1;
                currentUserPoint = nextUserPoint;
                if (userEpoch > maxUserEpoch) {
                    nextUserPoint = IVotingEscrow.Point(0, 0, 0, 0);
                } else {
                    (int128 bias, int128 slope, uint256 ts, uint256 blk) =
                        _votingEscrow.user_point_history(user, userEpoch);
                    nextUserPoint = IVotingEscrow.Point(bias, slope, ts, blk);
                }
            } else {
                // The week being considered lies inside the user epoch described by `oldUserPoint`
                // we can then use it to calculate the user's balance at the beginning of the week.
                if (nextWeekToCheckpoint >= block.timestamp) {
                    // Break if we're trying to cache the user's balance at a timestamp in the future.
                    // We only perform this check here to ensure that we can still process checkpoints created
                    // in the current week.
                    break;
                }

                int128 dt = int128(int256(nextWeekToCheckpoint) - int256(currentUserPoint.ts));
                uint256 userBalance = currentUserPoint.bias > currentUserPoint.slope * dt
                    ? uint256(int256(currentUserPoint.bias - currentUserPoint.slope * dt))
                    : 0;

                // User's lock has expired and they haven't relocked yet.
                if (userBalance == 0 && userEpoch > maxUserEpoch) {
                    nextWeekToCheckpoint = _roundUpTimestamp(block.timestamp);
                    break;
                }

                // User had a nonzero lock and so is eligible to collect fees.
                _userBalanceAtTimestamp[user][nextWeekToCheckpoint] = uint256(userBalance);

                nextWeekToCheckpoint += 1 weeks;
            }
        }

        // We subtract off 1 from the userEpoch to step back once so that on the next attempt to checkpoint
        // the current `currentUserPoint` will be loaded as `nextUserPoint`. This ensures that we can't skip over the
        // user epoch containing `nextWeekToCheckpoint`.
        // userEpoch > 0 so this is safe.
        userState.lastEpochCheckpointed = uint64(userEpoch - 1);
        userState.timeCursor = uint64(nextWeekToCheckpoint);
    }

    /**
     * @dev Cache the totalSupply of VotingEscrow token at the beginning of each new week
     */
    function _checkpointTotalSupply() internal {
        uint256 nextWeekToCheckpoint = _timeCursor;
        uint256 weekStart = _roundDownTimestamp(block.timestamp);

        // We expect `timeCursor == weekStart + 1 weeks` when fully up to date.
        if (nextWeekToCheckpoint > weekStart || weekStart == block.timestamp) {
            // We've already checkpointed up to this week so perform early return
            return;
        }

        _votingEscrow.checkpoint();

        // Step through the each week and cache the total supply at beginning of week on this contract
        for (uint256 i = 0; i < 20; ++i) {
            if (nextWeekToCheckpoint > weekStart) break;

            // NOTE: Replaced Balancer's logic with Solidly/Velodrome implementation due to the differences in the
            // VotingEscrow totalSupply function
            // See https://github.com/velodrome-finance/v1/blob/master/contracts/RewardsDistributor.sol#L143

            uint256 epoch = _findTimestampEpoch(nextWeekToCheckpoint);

            (int128 bias, int128 slope, uint256 ts, uint256 blk) = _votingEscrow.point_history(epoch);
            IVotingEscrow.Point memory pt = IVotingEscrow.Point(bias, slope, ts, blk);

            int128 dt = nextWeekToCheckpoint > pt.ts ? int128(uint128(nextWeekToCheckpoint - pt.ts)) : int128(0);
            int128 supply = pt.bias - pt.slope * dt;
            _veSupplyCache[nextWeekToCheckpoint] = supply > 0 ? uint256(int256(supply)) : 0;

            // This is safe as we're incrementing a timestamp
            nextWeekToCheckpoint += 1 weeks;
        }
        // Update state to the end of the current week (`weekStart` + 1 weeks)
        _timeCursor = nextWeekToCheckpoint;
    }

    // Helper functions

    /**
     * @dev Wrapper around `_userTokenTimeCursor` which returns the start timestamp for `token`
     * if `user` has not attempted to interact with it previously.
     */
    function _getUserTokenTimeCursor(address user, IERC20 token) internal view returns (uint256) {
        uint256 userTimeCursor = _userTokenTimeCursor[user][token];
        if (userTimeCursor > 0) return userTimeCursor;
        // This is the first time that the user has interacted with this token.
        // We then start from the latest out of either when `user` first locked veRAFT or `token` was first
        // checkpointed.
        return Math.max(_userState[user].startTime, _tokenState[token].startTime);
    }

    /**
     * @dev Return the user epoch number for `user` corresponding to the provided `timestamp`
     */
    function _findTimestampUserEpoch(
        address user,
        uint256 timestamp,
        uint256 minUserEpoch,
        uint256 maxUserEpoch
    )
        internal
        view
        returns (uint256)
    {
        uint256 min = minUserEpoch;
        uint256 max = maxUserEpoch;

        // Perform binary search through epochs to find epoch containing `timestamp`
        for (uint256 i = 0; i < 128; ++i) {
            if (min >= max) break;

            // Algorithm assumes that inputs are less than 2^128 so this operation is safe.
            // +2 avoids getting stuck in min == mid < max
            uint256 mid = (min + max + 2) / 2;
            (int128 bias, int128 slope, uint256 ts, uint256 blk) = _votingEscrow.user_point_history(user, mid);
            IVotingEscrow.Point memory pt = IVotingEscrow.Point(bias, slope, ts, blk);
            if (pt.ts <= timestamp) {
                min = mid;
            } else {
                // max > min so this is safe.
                max = mid - 1;
            }
        }
        return min;
    }

    /**
     * @dev Return the global epoch number corresponding to the provided `timestamp`
     */
    function _findTimestampEpoch(uint256 timestamp) internal view returns (uint256) {
        uint256 min = 0;
        uint256 max = _votingEscrow.epoch();

        // Perform binary search through epochs to find epoch containing `timestamp`
        for (uint256 i = 0; i < 128; i++) {
            if (min >= max) break;

            // Algorithm assumes that inputs are less than 2^128 so this operation is safe.
            // +2 avoids getting stuck in min == mid < max
            uint256 mid = (min + max + 2) / 2;
            (int128 bias, int128 slope, uint256 ts, uint256 blk) = _votingEscrow.point_history(mid);
            IVotingEscrow.Point memory pt = IVotingEscrow.Point(bias, slope, ts, blk);
            if (pt.ts <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }
        return min;
    }

    /**
     * @dev Rounds the provided timestamp down to the beginning of the previous week (Thurs 00:00 UTC)
     */
    function _roundDownTimestamp(uint256 timestamp) private pure returns (uint256) {
        // Division by zero or overflows are impossible here.
        return (timestamp / 1 weeks) * 1 weeks;
    }

    /**
     * @dev Rounds the provided timestamp up to the beginning of the next week (Thurs 00:00 UTC)
     */
    function _roundUpTimestamp(uint256 timestamp) private pure returns (uint256) {
        // Overflows are impossible here for all realistic inputs.
        return _roundDownTimestamp(timestamp + WEEK_MINUS_SECOND);
    }

    /**
     * @dev Reverts if the provided token cannot be claimed.
     */
    function _checkIfClaimingEnabled(IERC20 token) private view {
        require(_tokenClaimingEnabled[token], "Token is not allowed");
    }
}