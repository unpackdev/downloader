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

// File: newstaking.sol


pragma solidity ^0.8.20;





contract StakingContract is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public havocToken;
    uint256 public constant PERCENT_DIVIDER = 10000;

    bool public paused;
    uint256 public totalUsers;
    uint256 public penaltyPercent;
    uint256[3] public totalStakedUsers;
    uint256[3] public totalStakedAmount;
    uint256[3] public totalRewardAmount;
    uint256[3] public totalUnstakedAmount;

    uint256 public totalRewardCount;
    uint256 public totalPlan1RewardCount;
    uint256 public totalPlan2RewardCount;
    uint256[3] public lockDuration;
    mapping(uint256 => uint256) public totalAddedRewards; // plan => index => amount
    mapping(uint256 => uint256) public totalAddedPlan1Bonus; // plan => index => amount
    mapping(uint256 => uint256) public totalAddedPlan2Bonus; // plan => index => amount

    struct Stake {
        uint256 amount;
        uint256 endTime;
        uint256 startTime;
        uint256 unstakedAt;
        uint256 lastClaimedAt;
        uint256 lastClaimedCount;
        uint256 lastClaimedBonus1;
        uint256 lastClaimedBonus2;
    }

    struct User {
        uint256 totalAmountStaked;
        uint256 totalAmountUnstaked;
        uint256 totalStakesCount;
        uint256 lastClaimedBonus1;
        uint256 lastClaimedBonus2;
        uint256 prevRemainingBonus1;
        uint256 prevRemainingBonus2;
        uint256[3] stakeCounts;
        uint256[3] lastClaimedCount;
        uint256[3] lastUnstakedIndex;
        uint256[3] prevRemainingReward;
        mapping(uint256 => mapping(uint256 => Stake)) planStakes;
    }

    mapping(address => User) public userStakes;

    struct StakeDetail {
        uint256 totalUsers;
        uint256 totalAmount;
        uint256 addedAt;
    }

    mapping(uint256 => StakeDetail) public rewardStakeHistory;
    mapping(uint256 => StakeDetail) public plan1BonusHistory;
    mapping(uint256 => StakeDetail) public plan2BonusHistory;

    event STAKED(address user, uint256 amount, uint256 plan, uint256 at);
    event UNSTAKED(address user, uint256 amount, uint256 plan, uint256 at);
    event REWARD_CLAIMED(address user, uint256 amount, uint256 at);
    event REWARD_DEPOSITED(uint256 amount, uint256 index, uint256 at);

    modifier notPaused() {
        require(!paused, "Temporarily Paused");
        _;
    }

    constructor() Ownable(msg.sender) {
        havocToken = IERC20(0x9F94b198ce85C19A846C2B1a4D523f40A747a850);
        penaltyPercent = 500;
        lockDuration[0] = 30 days;
        lockDuration[1] = 60 days;
        lockDuration[2] = 90 days;
    }

    function stake(uint256 _plan, uint256 _amount) external {
        require(_plan < lockDuration.length, "Invalid plan");
        require(_amount != 0, "Amount must be greater than 0");

        User storage user = userStakes[msg.sender];
        // Update last Reward
        havocToken.safeTransferFrom(msg.sender, address(this), _amount);
        // uint256 _curReward = claimableReward(msg.sender, _plan);
        // user.prevRemainingReward[_plan] = _curReward;
        // userStakes[msg.sender].lastClaimedCount[_plan] = totalRewardCount;

        // update user
        user.totalStakesCount++;
        uint256 currentIndex = ++user.stakeCounts[_plan];
        Stake storage _currentStake = user.planStakes[_plan][currentIndex];
        _currentStake.amount = _amount;
        _currentStake.startTime = block.timestamp;
        _currentStake.endTime = block.timestamp + lockDuration[_plan];

        // update total staked info
        if (user.totalStakesCount == 1) {
            totalUsers++;
        }

        if (user.stakeCounts[_plan] == 1) {
            totalStakedUsers[_plan]++;
        }

        user.totalAmountStaked += _amount;
        totalStakedAmount[_plan] += _amount;

        emit STAKED(msg.sender, _amount, _plan, block.timestamp);
    }

    function unstakeUnlocked(
        uint256 _plan,
        uint256 _index
    ) external nonReentrant notPaused {
        User storage user = userStakes[msg.sender];
        require(
            user.stakeCounts[_plan] != 0 && _index <= user.stakeCounts[_plan],
            "Plan stakes not found!"
        );
        Stake storage stakeInfo = user.planStakes[_plan][_index];
        require(stakeInfo.unstakedAt == 0, "Already unstaked!");

        uint256 totalStakedHavocs = stakeInfo.amount;
        // Claim reward if available
        if (block.timestamp < stakeInfo.endTime) {
            stakeInfo.lastClaimedAt = block.timestamp;
            stakeInfo.lastClaimedCount = totalRewardCount;
            totalStakedHavocs -=
                (stakeInfo.amount * penaltyPercent) /
                PERCENT_DIVIDER;
        } else {
            _withdrawReward(msg.sender, _plan, _index);
        }

        stakeInfo.unstakedAt = block.timestamp;
        user.lastUnstakedIndex[_plan] = _index;
        havocToken.safeTransfer(msg.sender, totalStakedHavocs);

        // update total staked info
        user.totalAmountUnstaked += stakeInfo.amount;
        totalUnstakedAmount[_plan] += stakeInfo.amount;
        emit UNSTAKED(msg.sender, totalStakedHavocs, _plan, block.timestamp);
    }

    function claimReward(
        uint256 _plan,
        uint256 _index
    ) external nonReentrant notPaused {
        User storage user = userStakes[msg.sender];
        require(
            user.stakeCounts[_plan] != 0 && _index <= user.stakeCounts[_plan],
            "Stakes not found!"
        );

        uint256 rewardSent = _withdrawReward(msg.sender, _plan, _index);
        require(rewardSent != 0, "Nothing to withdraw!");
        emit REWARD_CLAIMED(msg.sender, rewardSent, block.timestamp);
    }

    function claimPlan1Bonus(uint256 _index) external nonReentrant notPaused {
        User storage user = userStakes[msg.sender];
        require(
            user.stakeCounts[1] != 0 && _index <= user.stakeCounts[1],
            "Stakes not found!"
        );

        uint256 rewardSent = _withdrawBonus(msg.sender, 1, _index);
        require(rewardSent != 0, "Nothing to withdraw!");
        emit REWARD_CLAIMED(msg.sender, rewardSent, block.timestamp);
    }

    function claimPlan2Bonus(uint256 _index) external nonReentrant notPaused {
        User storage user = userStakes[msg.sender];
        require(
            user.stakeCounts[2] != 0 && _index <= user.stakeCounts[2],
            "Stakes not found!"
        );

        uint256 rewardSent = _withdrawBonus(msg.sender, 2, _index);
        require(rewardSent != 0, "Nothing to withdraw!");
        emit REWARD_CLAIMED(msg.sender, rewardSent, block.timestamp);
    }

    function _withdrawReward(
        address _user,
        uint256 _plan,
        uint256 _index
    ) private returns (uint256 rewardAmount) {
        rewardAmount = claimableReward(_user, _plan, _index);

        userStakes[_user].prevRemainingReward[_plan] = 0;
        userStakes[_user].planStakes[_plan][_index].lastClaimedAt = block
            .timestamp;
        userStakes[_user]
        .planStakes[_plan][_index].lastClaimedCount = totalRewardCount;
        // update last claim
        if (rewardAmount != 0) {
            uint256 balance = address(this).balance;
            require(balance >= rewardAmount, "Insufficient reward in pool");

            payable(_user).transfer(rewardAmount);
            totalRewardAmount[_plan] += rewardAmount;
        }
    }

    function _withdrawBonus(
        address _user,
        uint256 _plan,
        uint256 _index
    ) private returns (uint256 rewardAmount) {
        require(_plan == 1 || _plan == 2, "Wrong plan");
        if (_plan == 1) {
            rewardAmount = claimablePlan1Bonus(_user, _index);
            userStakes[_user].prevRemainingBonus1 = 0;
            userStakes[_user]
            .planStakes[_plan][_index]
                .lastClaimedBonus1 = totalPlan1RewardCount;
        } else {
            rewardAmount = claimablePlan2Bonus(_user, _index);
            userStakes[_user].prevRemainingBonus2 = 0;
            userStakes[_user]
            .planStakes[_plan][_index]
                .lastClaimedBonus2 = totalPlan2RewardCount;
        }

        // update last claim
        if (rewardAmount != 0) {
            require(
                address(this).balance >= rewardAmount,
                "Insufficient reward in pool"
            );

            payable(_user).transfer(rewardAmount);
            totalRewardAmount[_plan] += rewardAmount;
        }
    }

    function claimableReward(
        address _user,
        uint256 _plan,
        uint256 _index
    ) public view returns (uint256) {
        User storage user = userStakes[_user];
        if (_index == 0 && _index > user.stakeCounts[_plan]) {
            return 0;
        }

        Stake storage userStake = user.planStakes[_plan][_index];
        uint256 stakedAmount = userStake.amount;
        if (stakedAmount == 0) {
            return 0;
        }
        uint256 totalReward;
        // Check if token is set as reward
        uint256 totalAddedRewardCount = totalRewardCount;
        uint256 lastUserClaimed = userStake.lastClaimedCount;
        for (uint256 k = lastUserClaimed + 1; k <= totalAddedRewardCount; k++) {
            uint256 totalAddedReward = totalAddedRewards[k];

            StakeDetail memory _detail = rewardStakeHistory[k];
            if (
                (_detail.addedAt > userStake.startTime &&
                    _detail.addedAt <= userStake.endTime) &&
                _detail.totalAmount != 0
            ) {
                uint256 _claimableReward;
                uint256 currentPercentage = (stakedAmount * PERCENT_DIVIDER) /
                    _detail.totalAmount;
                _claimableReward =
                    (totalAddedReward * currentPercentage) /
                    PERCENT_DIVIDER;

                totalReward += _claimableReward;
            }
        }
        // totalReward += user.prevRemainingReward[_plan];

        return totalReward;
    }

    function claimablePlan1Bonus(
        address _user,
        uint256 _index
    ) public view returns (uint256 totalReward) {
        User storage user = userStakes[_user];
        if (_index == 0 && _index > user.stakeCounts[1]) {
            return 0;
        }

        Stake storage userStake = user.planStakes[1][_index];
        uint256 stakedAmount = userStake.amount;

        // Check if token is set as reward
        uint256 totalAddedRewardCount = totalPlan1RewardCount;
        uint256 lastUserClaimed = userStake.lastClaimedBonus1;
        for (uint256 k = lastUserClaimed + 1; k <= totalAddedRewardCount; k++) {
            uint256 totalAddedReward = totalAddedPlan1Bonus[k];

            StakeDetail memory _detail = plan1BonusHistory[k];
            if (
                (_detail.addedAt > userStake.startTime &&
                    _detail.addedAt <= userStake.endTime) &&
                _detail.totalAmount != 0
            ) {
                uint256 _claimableReward;
                uint256 currentPercentage = (stakedAmount * PERCENT_DIVIDER) /
                    _detail.totalAmount;
                _claimableReward =
                    (totalAddedReward * currentPercentage) /
                    PERCENT_DIVIDER;

                totalReward += _claimableReward;
            }
        }

        return totalReward;
    }

    function claimablePlan2Bonus(
        address _user,
        uint256 _index
    ) public view returns (uint256 totalReward) {
        User storage user = userStakes[_user];
        if (_index == 0 && _index > user.stakeCounts[2]) {
            return 0;
        }
        Stake storage userStake = user.planStakes[2][_index];
        uint256 stakedAmount = userStake.amount;

        // Check if token is set as reward
        uint256 totalAddedRewardCount = totalPlan2RewardCount;
        uint256 lastUserClaimed = userStake.lastClaimedBonus2;
        for (uint256 k = lastUserClaimed + 1; k <= totalAddedRewardCount; k++) {
            uint256 totalAddedReward = totalAddedPlan2Bonus[k];

            StakeDetail memory _detail = plan2BonusHistory[k];
            if (
                (_detail.addedAt > userStake.startTime &&
                    _detail.addedAt <= userStake.endTime) &&
                _detail.totalAmount != 0
            ) {
                uint256 _claimableReward;
                uint256 currentPercentage = (stakedAmount * PERCENT_DIVIDER) /
                    _detail.totalAmount;
                _claimableReward =
                    (totalAddedReward * currentPercentage) /
                    PERCENT_DIVIDER;

                totalReward += _claimableReward;
            }
        }

        return totalReward;
    }

    function calculateTotalStakedInfo(
        address _usr,
        uint256 _plan
    ) public view returns (uint256 stakedAmount) {
        for (uint256 i = 1; i <= userStakes[_usr].stakeCounts[_plan]; i++) {
            if (userStakes[_usr].planStakes[_plan][i].unstakedAt == 0) {
                Stake memory stakeInfo = userStakes[_usr].planStakes[_plan][i];
                stakedAmount += stakeInfo.amount;
            }
        }
    }

    function getStakeInfo(
        address _usr,
        uint256 _plan,
        uint256 _index
    )
        external
        view
        returns (
            uint256 staked,
            uint256 stakeTime,
            uint256 endTime,
            uint256 unstakedAt
        )
    {
        require(
            _index != 0 && _index <= userStakes[_usr].stakeCounts[_plan],
            "Invalid index"
        );

        return (
            userStakes[_usr].planStakes[_plan][_index].amount,
            userStakes[_usr].planStakes[_plan][_index].startTime,
            userStakes[_usr].planStakes[_plan][_index].endTime,
            userStakes[_usr].planStakes[_plan][_index].unstakedAt
        );
    }

    function userStakeCounts(
        address _user,
        uint256 _plan
    ) external view returns (uint256) {
        return userStakes[_user].stakeCounts[_plan];
    }

    // Deposit rewards into the contract
    function depositRewards() external payable onlyOwner {
        require(msg.value != 0, "Invalid amount");

        totalRewardCount += 1;
        totalAddedRewards[totalRewardCount] = msg.value;

        rewardStakeHistory[totalRewardCount].totalUsers = totalUsers;
        uint256 stakedAmount = totalStakedAmount[0] +
            totalStakedAmount[1] +
            totalStakedAmount[2];
        uint256 unstakedAmount = totalUnstakedAmount[0] +
            totalUnstakedAmount[1] +
            totalUnstakedAmount[2];
        rewardStakeHistory[totalRewardCount].totalAmount =
            stakedAmount -
            unstakedAmount;
        rewardStakeHistory[totalRewardCount].addedAt = block.timestamp;

        emit REWARD_DEPOSITED(msg.value, totalRewardCount, block.timestamp);
    }

    // Deposit rewards into the contract
    function depositPlan1Bonus() external payable onlyOwner {
        require(msg.value != 0, "Invalid amount");

        totalPlan1RewardCount += 1;
        totalAddedPlan1Bonus[totalPlan1RewardCount] = msg.value;
        plan1BonusHistory[totalPlan1RewardCount].totalUsers = totalUsers;

        uint256 stakedAmount = totalStakedAmount[0] +
            totalStakedAmount[1] +
            totalStakedAmount[2];
        uint256 unstakedAmount = totalUnstakedAmount[0] +
            totalUnstakedAmount[1] +
            totalUnstakedAmount[2];
        plan1BonusHistory[totalPlan1RewardCount].totalAmount =
            stakedAmount -
            unstakedAmount;
        plan1BonusHistory[totalPlan1RewardCount].addedAt = block.timestamp;

        emit REWARD_DEPOSITED(
            msg.value,
            totalPlan1RewardCount,
            block.timestamp
        );
    }

    function depositPlan2Bonus() external payable onlyOwner {
        require(msg.value != 0, "Invalid amount");

        totalPlan2RewardCount += 1;
        totalAddedPlan2Bonus[totalPlan2RewardCount] = msg.value;
        plan2BonusHistory[totalPlan2RewardCount].totalUsers = totalUsers;

        uint256 stakedAmount = totalStakedAmount[0] +
            totalStakedAmount[1] +
            totalStakedAmount[2];
        uint256 unstakedAmount = totalUnstakedAmount[0] +
            totalUnstakedAmount[1] +
            totalUnstakedAmount[2];
        plan2BonusHistory[totalPlan2RewardCount].totalAmount =
            stakedAmount -
            unstakedAmount;
        plan2BonusHistory[totalPlan2RewardCount].addedAt = block.timestamp;

        emit REWARD_DEPOSITED(
            msg.value,
            totalPlan2RewardCount,
            block.timestamp
        );
    }

    function setLockDuration(uint256[3] memory duration) external onlyOwner {
        lockDuration = duration;
    }

    function setPenaltyPercent(uint256 percent) external onlyOwner {
        require(percent <= 100, "Invalid penalty percent");
        penaltyPercent = percent;
    }

    function setStakingToken(IERC20 _token) external onlyOwner {
        havocToken = _token;
    }

    function setPauseStatus(bool _pauseStatus) external onlyOwner {
        paused = _pauseStatus;
    }

    function withdrawStuckTokens(
        IERC20 _token,
        address _receiver,
        uint256 _amount
    ) external onlyOwner {
        _token.safeTransfer(_receiver, _amount);
    }
}