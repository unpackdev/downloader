// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.19;


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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: Coinlend.sol



pragma solidity 0.8.20;






/**
 * @title The Conlend DeFi contract
 * @author Jan Pumpe
 * @notice This contract is used for a decentralized lending platform
 */
contract Coinlend is ReentrancyGuard, Ownable {
    struct Loan {
        // Attributes of an loan
        uint256 id; // Unique identifier for loan
        address user; // Creator of loan
        address lender; // User who is lending
        address tokenLending; // Address of the token borrower receives
        uint256 tokenLendingAmount; // Amount to lend
        address tokenCollateral; // Address of token used as collateral
        uint256 tokenCollateralAmount; // Amount collateral
        uint256 interestRate; // Interest rate of the loan in basis points -> 5% = 500
        uint256 loanDuration; // The loan duration in days
        uint256 loanState; // The state of the loan (0 = OPEN, 1 = CANCELED, 2 = ACTIVE, 3 = COMPLETE)
        address borrower; // User who is borrowing
        uint256 timestamp; // Time when loan was created or taken
    }

    struct Transfer {
        uint256 id; // Unique identifier for deposit
        address user; // User who is lending
        address token; // Address of the token which is transferred
        uint256 tokenAmount; // Amount transferred
        uint256 transferType; // 0 -> Deposit, 1 -> Withdraw
        uint256 timestamp; // Time transfer was created
    }

    /* State variables */

    /**
     * Mapping of the exchange balances
     */
    mapping(address => mapping(address => uint256)) public tokens;

    /**
     * Mapping of all loans on the platform (id as key)
     */
    mapping(uint256 => Loan) public loans;

    /**
     * Store the fee percent for the loans so fee percent changes don't affect existing loans.
     * Separate mapping needed since loan struct is too big already.
     */
    mapping(uint256 => uint256) public loansFee;

    /**
     * Mapping of all deposits/withdrawals on the platform (id as key)
     */
    mapping(uint256 => Transfer) public transfers;

    /**
     * Mapping of pricefeeds for all supported tokens on the platform
     */
    mapping(address => AggregatorV3Interface) public priceFeeds;

    /**
     * Count of all loans on the platform -> used as ID
     */
    uint256 public loanCount = 1;

    /**
     * Count of all transfers on the platform -> used as ID
     */
    uint256 public transferCount = 1;

    /**
     * The address that receives all fee payments
     */
    address public feeAccount;

    /**
     * The fee charged for the interest generated on the platform in basis points: 5% -> 500
     */
    uint256 public feePercent;

    /**
     * The maximum LTV for new loans
     */
    uint256 public maxLTV;

    /**
     * The  maximum LTV for exiting loans. If LTV exceeds this threshold the lender can force liquidate loan
     */
    uint256 public ltvThreshold;

    /**
     * The time that needs to pass after loan expiration after which the lender can force liquidate the loan if it is not payed back
     */
    uint256 public expirationBuffer = 60 * 60 * 24 * 7; // 7 days

    /**
     * The address of the Coinlend Credits token
     */
    address public coinlendCredits;

    /**
     * Discount in percent for paying with Coinlend Credits
     */
    uint256 public coinlendCreditsDiscount;

    /* Events */

    event LoanListingCreated(
        // Attributes of an loan
        uint256 id, // Unique identifier for loan
        address user, // Creater of the loan
        address lender, // User who is lending
        address tokenLending, // Address of the token they receive
        uint256 tokenLendingAmount, // Amount to lend
        address borrower, // user who is borowwing
        address tokenCollateral, // Address of token for the collateral
        uint256 tokenCollateralAmount, // Amount collateral
        uint256 interestRate,
        uint256 loanDuration,
        uint256 loanState,
        uint256 timestamp // When loan was created
    );

    event LoanListingCancelled(
        // Attributes of an loan
        uint256 id, // Unique identifier for loan
        address user, // user that created event
        address lender, // User who is lending
        address tokenLending, // Address of the token they receive
        uint256 tokenLendingAmount, // Amount to lend
        address borrower,
        address tokenCollateral, // Address of token for the collateral
        uint256 tokenCollateralAmount, // Amount collateral
        uint256 interestRate,
        uint256 loanDuration,
        uint256 loanState,
        uint256 timestamp // When loan was created
    );

    event LoanTaken(
        // Attributes of an loan
        uint256 id, // Unique identifier for loan
        address user,
        address lender, // User who is lending
        address tokenLending, // Address of the token they receive
        uint256 tokenLendingAmount, // Amount to lend
        address borrower,
        address tokenCollateral, // Address of token for the collateral
        uint256 tokenCollateralAmount, // Amount collateral
        uint256 interestRate,
        uint256 loanDuration,
        uint256 loanState,
        uint256 timestamp // When loan was created
    );

    event LoanPayBack(
        // Attributes of an loan
        uint256 id, // Unique identifier for loan
        address user,
        address lender, // User who is lending
        address tokenLending, // Address of the token they receive
        uint256 tokenLendingAmount, // Amount to lend
        address borrower,
        address tokenCollateral, // Address of token for the collateral
        uint256 tokenCollateralAmount, // Amount collateral
        uint256 interestRate,
        uint256 loanDuration,
        uint256 interest,
        uint256 timestamp // When loan was created
    );

    event LoanOfferCancelled(address indexed loanProvider, uint256 loanId);

    event Deposit(uint256 id, address token, address user, uint256 amount, uint256 balance);

    event Withdraw(uint256 id, address token, address user, uint256 amount, uint256 balance);

    /* Functions */
    constructor(address initialOwner) ReentrancyGuard() Ownable(initialOwner) {
        feeAccount = msg.sender; // Deployer will receive fees by default
        feePercent = 500; // 5% default fee
        maxLTV = 80; // Maximum LTV = 80%
        ltvThreshold = 90; // Loans can be liquidated if LTV exceed 90%
    }

    /**
     * Deposit tokens to the platform
     * @param _token Address of the token to deposit
     * @param _amount Amount of token to deposit
     */
    function depositToken(address _token, uint256 _amount) public nonReentrant {
        // Only allow deposit of token with pricefeed (prevent deposit of fake token)
        require(getLatestPrice(_token) > 0);

        // Only allow valid amounts greater 0
        require(_amount > 0);

        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        // Transfer tokens to exchange
        SafeERC20.safeTransferFrom(
            IERC20(_token), // Pass the token contract address as the first parameter
            msg.sender, // Sender of the tokens
            address(this), // Recipient of the tokens
            _amount // Amount of tokens to transfer
        );

        // Special handling for deflationary tokens
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        uint256 balanceDiff = balanceAfter - balanceBefore;
        if (balanceDiff < _amount) {
            _amount = balanceDiff;
        }

        // Update user balance
        tokens[_token][msg.sender] = tokens[_token][msg.sender] + _amount;

        transfers[transferCount] = Transfer(
            transferCount,
            msg.sender,
            _token,
            _amount,
            0,
            block.timestamp
        );

        // Emit deposit event
        emit Deposit(transferCount, _token, msg.sender, _amount, tokens[_token][msg.sender]);

        transferCount++;
    }

    /**
     * Withdraw tokens from the platform
     * @param _token Address of the token to withdraw
     * @param _amount Amount of token to withdraw
     */
    function withdrawToken(address _token, uint256 _amount) public nonReentrant {
        // Ensure user has enough tokens to withdraw

        require(tokens[_token][msg.sender] >= _amount);

        // Transfer tokens to user
        SafeERC20.safeTransfer(
            IERC20(_token), // Pass the token contract address as the first parameter
            msg.sender, // Sender of the tokens
            _amount // Amount of tokens to transfer
        );

        // Update user balance
        tokens[_token][msg.sender] = tokens[_token][msg.sender] - _amount;

        transfers[transferCount] = Transfer(
            transferCount,
            msg.sender,
            _token,
            _amount,
            1,
            block.timestamp
        );

        // Emit withdraw event
        emit Withdraw(transferCount, _token, msg.sender, _amount, tokens[_token][msg.sender]);

        transferCount++;
    }

    function balanceOf(address _token, address _user) public view returns (uint256) {
        return tokens[_token][_user];
    }

    function createLoanLend(
        address _tokenLend,
        uint256 _tokenLendAmount,
        address _tokenCollateral,
        uint256 _interestRate, // Interest in basis points: 12% -> 1200
        uint256 _loanDuration,
        uint256 _ltv
    ) public nonReentrant {
        require(_ltv > 0 && _ltv <= maxLTV);
        require(_interestRate >= 1 && _interestRate <= 10000); // Interest in basis points: 0,01% - 100%
        require(_tokenLendAmount > 0);
        require(_loanDuration > 0 && _loanDuration < 3650);

        require(balanceOf(_tokenLend, msg.sender) >= _tokenLendAmount);

        uint256 tokenCollateralAmount = (_tokenLendAmount * 100 * getLatestPrice(_tokenLend)) /
            _ltv /
            getLatestPrice(_tokenCollateral);

        tokens[_tokenLend][msg.sender] -= _tokenLendAmount;

        createLoanInternal(
            msg.sender, // loan creator
            msg.sender,
            _tokenLend,
            _tokenLendAmount,
            address(0),
            _tokenCollateral,
            tokenCollateralAmount,
            _interestRate,
            _loanDuration
        );
    }

    function createLoanBorrow(
        address _tokenLend,
        uint256 _tokenLendAmount,
        address _tokenCollateral,
        uint256 _interestRate,
        uint256 _loanDuration,
        uint256 _ltv
    ) public nonReentrant {
        require(_ltv > 0 && _ltv <= maxLTV);
        require(_interestRate >= 1 && _interestRate <= 10000); // Interest in basis points: 0,01% - 100%
        require(_tokenLendAmount > 0);
        require(_loanDuration > 0 && _loanDuration < 3650);

        uint256 tokenCollateralAmount = (_tokenLendAmount * 100 * getLatestPrice(_tokenLend)) /
            _ltv /
            getLatestPrice(_tokenCollateral);

        require(balanceOf(_tokenCollateral, msg.sender) >= tokenCollateralAmount);

        tokens[_tokenCollateral][msg.sender] -= tokenCollateralAmount;

        createLoanInternal(
            msg.sender, // loan creator
            address(0),
            _tokenLend,
            _tokenLendAmount,
            msg.sender,
            _tokenCollateral,
            tokenCollateralAmount,
            _interestRate,
            _loanDuration
        );
    }

    function createLoanInternal(
        address _user,
        address _lender,
        address _tokenLending,
        uint256 _tokenLendingAmount,
        address _borrower,
        address _tokenCollateral,
        uint256 _tokenCollateralAmount, // Amount collateral
        uint256 _interestRate, // Interest in basis points: 12% -> 1200
        uint256 _loanDuration
    ) internal {
        loans[loanCount] = Loan(
            loanCount,
            _user,
            _lender,
            _tokenLending,
            _tokenLendingAmount,
            _tokenCollateral,
            _tokenCollateralAmount,
            _interestRate,
            _loanDuration,
            0,
            _borrower,
            block.timestamp
        );

        loansFee[loanCount] = feePercent;
        // Emit event
        emit LoanListingCreated(
            loanCount,
            _user, // loan creator
            _lender,
            _tokenLending,
            _tokenLendingAmount,
            _borrower,
            _tokenCollateral,
            _tokenCollateralAmount,
            _interestRate,
            _loanDuration,
            0,
            block.timestamp
        );

        loanCount++;
    }

    function cancelLoan(uint256 _id) public nonReentrant {
        // Fetch loan
        Loan storage _loan = loans[_id];

        // Ensure the caller of the function is the owner of the loan
        require(address(_loan.user) == msg.sender);

        // Ensue the loan is in state open
        require(_loan.loanState == 0);

        // Update loan state
        _loan.loanState = 1;

        if (_loan.borrower == address(0)) {
            tokens[_loan.tokenLending][_loan.lender] += _loan.tokenLendingAmount;
        } else if (_loan.lender == address(0)) {
            tokens[_loan.tokenCollateral][_loan.borrower] += _loan.tokenCollateralAmount;
        }

        // Emit event
        emit LoanListingCancelled(
            _loan.id,
            msg.sender,
            _loan.lender,
            _loan.tokenLending,
            _loan.tokenLendingAmount,
            _loan.borrower,
            _loan.tokenCollateral,
            _loan.tokenCollateralAmount,
            _loan.interestRate,
            _loan.loanDuration,
            1,
            block.timestamp
        );
    }

    function takeLoan(uint256 _id) public nonReentrant {
        // Fetch loan
        Loan storage _loan = loans[_id];

        // Loan must exist
        require(_loan.id == _id);

        // Check loan state: Only open loans can be taken
        require(_loan.loanState == 0);

        // If user takes a lending offer -> check if he has enough collateral
        if (_loan.borrower == address(0)) {
            require(balanceOf(_loan.tokenCollateral, msg.sender) >= _loan.tokenCollateralAmount);
        }

        // If user provides funds for a borrow offer -> check if he has enough funds to lend
        if (_loan.lender == address(0)) {
            require(balanceOf(_loan.tokenLending, msg.sender) >= _loan.tokenLendingAmount);
        }

        _loan.loanState = 2;
        _loan.timestamp = block.timestamp;

        // Transfer tokens
        if (_loan.borrower == address(0)) {
            // Borrower takes a loan: Transfer lending amount to him and transfer collateral to contract

            // Transfer away collateral from borrower
            tokens[_loan.tokenCollateral][msg.sender] -= _loan.tokenCollateralAmount;

            // Transfer borrowed coins to borrower
            tokens[_loan.tokenLending][msg.sender] += _loan.tokenLendingAmount;

            _loan.borrower = msg.sender;
        } else if (_loan.lender == address(0)) {
            // Lender takes borrowing offer
            // Transfer borrowed coins to borrower
            tokens[_loan.tokenLending][_loan.borrower] += _loan.tokenLendingAmount;

            // Subtract borrowed coins from lender
            tokens[_loan.tokenLending][msg.sender] -= _loan.tokenLendingAmount;

            _loan.lender = msg.sender;
        }

        // Emit event
        emit LoanTaken(
            _loan.id,
            msg.sender,
            _loan.lender,
            _loan.tokenLending,
            _loan.tokenLendingAmount,
            _loan.borrower,
            _loan.tokenCollateral,
            _loan.tokenCollateralAmount,
            _loan.interestRate,
            _loan.loanDuration,
            2,
            block.timestamp
        );
    }

    function payBackLoan(uint256 _id) public nonReentrant {
        // Fetch loan
        Loan storage _loan = loans[_id];

        // Ensure the caller of the function is the owner of the loan
        require(address(_loan.borrower) == msg.sender);

        // Only active loans can be paid back
        require(_loan.loanState == 2);

        _loan.loanState = 3;

        // Calculate interest
        uint256 interestAmount = calculateInterest(
            _loan.tokenLendingAmount,
            _loan.interestRate,
            _loan.timestamp,
            block.timestamp
        );

        uint256 fee = calculateFee(interestAmount, loansFee[_id]);

        // Check if borrower has enough funds for payback
        require(hasBorrowerEnoughFundsForPayback(_loan, interestAmount));

        payBackLoanInternal(_loan, interestAmount, fee);
    }

    function payBackLoanInternal(Loan memory _loan, uint256 _interestAmount, uint256 _fee) private {
        uint256 feeValue = (((_fee * getLatestPrice(_loan.tokenLending)) /
            (10 ** (ERC20(_loan.tokenLending).decimals()))) * (100 - coinlendCreditsDiscount)) /
            100;
        // Transfer fee to fee account
        bool senderHasEnoughCredits = senderHasEnoughCoinlendCredits(feeValue);

        if (senderHasEnoughCredits) {
            tokens[coinlendCredits][feeAccount] += feeValue;
        } else {
            tokens[_loan.tokenLending][feeAccount] += _fee;
        }

        uint256 interestAmountMinusFee = _interestAmount - _fee;

        // Payback borrowed token to lender
        tokens[_loan.tokenLending][_loan.lender] +=
            _loan.tokenLendingAmount +
            interestAmountMinusFee;

        if (senderHasEnoughCredits) {
            tokens[coinlendCredits][_loan.borrower] -= feeValue;
            // substract lending amount and interest from borrower balance
            tokens[_loan.tokenLending][_loan.borrower] -= (_loan.tokenLendingAmount +
                interestAmountMinusFee);
        } else {
            // substract lending amount and interest from borrower balance
            tokens[_loan.tokenLending][_loan.borrower] -= (_loan.tokenLendingAmount +
                _interestAmount);
        }

        // Payback collateral
        tokens[_loan.tokenCollateral][_loan.borrower] += _loan.tokenCollateralAmount;

        // Emit event
        emit LoanPayBack(
            _loan.id,
            msg.sender,
            _loan.lender,
            _loan.tokenLending,
            _loan.tokenLendingAmount,
            _loan.borrower,
            _loan.tokenCollateral,
            _loan.tokenCollateralAmount,
            _loan.interestRate,
            _loan.loanDuration,
            interestAmountMinusFee,
            block.timestamp
        );
    }

    function hasBorrowerEnoughFundsForPayback(
        Loan memory _loan,
        uint256 _interestAmount
    ) internal view returns (bool) {
        return
            tokens[_loan.tokenLending][_loan.borrower] >=
            _loan.tokenLendingAmount + _interestAmount;
    }

    function senderHasEnoughCoinlendCredits(uint256 _feeValue) internal view returns (bool) {
        return balanceOf(coinlendCredits, msg.sender) >= _feeValue;
    }

    function calculateInterest(
        uint256 _tokenLendingAmount,
        uint256 _interestRate,
        uint256 _startTime,
        uint256 _endTime
    ) internal pure returns (uint256) {
        // End time needs to be bigger than the start time
        require(_endTime > _startTime);
        uint256 interestAmount = (((_tokenLendingAmount * _interestRate) *
            (_endTime - _startTime)) /
            365 /
            24 /
            60 /
            60 /
            10000);

        return interestAmount;
    }

    function calculateFee(
        uint256 _interestAmount,
        uint256 _feePercent
    ) internal pure returns (uint256) {
        return (_interestAmount * _feePercent) / 10000;
    }

    function forceLiquidateExpiredLoan(uint256 _id) public nonReentrant {
        // Fetch loan
        Loan storage _loan = loans[_id];

        // Ensure the caller of the function is the lender of the loan
        require(address(_loan.lender) == msg.sender);

        // Check loan state
        require(_loan.loanState == 2);

        // check loan is expired + buffer
        // Only loans which are expired the loan duration plus buffer can be liquidated
        require(_loan.timestamp + _loan.loanDuration + expirationBuffer < block.timestamp);

        // If borrower has enough of borrowed currency + fee -> payback lender and return collateral
        uint256 interestAmount = calculateInterest(
            _loan.tokenLendingAmount,
            _loan.interestRate,
            _loan.timestamp,
            block.timestamp
        );

        uint256 fee = calculateFee(interestAmount, loansFee[_id]);

        // Check if borrower has enough funds for payback
        if (hasBorrowerEnoughFundsForPayback(_loan, interestAmount)) {
            payBackLoanInternal(_loan, interestAmount, fee);
        } else {
            // If borrower has not enough of borrowed currency + fee -> move ownership of collateral to lender
            tokens[_loan.tokenCollateral][_loan.lender] += _loan.tokenCollateralAmount;

            // Emit event
            emit LoanPayBack(
                _loan.id,
                msg.sender,
                _loan.lender,
                _loan.tokenLending,
                _loan.tokenLendingAmount,
                _loan.borrower,
                _loan.tokenCollateral,
                _loan.tokenCollateralAmount,
                _loan.interestRate,
                _loan.loanDuration,
                interestAmount - fee,
                block.timestamp
            );
        }

        _loan.loanState = 3;
    }

    function forceLiquidateMarginExceeded(uint256 _id) public nonReentrant {
        // Fetch loan
        Loan storage _loan = loans[_id];

        // Ensure the caller of the function is the lender of the loan
        require(address(_loan.lender) == msg.sender);

        // Check loan state
        require(_loan.loanState == 2);

        uint256 ltv = calculateLTV(_loan);

        // Loan can not be liquiditated since ltv threshold was not exeeded yet
        require(ltv > ltvThreshold);

        // If borrower has enough of borrowed currency + fee -> payback lender and return collateral
        uint256 interestAmount = calculateInterest(
            _loan.tokenLendingAmount,
            _loan.interestRate,
            _loan.timestamp,
            block.timestamp
        );

        uint256 fee = calculateFee(interestAmount, loansFee[_id]);

        // Check if borrower has enough funds for payback
        if (hasBorrowerEnoughFundsForPayback(_loan, interestAmount)) {
            payBackLoanInternal(_loan, interestAmount, fee);
        } else {
            // If borrower has not enough of borrowed currency + fee -> move ownership of collateral to lender
            tokens[_loan.tokenCollateral][_loan.lender] += _loan.tokenCollateralAmount;

            // Emit event
            emit LoanPayBack(
                _loan.id,
                msg.sender,
                _loan.lender,
                _loan.tokenLending,
                _loan.tokenLendingAmount,
                _loan.borrower,
                _loan.tokenCollateral,
                _loan.tokenCollateralAmount,
                _loan.interestRate,
                _loan.loanDuration,
                interestAmount - fee,
                block.timestamp
            );
        }

        _loan.loanState = 3;
    }

    /**
     *  Increase the collateral amount of the loan for the given loan ID
     */
    function increaseCollateral(uint256 _id, uint256 _amount) public nonReentrant {
        // Fetch loan
        Loan storage _loan = loans[_id];

        // Ensure the caller of the function is the borrower of the loan
        require(address(_loan.borrower) == msg.sender);

        // Check loan state
        require(_loan.loanState == 2);

        // check if borrower has enough funds to increase collateral
        require(tokens[_loan.tokenCollateral][msg.sender] >= _amount);

        tokens[_loan.tokenCollateral][_loan.borrower] -= _amount;

        _loan.tokenCollateralAmount += _amount;
    }

    /**
     * Returns the latest price adjusted for the decimals of the token
     */
    function getLatestPrice(address _currencyAddress) public view returns (uint256) {
        (uint80 roundID, int price, , uint256 timeStamp, uint80 answeredInRound) = priceFeeds[
            _currencyAddress
        ].latestRoundData();

        uint256 decimalsFeed = priceFeeds[_currencyAddress].decimals();
        // Validate price feed data
        require(price > 0 && answeredInRound >= roundID && timeStamp != 0);

        return uint256(price) * 10 ** (18 - decimalsFeed); // Price comes with variable decimals but we need 18
    }

    function calculateLTV(uint256 _loanId) internal view returns (uint256) {
        return calculateLTV(loans[_loanId]);
    }

    function calculateLTV(Loan memory _loan) internal view returns (uint256) {
        uint256 tokenLendingTotalValue = (getLatestPrice(_loan.tokenLending) *
            _loan.tokenLendingAmount);

        uint256 tokenCollateralTotalValue = (getLatestPrice(_loan.tokenCollateral) *
            _loan.tokenCollateralAmount);

        return (tokenLendingTotalValue * 100) / tokenCollateralTotalValue;
    }

    function addPriceFeed(address _currencyAddress, address _priceFeedAddress) public onlyOwner {
        priceFeeds[_currencyAddress] = AggregatorV3Interface(_priceFeedAddress);
    }

    function setMaxLTV(uint256 _maxLTV) public onlyOwner {
        require(maxLTV > 0);
        maxLTV = _maxLTV;
    }

    function setFeeAccount(address _feeAccount) public onlyOwner {
        feeAccount = _feeAccount;
    }

    function setExpirationBuffer(uint256 _expirationBuffer) public onlyOwner {
        expirationBuffer = _expirationBuffer;
    }

    function setCoinlendCredits(address _coinlendCredits) public onlyOwner {
        coinlendCredits = _coinlendCredits;
    }

    function setFeePercent(uint256 _feePercent) public onlyOwner {
        require(_feePercent <= 3000); // limit fee to max 30%
        feePercent = _feePercent;
    }

    function setCoinlendCreditsDiscount(uint256 _coinlendCreditsDiscount) public onlyOwner {
        coinlendCreditsDiscount = _coinlendCreditsDiscount;
    }
}