// Sources flattened with hardhat v2.19.1 https://hardhat.org

// SPDX-License-Identifier: MIT

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


// File @openzeppelin/contracts/access/Ownable.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/Address.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/utils/cryptography/MerkleProof.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/structs/EnumerableSet.sol@v4.9.3

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


// File contracts/interfaces/IPhysicsStaking.sol

// Original license: SPDX_License_Identifier: MIT

pragma solidity 0.8.19;

interface IPhysicsStaking {
    function users(
        address account
    )
        external
        view
        returns (
            uint112 withdrawableTokens,
            uint112 baseTokensStaked,
            uint112 holderUnlockTime,
            uint48 stakingDuration,
            bool blacklisted
        );
}


// File contracts/ico/PhysicsIco.sol

pragma solidity ^0.8.0;

// Original license: SPDX_License_Identifier: MIT






contract PhysicsIco is Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    enum ClaimOption {
        FULL, // Users can claim 100% tokens at first
        HALF // Users can claim 50% tokens at first, and then 50% after 24 hours
    }

    enum ContributeOption {
        HOLDING, // contributable because the account has token holdings
        STAKING // contributable because the account has token staked
    }

    struct IcoConf {
        ClaimOption claimOption;
        address treasury; // Address where the accumulated funds will be received.
        address icoToken; // Token to be listed
        address physicsToken; // Physics token
        address physicsStaking; // Physics staking
        string icoTokenSymbol; // Ico token symbol. It is needed on the FE side before ico token is configured
        uint256 startDate; // Ico start dte
        uint256 endDate; // Ico end date
        uint256 hardcap; // Hardcap in ETH
        bytes32 optMerkleRoot; // Merkle root for the contribution criteria
        bool isClaimEnabled; // The flag if the claim is enabled for the ICO
    }

    struct IcoStats {
        uint256 accumedFunds; // Total accumlated ETH amount by the users' contribution
        /**
         * _filledTokens = _toDistTokens + [amount to distributed to the blocked accounts]
         */
        uint256 filledTokens; // Total filled ICO token amount
        uint256 toDistTokens; // Total ICO token amount to be distributed
        uint256 claimedTokens; // Total claimed tokens amount
        bool isFundsClaimed; // The flag is that the accumulated funds were withdrawn.
    }

    struct UserData {
        uint256 contribAmtWithHoldOpt; // User contributed funds amount with holding option
        uint256 contribAmtWithStakeOpt; // User contributed funds amount with staking option
        uint256 disAmtWithHoldOpt; // ICO token amount to be received for the holding option contribution
        uint256 disAmtWithStakeOpt; // ICO token amount to be received for the staking option contribution
        uint256 firstClaimedAt; // First claimed time
        bool claimed; // User claimed tokens or not
    }

    uint256 private constant CLAIM_INTERVAL = 24 hours;

    /// @dev Last ico id
    uint256 private _lastIcoId;

    /// @dev Flag to show if any ico is opened or not
    bool private _icoOpened;

    /// @dev Ico configuration data
    mapping(uint256 => IcoConf) private _icoConfData;
    /// @dev Ico live stats data
    mapping(uint256 => IcoStats) private _icoStatsData;
    /// @notice User contribution data for the ico
    /// @dev Key is the hash value of user address & ico id
    mapping(bytes32 => UserData) private _userData;
    /// @notice Claim blacklist
    /// @dev Key is the hash value of user address & ico id
    mapping(bytes32 => bool) private _blacklist;

    event AccountBlacklisted(uint256 icoId, address account, bool blacklisted);
    event Claimed(uint256 icoId, address account, uint256 amount);
    event Contributed(
        uint256 icoId,
        address account,
        ContributeOption option,
        uint256 fundAmount,
        uint256 tokenAmount
    );
    event Finalized(uint256 icoId);
    event HardcapUpdated(uint256 icoId, uint256 hardcap);
    event IcoOpened(uint256 icoId);
    event IcoTrunedOff();

    function openNewIco(
        ClaimOption option_,
        address treasury_,
        address physicsToken_,
        address physicsStaking_,
        string calldata icoTokenSymbol_,
        uint256 startDate_,
        uint256 endDate_,
        uint256 hardcap_,
        bytes32 optMerkleRoot_
    ) external onlyOwner {
        require(treasury_ != address(0), "invalid treasury");
        IPhysicsStaking(physicsStaking_).users(address(0)); // To check the Physics staking contract
        IERC20(physicsToken_).balanceOf(address(this)); // To check the IERC20 contract
        require(!_icoOpened, "close opened ico");
        require(block.timestamp < startDate_, "must be future time");
        require(startDate_ < endDate_, "startDate must before endDate");

        IcoConf memory conf = IcoConf({
            claimOption: option_,
            treasury: treasury_,
            physicsToken: physicsToken_,
            physicsStaking: physicsStaking_,
            icoTokenSymbol: icoTokenSymbol_,
            startDate: startDate_,
            endDate: endDate_,
            hardcap: hardcap_,
            optMerkleRoot: optMerkleRoot_,
            icoToken: address(0),
            isClaimEnabled: false
        });
        uint256 icoId = _lastIcoId;
        ++icoId;
        _lastIcoId = icoId;
        _icoConfData[icoId] = conf;
        _icoOpened = true;

        emit IcoOpened(icoId);
    }

    /// @notice Contribute in the ICO
    /// @dev Holding option or Staking option are available
    /// @param option_ One of contribution options: holding or staking
    /// @param icoId_ Current opened ico
    /// @param crtAmt_ Criteria amount (this can be holding criteria amount or staking criteria amount)
    /// @param crtPeriod_ Criteria period (use only for the staking option. default 0 for the holding option)
    /// @param maxFundAmt_ Max contributable funds amount with the option and the criteria
    /// @param fundAmt_ Current contribution fund amount
    /// @param tokenAmt_ ICO token amount to be received from the current contribution
    /// @param proof_ Proof data to validate the given parameters by using merkle root
    function contribute(
        ContributeOption option_,
        uint256 icoId_,
        uint256 crtAmt_,
        uint256 crtPeriod_,
        uint256 maxFundAmt_,
        uint256 fundAmt_,
        uint256 tokenAmt_,
        bytes32[] calldata proof_
    ) external payable {
        address caller = _msgSender();
        bytes32 key = _hash2(icoId_, caller);
        IcoStats storage icoStats = _icoStatsData[icoId_];
        IcoConf memory icoConf = _icoConfData[icoId_];
        require(
            block.timestamp >= icoConf.startDate &&
                block.timestamp < icoConf.endDate,
            "ico not opened"
        );
        require(msg.value >= fundAmt_, "less funds");

        require(
            MerkleProof.verify(
                proof_,
                icoConf.optMerkleRoot,
                keccak256(
                    bytes.concat(
                        keccak256(
                            abi.encodePacked(
                                option_,
                                crtAmt_,
                                crtPeriod_,
                                maxFundAmt_,
                                fundAmt_,
                                tokenAmt_
                            )
                        )
                    )
                )
            ),
            "proof failed"
        );

        _validateCriteria(
            option_,
            icoConf.physicsToken,
            icoConf.physicsStaking,
            crtAmt_,
            crtPeriod_
        );
        _validateContribLimit(
            icoId_,
            option_,
            maxFundAmt_,
            fundAmt_,
            tokenAmt_
        );

        icoStats.accumedFunds += fundAmt_;
        icoStats.filledTokens += tokenAmt_;
        // The distributable token amount only accumulates when the account is not blacklisted.
        if (!_blacklist[key]) icoStats.toDistTokens += tokenAmt_;

        require(icoStats.accumedFunds <= icoConf.hardcap, "reached hardcap");

        emit Contributed(icoId_, caller, option_, fundAmt_, tokenAmt_);
    }

    /// @notice Validate whether the account is eligible for the ICO using the provided option.
    /// @dev ContributeOption.HOLDING checks the hold amount of Physics token
    /// @dev ContributeOption.STAKING checks the staked amount and duration in the Physics staking contract
    function _validateCriteria(
        ContributeOption option_,
        address physicsToken_,
        address physicsStaking_,
        uint256 crtAmt_,
        uint256 crtPeriod_
    ) internal view {
        address caller = _msgSender();
        if (option_ == ContributeOption.HOLDING) {
            uint256 holdingBalance = IERC20Metadata(physicsToken_).balanceOf(
                caller
            );
            require(holdingBalance >= crtAmt_, "unmeet holding criteria");
        } else {
            (
                uint256 withdrawableTokens,
                ,
                ,
                uint48 stakingDuration,
                bool blacklisted
            ) = IPhysicsStaking(physicsStaking_).users(caller);
            require(
                !blacklisted &&
                    withdrawableTokens >= crtAmt_ &&
                    stakingDuration >= crtPeriod_,
                "unmeet staking criteria"
            );
        }
    }

    /// @notice Validate the contribution limit when using the provided option.
    function _validateContribLimit(
        uint256 icoId_,
        ContributeOption option_,
        uint256 maxFundAmt_,
        uint256 fundAmt_,
        uint256 tokenAmt_
    ) internal {
        bytes32 key = _hash2(icoId_, _msgSender());
        UserData storage userData = _userData[key];
        if (option_ == ContributeOption.HOLDING) {
            uint256 contribAmtWithHoldOpt_ = userData.contribAmtWithHoldOpt +
                fundAmt_;
            require(
                contribAmtWithHoldOpt_ <= maxFundAmt_,
                "hold opt contribution limit"
            );
            userData.contribAmtWithHoldOpt = contribAmtWithHoldOpt_;
            userData.disAmtWithHoldOpt += tokenAmt_;
        } else {
            uint256 contribAmtWithStakeOpt_ = userData.contribAmtWithStakeOpt +
                fundAmt_;
            require(
                contribAmtWithStakeOpt_ <= maxFundAmt_,
                "stake opt contribution limit"
            );
            userData.contribAmtWithStakeOpt = contribAmtWithStakeOpt_;
            userData.disAmtWithStakeOpt += tokenAmt_;
        }
    }

    /// @notice Claim ICO tokens for the contributions already made.
    /// @dev There are two types of ICO. One offers a 100% claim, while the other offers a 50% / 50% claim.
    /// In the case of the second option, users can only claim the second 50% after 24 hours from the first claim.
    function claimTokens(uint256 icoId_) external {
        address caller = _msgSender();
        bytes32 key = _hash2(icoId_, caller);
        IcoConf memory icoConf = _icoConfData[icoId_];
        require(icoConf.endDate < block.timestamp, "not finished");
        require(icoConf.isClaimEnabled, "claim disabled");

        UserData memory userData = _userData[key];
        require(!_blacklist[key], "blacklisted");
        require(!userData.claimed, "already claimed");

        uint256 claimableAmt = userData.disAmtWithHoldOpt +
            userData.disAmtWithStakeOpt;
        require(claimableAmt != 0, "nothing claimable");

        if (icoConf.claimOption == ClaimOption.FULL) {
            _userData[key].claimed = true;
        } else {
            claimableAmt /= 2;
            if (userData.firstClaimedAt > 0) {
                require(
                    block.timestamp >= userData.firstClaimedAt + CLAIM_INTERVAL,
                    "wait more"
                );
                _userData[key].claimed = true;
            }
        }

        IERC20(icoConf.icoToken).safeTransfer(caller, claimableAmt);
        _userData[key].firstClaimedAt = block.timestamp;
        _icoStatsData[icoId_].claimedTokens += claimableAmt;
        emit Claimed(icoId_, caller, claimableAmt);
    }

    /// @notice Finalize ICO when it was filled or by some reasons
    /// @dev Only owner can call this function
    /// @dev It should indicate the new claim date
    function finalizeIco(uint256 icoId_) external onlyOwner {
        IcoConf storage icoConf = _icoConfData[icoId_];
        require(
            block.timestamp > icoConf.startDate &&
                block.timestamp < icoConf.endDate,
            "ico not opened"
        );

        icoConf.endDate = block.timestamp;

        emit Finalized(icoId_);
    }

    /// @notice Turn ICO off
    /// @dev icoOpened flag turned to false
    function turnOffIco(uint256 icoId_) external onlyOwner {
        IcoConf storage icoConf = _icoConfData[icoId_];
        require(block.timestamp > icoConf.endDate, "ico not finished");
        require(_icoOpened, "already turned off");

        _icoOpened = false;

        emit IcoTrunedOff();
    }

    /// @notice Withdraw remained ICO tokens after ICO finished
    /// @dev Only owner can call this function
    function withdrawRemainedTokens(uint256 icoId_) external onlyOwner {
        IcoStats memory icoStats = _icoStatsData[icoId_];
        IcoConf memory icoConf = _icoConfData[icoId_];
        require(block.timestamp >= icoConf.endDate, "ico not finished");

        IERC20 icoToken = IERC20(icoConf.icoToken);
        uint256 contractTokens = icoToken.balanceOf(address(this)) +
            icoStats.claimedTokens;
        uint256 toDistTokens = icoStats.toDistTokens;
        require(contractTokens >= toDistTokens, "insufficient amount");

        icoToken.safeTransfer(_msgSender(), contractTokens - toDistTokens);
    }

    /// @notice Withdraw accumlated funds in the contract
    /// @dev Only owner can call this function
    function withdrawFunds(uint256 icoId_) external onlyOwner {
        IcoStats memory icoStats = _icoStatsData[icoId_];
        IcoConf memory icoConf = _icoConfData[icoId_];

        require(block.timestamp >= icoConf.endDate, "ico not finished");
        require(!icoStats.isFundsClaimed, "already withdrawn");
        uint256 accumendFunds = icoStats.accumedFunds;
        require(accumendFunds > 0, "nothing to withdraw");

        address payable treasury = payable(icoConf.treasury);
        treasury.sendValue(accumendFunds);

        _icoStatsData[icoId_].isFundsClaimed = true;
    }

    /// @notice Batch blacklist account or recover from the blacklist
    /// @dev Only owner can call this function
    function batchBlacklistAccount(
        uint256 icoId_,
        address[] calldata accounts_,
        bool flag_
    ) external onlyOwner {
        uint256 len = accounts_.length;
        for (uint256 i; i < len; ) {
            blacklistAccount(icoId_, accounts_[i], flag_);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Blacklist account or recover from the blacklist
    /// @dev Only owner can call this function
    function blacklistAccount(
        uint256 icoId_,
        address account_,
        bool flag_
    ) public onlyOwner {
        bytes32 key = _hash2(icoId_, account_);
        if (_blacklist[key] == flag_) return; // Nothing change for this conf
        _blacklist[key] = flag_;

        UserData memory userData = _userData[key];
        uint256 changeAmount = userData.disAmtWithHoldOpt +
            userData.disAmtWithStakeOpt;

        // When an account is blacklisted, the distributable token amount decreases.
        // When removed from the blacklist, the distributable token amount increases.
        if (flag_) _icoStatsData[icoId_].toDistTokens -= changeAmount;
        else _icoStatsData[icoId_].toDistTokens += changeAmount;

        emit AccountBlacklisted(icoId_, account_, flag_);
    }

    /// @notice Check if the provided account is blacklisted.
    function isBlacklisted(
        uint256 icoId_,
        address account_
    ) external view returns (bool) {
        bytes32 key = _hash2(icoId_, account_);
        return _blacklist[key];
    }

    /// @notice View the ico configuration data for the given ico id
    function viewIcoConf(
        uint256 icoId_
    ) external view returns (IcoConf memory) {
        return _icoConfData[icoId_];
    }

    /// @notice View the ico live stats data for the given ico id
    function viewIcoStats(
        uint256 icoId_
    ) external view returns (IcoStats memory) {
        return _icoStatsData[icoId_];
    }

    /// @notice Update ICO start / end / claim date
    /// @dev Only owner can call this function
    function updateIcoDates(
        uint256 icoId_,
        uint256 startDate_,
        uint256 endDate_
    ) external onlyOwner {
        IcoConf storage icoConf = _icoConfData[icoId_];
        require(block.timestamp < icoConf.startDate, "ico already started");
        require(block.timestamp < startDate_, "must be future time");
        require(startDate_ < endDate_, "startDate must before endDate");

        icoConf.startDate = startDate_;
        icoConf.endDate = endDate_;
    }

    /// @notice Enable claim for the ico
    /// @dev Only owner can call this function
    function enableIcoClaim(uint256 icoId_) external onlyOwner {
        IcoConf storage icoConf = _icoConfData[icoId_];
        require(icoConf.startDate > 0, "invalid ico id");
        require(icoConf.icoToken != address(0), "ico token not set");
        icoConf.isClaimEnabled = true;
    }

    /// @notice Update ico token
    /// @dev Only owner can call this function
    function updateIcoToken(
        uint256 icoId_,
        address icoToken_
    ) external onlyOwner {
        IcoConf storage icoConf = _icoConfData[icoId_];
        require(icoConf.startDate > 0, "invalid ico id");
        IERC20(icoToken_).balanceOf(address(this)); // To check the IERC20 contract
        icoConf.icoToken = icoToken_;
    }

    /// @notice Update ICO hardcap
    /// @dev Only owner can call this function
    function updateHardcap(
        uint256 icoId_,
        uint256 hardcap_
    ) external onlyOwner {
        require(
            hardcap_ >= _icoStatsData[icoId_].accumedFunds,
            "more accumlated"
        );
        _icoConfData[icoId_].hardcap = hardcap_;

        emit HardcapUpdated(icoId_, hardcap_);
    }

    /// @notice Update the contribute option merkle root
    /// @dev Only owner can call this function
    function updateOptMerkleRoot(
        uint256 icoId_,
        bytes32 merkleRoot_
    ) external onlyOwner {
        IcoConf storage icoConf = _icoConfData[icoId_];
        require(icoConf.optMerkleRoot != merkleRoot_, "nothing changed");

        icoConf.optMerkleRoot = merkleRoot_;
    }

    /// @notice View user contribution data
    function viewUserData(
        uint256 icoId_,
        address account_
    ) external view returns (UserData memory) {
        bytes32 key = _hash2(icoId_, account_);
        return _userData[key];
    }

    /// @notice View the last ico id
    function lastIcoId() external view returns (uint256) {
        return _lastIcoId;
    }

    /// @notice Get hash value from (address, uint256)
    function _hash2(
        uint256 param1_,
        address param2_
    ) private pure returns (bytes32) {
        return keccak256(abi.encode(param1_, param2_));
    }

    /// @notice It allows the admin to recover tokens sent to the contract
    /// @param token_: the address of the token to withdraw
    /// @param amount_: the number of tokens to withdraw
    /// @dev Only owner can call this function
    function recoverToken(address token_, uint256 amount_) external onlyOwner {
        IERC20(token_).safeTransfer(_msgSender(), amount_);
    }
}