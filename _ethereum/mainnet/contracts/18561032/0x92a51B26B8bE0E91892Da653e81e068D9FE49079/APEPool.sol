// File: IApeStakePool.sol

pragma solidity ^0.8.21;


interface IApeStakePool{
    function depositSelfApeCoin(uint256 _amount) external;
    function claimSelfApeCoin() external;
    function withdrawSelfApeCoin(uint256 _amount) external;
    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256);
}
// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: IRewardReserve.sol

pragma solidity ^0.8.21;

interface IRewardReserve{
    function transferReward(address token, uint256 amount, address to) external;
}
// File: IRoleRegistry.sol

pragma solidity ^0.8.21;


interface IRoleRegistry{
    function getRouter() external view returns(address);
    function getOwner() external view returns(address);
    function getController() external view returns(address);
    function getRewardDistributor() external view returns(address);
    function getOperator() external view returns(address);
    function getVRF() external view returns(address);
    function getReserveAddress() external view returns(address);
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


// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

// File: APEPoolV2.sol

pragma solidity ^0.8.21;







contract APEPool{
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    event rewardPortionUpdated(uint256 first, uint256 second, uint256 third);
    event OwnershipTransferred(address oldOwner, address newOwner);
    event ControllerRoleTransferred(address oldController, address newController);
    event changedRouter(address oldRouter, address newRouter);


    struct PrizeDetails{
        address winner;
        uint256 prizeAmount;
        bool claimed;
    }
    struct EpochResult{
        PrizeDetails first;
        PrizeDetails second;
        PrizeDetails third;
        bool finalized;
        uint256 totalPrize;
        uint256 duration;
        uint256 createdTimeStamp;
        //uint256 totalParticipant;
    }

    struct rewardAllocation{
        uint256 first;
        uint256 second;
        uint256 third;
    }
    struct userInfo{
        address userAddress;
        uint256 DepositAmount;
        uint256 registeredDate;
        uint256 Lastupdated;
        //uint256 depositTimeStamp;
    }
    struct ChangeArray{
        uint256 oldAmount;
        uint256 newAmount;
        uint256 updatedBlock;
    }
    struct userChangeHistory{
        bool changedwithinEpoch;
        ChangeArray[] historyArray;
    }
    struct rewardHistory{
        uint256 EpochNumber;
        uint256 position;
        uint256 PrizeAmount;
    }
    struct claimableRewardInfo{
        uint256 claimable;
        rewardHistory[] rewardHistoryArray;
        uint256[] temporaryNotClaimedEpochArray;
    }


    
    address registryContract;
    bool initialized;
    uint256 amountOfUser;
    mapping(uint256 => userInfo) internal userDepositInfo;
    mapping(address => uint256) internal userID;
    //mapping(address => userInfo) public userDepositInfo;
    mapping(uint256 => mapping(uint256 => uint256)) internal accumulatedTicket;
    mapping(uint256 => mapping(uint256 => userChangeHistory)) internal changeHistory;
    mapping(address => claimableRewardInfo) internal claimableRewardData;
    uint256 status;
    uint256 poolTVL;
    rewardAllocation AllocationPortion;
    uint256 PercentageDecimal;
    EpochResult[] EpochResults;
    uint256 epochDuration;
    address TokentoDeposit;
    address StakePoolAddress;
    //uint256 minToDeposit;
    uint256 TICKET_DECIMAL;
    uint256 APE_COIN_POOL_ID = 0;
    uint256 APE_COIN_TOKEN_ID = 0;
    
    
    modifier validEpoch(uint256 epochNumber){
        uint256 latestEpoch = EpochResults.length.sub(1);
        require(epochNumber <= latestEpoch,"Invalid epoch number");
        _;
    }

    modifier contractStarted(){
        //uint256 epochLength = getEpochLength();
        require(EpochResults.length > 0, "Contract not started");
        _;
    }
    modifier onlyRewardDistributor(){
        address role = IRoleRegistry(registryContract).getRewardDistributor();
        require(msg.sender == role, "Invalid caller");
        _;
    }
    modifier onlyOwner(){
        address role = IRoleRegistry(registryContract).getOwner();
        require(msg.sender == role, "Invalid caller");
        _;
    }

    modifier onlyController(){
        address role = IRoleRegistry(registryContract).getController();
        require(msg.sender == role, "Invalid caller");
        _;
    }

    modifier onlyRouter(){
        address role = IRoleRegistry(registryContract).getRouter();
        require(msg.sender == role, "Invalid caller");
        _;
    }
    modifier nonReentrant(){
        require(status == 0, "Illegal call");
        status = 1;
        _;
        status = 0;
    }
    function initialize(address registryAddress) external{
        require(initialized == false, "Contract is initialized already");
        _transferRegistryAddr(registryAddress);
        initialized = true;
    }
    function _transferRegistryAddr(address registryAddress) internal{
        registryContract = registryAddress;
    }
    function changeRegistryContractAddr(address registryAddress) external onlyOwner{
        _transferRegistryAddr(registryAddress);
    }
    //function getMinAmountToDeposit() public view returns(uint256){
        //uint256 result = minToDeposit;
        //return result;
    //}

    function setStakePoolAddress(address StakePoolAdd) external onlyController{
        StakePoolAddress = StakePoolAdd;
    }
    function depositFor(address user, uint256 amount) external onlyRouter nonReentrant contractStarted{
        //require(amount >= minToDeposit,"The minimum amount is not met");
        uint256 realDepositAmount = getTokenFromMsgsender(amount);
        stakeToPool(realDepositAmount);
        updateUserInfo(user, realDepositAmount,true);
    }

    function stakeToPool(uint256 amount) internal{
        IERC20(TokentoDeposit).safeApprove(StakePoolAddress,0);
        IERC20(TokentoDeposit).safeApprove(StakePoolAddress,amount);
        IApeStakePool(StakePoolAddress).depositSelfApeCoin(amount);
    }

    function withdrawFor(address user, uint256 amount) external onlyRouter nonReentrant contractStarted{
        require(amount > 0, "Invalid amount");
        updateUserInfo(user, amount, false);
        uint256 balanceBeforeWithdraw = IERC20(TokentoDeposit).balanceOf(address(this));
        unstakeFromPool(amount);
        uint256 balanceAfterWithdraw = IERC20(TokentoDeposit).balanceOf(address(this));
        uint256 changeAfterWithdraw = balanceAfterWithdraw.sub(balanceBeforeWithdraw);
        sendTokenToMsgsender(changeAfterWithdraw);
    }

    function unstakeFromPool(uint256 amount) internal{
        IApeStakePool(StakePoolAddress).withdrawSelfApeCoin(amount);
    }

    function claimRewardFromPool() external onlyRewardDistributor returns(uint256){
        uint256 balanceBeforeclaim = IERC20(TokentoDeposit).balanceOf(address(this));
        IApeStakePool(StakePoolAddress).claimSelfApeCoin();
        uint256 balanceAfterclaim = IERC20(TokentoDeposit).balanceOf(address(this));
        uint256 changeAfterClaim = balanceAfterclaim.sub(balanceBeforeclaim);
        return changeAfterClaim;
    }

    function updateUserInfo(address user, uint256 amount, bool isDeposit) internal {
        if(isDeposit){
            //get UserID. If userID = 0, set userID + user
            uint256 userIDnow = userID[user];
            bool addNewUser = false;
            //get current amount of user
            if(userIDnow == 0){
                registerNewUser(user);
                addNewUser = true;
            }

            if(addNewUser){
                userIDnow = userID[user];
            }

            _proceedUpdate(userIDnow, amount, isDeposit);
        }
        else if(isDeposit == false){
            uint256 userIDnow = userID[user];
            require(userIDnow != 0, "User not registered");
            _proceedUpdate(userIDnow, amount, isDeposit);
        }
    }
    function _proceedUpdate(uint256 userIDnow, uint256 amount, bool isDeposit) internal{
        uint256 beforeUpdateBalance = userDepositInfo[userIDnow].DepositAmount;
        if(isDeposit){
            userDepositInfo[userIDnow].DepositAmount += amount;
            poolTVL += amount;
        }
        else if(isDeposit == false){
        require(amount<= userDepositInfo[userIDnow].DepositAmount, "Invalid amount");
        userDepositInfo[userIDnow].DepositAmount -= amount;
        poolTVL -= amount;
        }
        uint256 latestUpdatedBlock = userDepositInfo[userIDnow].Lastupdated;
        userDepositInfo[userIDnow].Lastupdated = block.timestamp;
        uint256 afterUpdateBalance = userDepositInfo[userIDnow].DepositAmount;
        uint256 currentEpoch = EpochResults.length.sub(1);
        EpochResult storage getEpochDetails = EpochResults[currentEpoch];
        uint256 endBlock = getEpochDetails.createdTimeStamp.add(getEpochDetails.duration);
        require(block.timestamp <= endBlock, "Contract is in the process of updating. Please wait for a while and try again");
        _updateBalanceChange(userIDnow,beforeUpdateBalance,afterUpdateBalance, currentEpoch);
        _updateAccumulatedTicket(userIDnow, beforeUpdateBalance, latestUpdatedBlock, currentEpoch);
        
    }
    function _updateAccumulatedTicket(uint256 userIDnow, uint256 beforeUpdateBalance, uint256 latestUpdatedBlock, uint256 currentEpoch) internal{
        //Get current Epoch info
        EpochResult memory epochInfo = EpochResults[currentEpoch];
        //nếu latestUpdatedBlock nằm trong range currentEpoch -> lấy từ latestUpdatedBlock
        //Nếu latestUpdatedBlock nằm dưới start date -> Lấy từ startBlock
        uint256 epochStartBlock = epochInfo.createdTimeStamp;
        //uint256 epochDuration = epochInfo.duration;
        uint256 epochEndBlock = epochInfo.duration.add(epochStartBlock);
        
        uint256 range;
        if(latestUpdatedBlock<epochStartBlock){
            range = block.timestamp.sub(epochStartBlock);
        }
        else if(latestUpdatedBlock >= epochStartBlock && latestUpdatedBlock<= epochEndBlock){
            range = block.timestamp.sub(latestUpdatedBlock);
        }
        uint256 accumulatedAmount = range.mul(beforeUpdateBalance);
        accumulatedTicket[currentEpoch][userIDnow] += accumulatedAmount;
    }
    function _updateBalanceChange(uint256 userIDnow, uint256 beforeUpdateBalance, uint256 afterUpdateBalance, uint256 currentEpoch) internal{
        changeHistory[currentEpoch][userIDnow].changedwithinEpoch = true;
        changeHistory[currentEpoch][userIDnow].historyArray.push(
        ChangeArray(
        {
            oldAmount: beforeUpdateBalance,
            newAmount: afterUpdateBalance,
            updatedBlock: block.timestamp
        })
        );
        //accumulatedTicket[currentEpoch][userID] = beforeUpdateBalance * ;
    }
    function registerNewUser(address user) internal{
        amountOfUser += 1;
        userID[user] = amountOfUser;
        uint256 newUserID = userID[user];
        userDepositInfo[newUserID].userAddress = user;
        userDepositInfo[newUserID].DepositAmount = 0;
        userDepositInfo[newUserID].registeredDate = block.timestamp;
        userDepositInfo[newUserID].Lastupdated = block.timestamp;
    }

    function getTokenFromMsgsender(uint256 amount) internal returns(uint256) {
        uint256 balanceBeforeDeposit = IERC20(TokentoDeposit).balanceOf(address(this));
        IERC20(TokentoDeposit).safeTransferFrom(msg.sender,address(this),amount);
        uint256 balanceAfterDeposit = IERC20(TokentoDeposit).balanceOf(address(this));
        uint256 changeAfterDeposit = balanceAfterDeposit.sub(balanceBeforeDeposit);
        return changeAfterDeposit;
    }
    function sendTokenToMsgsender(uint256 amount) internal{
        IERC20(TokentoDeposit).safeTransfer(msg.sender, amount);
    }
    function claimRewardsFor(address user) external onlyRouter nonReentrant contractStarted returns(uint256){
        uint256 rewardClaimable = claimableRewardData[user].claimable;
        require(rewardClaimable > 0, "No rewards to claim");
        claimableRewardData[user].claimable = 0;
        uint256 notclaimedLength = claimableRewardData[user].temporaryNotClaimedEpochArray.length;
        //claimableRewardData[winners[i]].temporaryNotClaimedEpochArray.push(epochNumber);
        for(uint i=0; i <notclaimedLength;i++){
            uint256 epochNumber = claimableRewardData[user].temporaryNotClaimedEpochArray[i];
            uint256 position = claimableRewardData[user].rewardHistoryArray[i].position;
            //bool epochClaimed;
            EpochResult storage result = EpochResults[epochNumber];
            if(position == 1){
                if(result.first.claimed == false){
                result.first.claimed = true;
                }
            }
            else if(position == 2){
                if(result.second.claimed == false){
                result.second.claimed = true;
                }
            }
            else if(position == 3){
                if(result.third.claimed == false){
                result.third.claimed = true;
                }
            }
        }

        delete claimableRewardData[user].temporaryNotClaimedEpochArray; //Reset array
        uint256 realizedRewardClaimable = sendRewardToRouter(rewardClaimable);        
        return realizedRewardClaimable;
        
    }


    function sendRewardToRouter(uint256 amount) internal returns(uint256){
        address router = IRoleRegistry(registryContract).getRouter();
        uint256 beforeTransfer = IERC20(TokentoDeposit).balanceOf(router);
        address reserve = IRoleRegistry(registryContract).getReserveAddress();
        IRewardReserve(reserve).transferReward(TokentoDeposit,amount,router);
        uint256 afterTransfer = IERC20(TokentoDeposit).balanceOf(router);
        uint256 changeAfterTransfer = afterTransfer.sub(beforeTransfer);
        return changeAfterTransfer;
    }
    
    function getPoolTVL() external view returns(uint256){
        uint256 result = poolTVL;
        return result;
    }
    function getCurrentEpochReward() external view returns(uint256){
        uint256 result = IApeStakePool(StakePoolAddress).pendingRewards(
            APE_COIN_POOL_ID,
            address(this),
            APE_COIN_TOKEN_ID
        );
        return result;
    }
    function getClaimable(address user) external view returns(uint256){
        uint256 result = claimableRewardData[user].claimable;
        return result;
    }
    function getWinningHistory(address user) external view returns(rewardHistory[] memory){
        rewardHistory[] memory result = claimableRewardData[user].rewardHistoryArray;
        return result;
    }
    function getBalanceChangeHistory(address user, uint256 epochNumber) external view contractStarted validEpoch(epochNumber) returns(userChangeHistory memory) {
        uint256 userIDnow = userID[user];
        require(userIDnow != 0, "User hasn't registered");
        userChangeHistory memory result = changeHistory[epochNumber][userIDnow];
        return result;
        
    }
    function getUserID(address user) external view returns(uint256){
        uint256 result = userID[user];
        return result;
    }
    function getUserAmount() external view returns(uint256){
        uint256 result = amountOfUser;
        return result;
    }
    function getuserByID(uint256 userIDnow) external view returns(address){
        address result = userDepositInfo[userIDnow].userAddress;
        return result;
    }
    function getUserDepositInfo(address user) public view returns(userInfo memory){
        uint256 userIDnow = userID[user];
        userInfo memory result = userDepositInfo[userIDnow];
        return result;
    }
    function getAccumulatedTicketwithoutDecimal(uint256 epochNumber, address user) public view contractStarted validEpoch(epochNumber)returns(uint256){
        uint256 userIDnow = userID[user];
        require(userIDnow !=0, "User hasn't registered");
        uint256 result = accumulatedTicket[epochNumber][userIDnow];
        return result;
    }
    function getTicketAmount(uint256 epochNumber, address user) external view returns(uint256){
        uint256 result;
        uint256 PeriodTicketofUser;
        uint256 accumulatedTicketnow = accumulatedTicket[epochNumber][userID[user]];
        //uint256 accumulatedTicket = getAccumulatedTicketwithoutDecimal(epochNumber, user);
        EpochResult memory epochInfo = EpochResults[epochNumber];
        uint256 epochEndBlock = epochInfo.duration.add(epochInfo.createdTimeStamp);
        uint256 userIDnow = userID[user];
        require(userIDnow !=0, "User hasn't registered");
        uint256 userLatestUpdateTimeStamp = userDepositInfo[userIDnow].Lastupdated;
        uint256 userDepositAmount = userDepositInfo[userIDnow].DepositAmount;
        require(userDepositInfo[userIDnow].registeredDate < epochEndBlock, "User has not participated in the epoch");
        //changeHistory[epochNumber][userIDnow]
        //userChangeHistory memory getUserBalanceChangeHistory = getBalanceChangeHistory(user, epochNumber);
        userChangeHistory memory getUserBalanceChangeHistory = changeHistory[epochNumber][userIDnow];
        if(block.timestamp >= epochInfo.createdTimeStamp && block.timestamp <= epochEndBlock){
            if(userLatestUpdateTimeStamp >= epochInfo.createdTimeStamp && userLatestUpdateTimeStamp <= epochEndBlock){
                PeriodTicketofUser =  (block.timestamp.sub(userLatestUpdateTimeStamp)).mul(userDepositAmount);
            }
            else if(userLatestUpdateTimeStamp < epochInfo.createdTimeStamp){
                PeriodTicketofUser =  (block.timestamp.sub(epochInfo.createdTimeStamp)).mul(userDepositAmount);
            }
            result = (accumulatedTicketnow.add(PeriodTicketofUser)).div((10**TICKET_DECIMAL));
            return result;
        }
        else if(block.timestamp > epochEndBlock){ 
            if(userLatestUpdateTimeStamp<epochInfo.createdTimeStamp){
                result = (epochDuration.mul(userDepositAmount)).div((10**TICKET_DECIMAL));
                return result;
            }
            else{
                if(getUserBalanceChangeHistory.changedwithinEpoch){ 
                uint256 historyLatest = getUserBalanceChangeHistory.historyArray.length.sub(1);
                uint256 latestBlockupdated = getUserBalanceChangeHistory.historyArray[historyLatest].updatedBlock;
                uint256 notAccumulated = (epochEndBlock.sub(latestBlockupdated)).mul(getUserBalanceChangeHistory.historyArray[historyLatest].newAmount);
                result = (accumulatedTicketnow.add(notAccumulated)).div((10**TICKET_DECIMAL));
                return result;
            }
            else if(getUserBalanceChangeHistory.changedwithinEpoch == false){ 
                uint256 epochvar = epochNumber.sub(1);
                for(uint i=0;i<epochNumber;i++){
                    userChangeHistory memory getUserBalanceChangeHistoryVar = changeHistory[epochvar][userIDnow];
                    //userChangeHistory memory getUserBalanceChangeHistoryVar = getBalanceChangeHistory(user, epochvar);
                    if(getUserBalanceChangeHistoryVar.changedwithinEpoch){
                        uint256 historyLatest = getUserBalanceChangeHistoryVar.historyArray.length.sub(1);
                        uint256 notAccumulated = epochInfo.duration.mul(getUserBalanceChangeHistoryVar.historyArray[historyLatest].newAmount);
                        result = notAccumulated.div((10**TICKET_DECIMAL));
                        break;
                    }
                    epochvar -= 1;
                }
                return result;
            }
            }     
        }
            result = 0;
            return result;
    }
    function getTokenUsing() external view returns(address){
        return TokentoDeposit;
    }
    function getLatestEpoch() external view returns(uint256){
        uint256 length = EpochResults.length.sub(1);
        require(length > 0,"Contract not started");
        uint256 result = length.sub(1);
        return result;
    }
    /*function getEpochLength() public view returns(uint256){
        uint256 length = EpochResults.length;
        return length;
    }*/
    function getEpochInfo(uint256 epochNumber) external view returns(EpochResult memory){
        EpochResult memory result = EpochResults[epochNumber];
        return result;
    }
    function getRewardAllocationPercentage() external view returns(rewardAllocation memory){
        return AllocationPortion;
    } 
    function config(address token, uint256 decimal, uint256 duration) external onlyController{
        TokentoDeposit = token;
        TICKET_DECIMAL = decimal;
        epochDuration = duration;
        //minToDeposit = minAmount;
    }

    function setRewardRatio(uint256 firstP, uint256 secondP, uint256 thirdP, uint256 percentageSUM) external onlyController{
        require(firstP.add(secondP).add(thirdP) == percentageSUM);
        AllocationPortion.first = firstP;
        AllocationPortion.second = secondP;
        AllocationPortion.third = thirdP;
        PercentageDecimal = percentageSUM;
        emit rewardPortionUpdated(firstP, secondP, thirdP);
    }
    //function finalizeEpochTicketandParticipantInfo(uint256 epochNumber) external onlyRewardDistributor{
        //EpochResult storage getEpochDetails = EpochResults[epochNumber];
        //uint256 endBlock = getEpochDetails.createdTimeStamp.add(getEpochDetails.duration);
        //getEpochDetails.totalParticipant = sumUptotalParticipant(epochNumber, endBlock);
    //}
   function finalizeEpoch(uint256 epochNumber, address firstWinner, address secondWinner, address thirdWinner, uint256 totalPrize) external onlyRewardDistributor{

        require(userID[firstWinner] != 0, "User doesn't exist");
        require(userID[secondWinner] != 0, "User doesn't exist");
        require(userID[thirdWinner] != 0, "User doesn't exist");
        EpochResult storage getEpochDetails = EpochResults[epochNumber];
        bool isEpochFinalized = getEpochDetails.finalized;
        require(isEpochFinalized == false, "Epoch is done");
        uint256 endBlock = getEpochDetails.createdTimeStamp.add(getEpochDetails.duration);
        require(block.timestamp > endBlock, "Epoch isn't done");
        getEpochDetails.finalized = true;

        uint256 realizedReward = transferRewardToReserve(totalPrize);
        getEpochDetails.totalPrize = realizedReward;
        getEpochDetails.first.winner = firstWinner;
        getEpochDetails.first.prizeAmount = (realizedReward.mul(AllocationPortion.first)).div(PercentageDecimal);
        getEpochDetails.first.claimed = false;
        getEpochDetails.second.winner = secondWinner;
        getEpochDetails.second.prizeAmount = (realizedReward.mul(AllocationPortion.second)).div(PercentageDecimal);
        getEpochDetails.second.claimed = false;
        getEpochDetails.third.winner = thirdWinner;
        getEpochDetails.third.prizeAmount = (realizedReward.mul(AllocationPortion.third)).div(PercentageDecimal);
        getEpochDetails.third.claimed = false;
        address[] memory winners = new address[](3);
        winners[0] = firstWinner;
        winners[1] = secondWinner;
        winners[2] = thirdWinner;
        uint256[] memory PrizeinOrder = new uint256[](3);
        PrizeinOrder[0] = getEpochDetails.first.prizeAmount;
        PrizeinOrder[1] = getEpochDetails.second.prizeAmount;
        PrizeinOrder[2] = getEpochDetails.third.prizeAmount;
        setClaimableRewards(epochNumber,winners,PrizeinOrder);
    }

    function transferRewardToReserve(uint256 totalPrize) internal returns(uint256){
        address reserveAddress = IRoleRegistry(registryContract).getReserveAddress();
        uint256 beforeUpdateBalance = IERC20(TokentoDeposit).balanceOf(reserveAddress);
        IERC20(TokentoDeposit).safeTransfer(reserveAddress,totalPrize);
        uint256 afterUpdateBalance = IERC20(TokentoDeposit).balanceOf(reserveAddress);
        uint256 changeAfterUpdate = afterUpdateBalance.sub(beforeUpdateBalance);
        return changeAfterUpdate;
    }
    /*function sumUptotalParticipant(uint256 epochNumber, uint256 endBlock) internal view returns(uint256){
        uint256 amountofParticipant;
        for(uint i = 1; i<amountOfUser; i++){ 
            uint256 registeredBlock = userDepositInfo[i].registeredDate;
            address userAddress = userDepositInfo[i].userAddress;
            if(registeredBlock <= endBlock){
                uint256 userTicketAmount = getTicketAmount(epochNumber,userAddress);
                if(userTicketAmount>0){
                    amountofParticipant += 1;
                }
            }
        }
        return amountofParticipant;
    }*/
    function setClaimableRewards(uint256 epochNumber,address[] memory winners, uint256[] memory PrizeInOrder) internal{
        uint256 winnersLength = winners.length;
        for(uint i=0; i <winnersLength;i++){
            claimableRewardData[winners[i]].claimable += PrizeInOrder[i];
            claimableRewardData[winners[i]].rewardHistoryArray.push(
            rewardHistory(
                {
                EpochNumber: epochNumber,
                position: i.add(1),
                PrizeAmount: PrizeInOrder[i]
                })
            );
            claimableRewardData[winners[i]].temporaryNotClaimedEpochArray.push(epochNumber);
        }
    }
    function createNewEpoch() external onlyRewardDistributor{
        uint256 epochLength = EpochResults.length;
        if(epochLength > 0){
            uint256 latestEpochNumber =  epochLength.sub(1);
            EpochResult memory getLastEpochDetails = EpochResults[latestEpochNumber];
            bool lastEpochFinalized = getLastEpochDetails.finalized;
            require(lastEpochFinalized);
        }
        PrizeDetails memory empty;
        empty.winner = 0x0000000000000000000000000000000000000000;
        empty.claimed = false;
        empty.prizeAmount = 0;
        EpochResults.push(
        EpochResult(
        {
            first: empty,
            second: empty,
            third: empty,
            finalized: false,
            totalPrize: 0,
            duration: epochDuration,
            createdTimeStamp: block.timestamp
            
        })
        );
    }
    }