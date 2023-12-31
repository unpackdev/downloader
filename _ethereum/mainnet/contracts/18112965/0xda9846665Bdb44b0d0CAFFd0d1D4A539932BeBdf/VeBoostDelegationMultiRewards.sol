// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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

interface IVeBoost {
    function approve(address, uint256) external;
    function boost(address, uint256, uint256, address) external;
    function delegable_balance(address) external returns (uint256);
    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external;
    function received_balance(address) external returns (uint256);
}

// Original idea and credit:
// VeSDTDelegation 0x6037Bb1BBa598bf88D816cAD90A28cC00fE3ff64 by AladdinDAO
// Mostly forked from AladdinDAO, except that now there is a minimum period to delegate boost
// and there are 2 tokens as reward rather than one.
contract VeBoostDelegationMultiRewards is Ownable {
    using SafeERC20 for IERC20;

    /// Errors
    error NOT_ALLOWED();
    error NOT_STARTED_YET();
    error TOO_LOW();
    error TOKEN_NOT_SUPPORTED();
    error ZERO_ADDRESS();

    /// @notice Emitted when someone boost the `LockerProxy` contract.
    /// @param _owner The address of veToken owner.
    /// @param _recipient The address of recipient who will receive the pool share.
    /// @param _amount The amount of veToken to boost.
    /// @param _endtime The timestamp in seconds when the boost will end.
    event Boost(address indexed _owner, address indexed _recipient, uint256 _amount, uint256 _endtime);

    /// @notice Emitted when someone checkpoint pending rewards.
    /// @param _timestamp The timestamp in seconds when the checkpoint happened.
    /// @param _rewardToken The token reward address
    /// @param _amount The amount of pending rewards distributed.
    event CheckpointReward(uint256 _timestamp, address _rewardToken, uint256 _amount);

    /// @notice Emitted when user claim pending rewards
    /// @param _owner The owner of the pool share.
    /// @param _recipient The address of recipient who will receive the rewards.
    /// @param _token The token claimed
    /// @param _amount The amount of pending rewards claimed.
    event Claim(address indexed _owner, address indexed _recipient, address indexed _token, uint256 _amount);

    /// @notice Emitted when a new min boost duration has set
    /// @param _duration Min boosting duration
    event MinBoostDurationSet(uint256 _duration);

    /// @dev The address of Token Vote-Escrowed Boost contract.
    // solhint-disable-next-line const-name-snakecase
    address public constant veTOKEN_BOOST = 0x67F8DF125B796B05895a6dc8Ecf944b9556ecb0B; // BAL VeBoost

    /// @notice Reward tokens
    address public constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;
    address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;

    uint256 private constant REWARD_CHECKPOINT_DELAY = 1 days;

    /// @dev The number of seconds in a week.
    uint256 private constant WEEK = 86400 * 7;

    /// @dev The minimum boost duration
    uint256 public minBoostDuration = 4 * WEEK;

    /// @notice The name of the vault.
    // solhint-disable-next-line const-name-snakecase
    string public constant name = "Balancer veBPT Boost";

    /// @notice The symbol of the vault.
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "veBPT-boost";

    /// @notice The decimal of the vault share.
    // solhint-disable-next-line const-name-snakecase
    uint8 public constant decimals = 18;

    /// @notice The address of lockerProxy contract.
    address public immutable lockerProxy;

    /// @dev Compiler will pack this into single `uint256`.
    /// The boost power can be represented as `bias - slope * (t - ts)` if the time `t` and `ts`
    /// is in the same epoch. If epoch cross happens, we will change the corresponding value based
    /// on slope changes.
    struct Point {
        // The bias for the linear function
        uint112 bias;
        // The slop for the linear function
        uint112 slope;
        // The start timestamp in seconds for current epoch.
        // `uint32` should be enough for next 83 years.
        uint32 ts;
    }

    /// @dev Compiler will pack this into single `uint256`.
    struct RewardData {
        // The current balance of reward token.
        uint128 balance;
        // The timestamp in second when last distribute happened.
        uint128 timestamp;
    }

    /// @notice Mapping from user address to current updated point.
    /// @dev The global information is stored in address(0)
    mapping(address => Point) public boosts;

    /// @notice Mapping from user address to boost endtime to slope changes.
    /// @dev The global information is stored in address(0)
    mapping(address => mapping(uint256 => uint256)) public slopeChanges;

    /// @notice Mapping from user address to week timestamp to the boost power.
    /// @dev The global information is stored in address(0)
    mapping(address => mapping(uint256 => uint256)) public historyBoosts;

    /// @notice Mapping from token -> week timestamp -> number of rewards accured during the week.
    mapping(address => mapping(uint256 => uint256)) public weeklyRewards;

    /// @notice Mapping from user address -> token address -> reward claimed week timestamp.
    mapping(address => mapping(address => uint256)) public claimIndex;

    /// @notice The lastest reward distribute information.
    mapping(address => RewardData) public lastRewards;

    /**
     * Constructor *********************************
     */

    constructor(address _lockerProxy, uint256 _startTimestamp) {
        lockerProxy = _lockerProxy;
        boosts[address(0)] = Point({bias: 0, slope: 0, ts: uint32(block.timestamp)});
        // BAL info
        lastRewards[BAL] =
            RewardData({balance: 0, timestamp: uint128(_startTimestamp)});
        // SDT info
        lastRewards[SDT] =
            RewardData({balance: 0, timestamp: uint128(_startTimestamp)});
    }

    /**
     * View Functions *********************************
     */

    /// @notice Return the current total pool shares.
    function totalSupply() external view returns (uint256) {
        Point memory p = _checkpointRead(address(0));
        return p.bias - p.slope * (block.timestamp - p.ts);
    }

    /// @notice Return the current pool share for the user.
    /// @param _user The address of the user to query.
    function balanceOf(address _user) external view returns (uint256) {
        if (_user == address(0)) return 0;

        Point memory p = _checkpointRead(_user);
        return p.bias - p.slope * (block.timestamp - p.ts);
    }

    /**
     * Mutated Functions *********************************
     */

    /// @notice Boost some veToken to `LockerProxy` contract permited.
    /// @dev Use `_amount=-1` to boost all available power.
    /// @param _amount The amount of veToken to boost.
    /// @param _endtime The timestamp in seconds when the boost will end.
    /// @param _recipient The address of recipient who will receive the pool share.
    /// @param _deadline The deadline in seconds for the permit signature.
    /// @param _v The V part of the signature
    /// @param _r The R part of the signature
    /// @param _s The S part of the signature
    function boostPermit(
        uint256 _amount,
        uint256 _endtime,
        address _recipient,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        // set allowance
        IVeBoost(veTOKEN_BOOST).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);

        // do delegation
        boost(_amount, _endtime, _recipient);
    }

    /// @notice Boost some veToken to `lockerProxy` contract.
    /// @dev Use `_amount=-1` to boost all available power.
    /// @param _amount The amount of veToken to boost.
    /// @param _endtime The timestamp in seconds when the boost will end.
    /// @param _recipient The address of recipient who will receive the pool share.
    function boost(uint256 _amount, uint256 _endtime, address _recipient) public {
        if (_recipient == address(0)) revert ZERO_ADDRESS();
        if (_amount == type(uint256).max) {
            _amount = IVeBoost(veTOKEN_BOOST).delegable_balance(msg.sender);
        }

        // check if the _endTime is at least minBoostDuration
        uint256 currentWeek = block.timestamp / WEEK * WEEK;
        if (_endtime < currentWeek + minBoostDuration) revert TOO_LOW();

        IVeBoost(veTOKEN_BOOST).boost(lockerProxy, _amount, _endtime, msg.sender);

        _boost(_amount, _endtime, _recipient);
    }

    /// @notice Claim rewards for some user.
    /// @param _user The address of user to claim.
    /// @param _recipient The address of recipient who will receive the reward.
    /// @param _token The address of the token to claim
    function claim(address _user, address _recipient, address _token) public {
        if (_user != msg.sender) {
            if (_recipient != _user) revert NOT_ALLOWED();
        }
        if (_user == address(0)) revert ZERO_ADDRESS();
        if (BAL != _token && SDT != _token) revert TOKEN_NOT_SUPPORTED();

        // during claiming, update the point if 1 day pasts, since we will not use the latest point
        Point memory p = boosts[address(0)];
        if (block.timestamp >= p.ts + REWARD_CHECKPOINT_DELAY) {
            _checkpointWrite(address(0), p);
            boosts[address(0)] = p;
        }

        // during claiming, update the point if 1 day pasts, since we will not use the latest point
        p = boosts[_user];
        if (block.timestamp >= p.ts + REWARD_CHECKPOINT_DELAY) {
            _checkpointWrite(_user, p);
            boosts[_user] = p;
        }

        // checkpoint weekly reward
        _checkpointReward(_token, false);

        // claim reward
        _claim(_user, _recipient, _token);
    }

    /// @notice Claim all rewards for some user.
    /// @param _user The address of user to claim.
    /// @param _recipient The address of recipient who will receive the reward.
    function claimAll(address _user, address _recipient) external {
        claim(_user, _recipient, BAL);
        claim(_user, _recipient, SDT);
    }

    /// @notice Force checkpoint reward status for one token.
    /// @param _token reward token to checkpoint
    function checkpointReward(address _token) external {
        if (_token != BAL && _token != SDT) revert TOKEN_NOT_SUPPORTED();
        _checkpointReward(_token, true);
    }

    /// @notice Force checkpoint reward status for all reward tokens.
    function checkpointRewards() external {
        _checkpointReward(BAL, true);
        _checkpointReward(SDT, true);
    }

    /// @notice Force checkpoint user information.
    /// @dev User `_user=address(0)` to checkpoint total supply.
    /// @param _user The address of user to checkpoint.
    function checkpoint(address _user) external {
        Point memory p = boosts[_user];
        _checkpointWrite(_user, p);
        boosts[_user] = p;
    }

    /// @notice Set the minimum duration for delegate boost
    /// @param _duration minimum boosting duration
    function setMinBoostDuration(uint256 _duration) external onlyOwner {
        minBoostDuration = _duration;
        emit MinBoostDurationSet(_duration);
    }

    /**
     * Internal Functions *********************************
     */

    /// @dev Internal function to update boost records
    /// @param _amount The amount of veToken to boost.
    /// @param _endtime The timestamp in seconds when the boost will end.
    /// @param _recipient The address of recipient who will receive the pool share.
    function _boost(uint256 _amount, uint256 _endtime, address _recipient) internal {
        if (claimIndex[_recipient][BAL] == 0) {
            claimIndex[_recipient][BAL] = (block.timestamp / WEEK) * WEEK;
            claimIndex[_recipient][SDT] = (block.timestamp / WEEK) * WEEK;
        }

        // _endtime should always be multiple of WEEK
        uint256 _slope = _amount / (_endtime - block.timestamp);
        uint256 _bias = _slope * (_endtime - block.timestamp);

        // update global state
        _update(_bias, _slope, _endtime, address(0));

        // update user state
        _update(_bias, _slope, _endtime, _recipient);

        emit Boost(msg.sender, _recipient, _amount, _endtime);
    }

    /// @dev Internal function to update veBoost point
    /// @param _bias The bias delta of the point.
    /// @param _slope The slope delta of the point.
    /// @param _endtime The endtime in seconds for the boost.
    /// @param _user The address of user to update.
    function _update(uint256 _bias, uint256 _slope, uint256 _endtime, address _user) internal {
        Point memory p = boosts[_user];
        _checkpointWrite(_user, p);
        p.bias += uint112(_bias);
        p.slope += uint112(_slope);

        slopeChanges[_user][_endtime] += _slope;
        boosts[_user] = p;

        if (p.ts % WEEK == 0) {
            historyBoosts[_user][p.ts] = p.bias;
        }
    }

    /// @dev Internal function to claim user rewards.
    /// @param _user The address of user to claim.
    /// @param _recipient The address of recipient who will receive the reward.
    /// @return The amount of reward claimed.
    function _claim(address _user, address _recipient, address _token) internal returns (uint256) {
        uint256 _index = claimIndex[_user][_token];
        uint256 _lastTime = lastRewards[_token].timestamp;
        uint256 _amount = 0;
        uint256 _thisWeek = (block.timestamp / WEEK) * WEEK;

        // claim at most 50 weeks in one tx
        for (uint256 i = 0; i < 50;) {
            // we don't claim rewards from current week.
            if (_index >= _lastTime || _index >= _thisWeek) break;
            uint256 _totalPower = historyBoosts[address(0)][_index];
            uint256 _userPower = historyBoosts[_user][_index];
            if (_totalPower != 0 && _userPower != 0) {
                _amount += (_userPower * weeklyRewards[_token][_index]) / _totalPower;
            }
            _index += WEEK;
            unchecked {
                ++i;
            }
        }
        claimIndex[_user][_token] = _index;

        if (_amount > 0) {
            lastRewards[_token].balance -= uint128(_amount);
            IERC20(_token).safeTransfer(_recipient, _amount);
        }

        emit Claim(_user, _recipient, _token, _amount);
        return _amount;
    }

    /// @dev Internal function to read checkpoint result without change state.
    /// @param _user The address of user to checkpoint.
    /// @return The result point for the user.
    function _checkpointRead(address _user) internal view returns (Point memory) {
        Point memory p = boosts[_user];

        if (p.ts == 0) {
            p.ts = uint32(block.timestamp);
        }
        if (p.ts == block.timestamp) {
            return p;
        }

        uint256 ts = (p.ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255;) {
            ts += WEEK;
            uint256 _slopeChange = 0;
            if (ts > block.timestamp) {
                ts = block.timestamp;
            } else {
                _slopeChange = slopeChanges[_user][ts];
            }

            p.bias -= p.slope * uint112(ts - p.ts);
            p.slope -= uint112(_slopeChange);
            p.ts = uint32(ts);

            if (p.ts == block.timestamp) {
                break;
            }

            unchecked {
                ++i;
            }
        }
        return p;
    }

    /// @dev Internal function to read checkpoint result and change state.
    /// @param _user The address of user to checkpoint.
    function _checkpointWrite(address _user, Point memory p) internal {
        if (p.ts == 0) p.ts = uint32(block.timestamp);
        if (p.ts == block.timestamp) return;

        uint256 ts = (p.ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255;) {
            ts += WEEK;
            uint256 _slopeChange = 0;
            if (ts > block.timestamp) {
                ts = block.timestamp;
            } else {
                _slopeChange = slopeChanges[_user][ts];
            }

            p.bias -= p.slope * uint112(ts - p.ts);
            p.slope -= uint112(_slopeChange);
            p.ts = uint32(ts);

            if (ts % WEEK == 0) {
                historyBoosts[_user][ts] = p.bias;
            }

            if (p.ts == block.timestamp) {
                break;
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Internal function to checkpoint the rewards
    /// @param _force Whether to do force checkpoint.
    function _checkpointReward(address _token, bool _force) internal {
        uint256 _lastTime = lastRewards[_token].timestamp;
        // We only claim in the next week, so the update can delay 1 day.
        if (!_force && block.timestamp <= _lastTime + REWARD_CHECKPOINT_DELAY) return;
        if (block.timestamp < _lastTime) revert NOT_STARTED_YET();

        // update timestamp
        uint256 _sinceLast = block.timestamp - _lastTime;
        lastRewards[_token].timestamp = uint128(block.timestamp);

        // update balance
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        uint256 _amount = _balance - lastRewards[_token].balance;
        lastRewards[_token].balance = uint128(_balance);

        if (_amount > 0) {
            uint256 _thisWeek = (_lastTime / WEEK) * WEEK;
            // 20 should be enough, since we are doing checkpoint every week.
            for (uint256 i; i < 20;) {
                uint256 _nextWeek = _thisWeek + WEEK;
                if (block.timestamp < _nextWeek) {
                    if (_sinceLast == 0) {
                        weeklyRewards[_token][_thisWeek] += _amount;
                    } else {
                        weeklyRewards[_token][_thisWeek] += (_amount * (block.timestamp - _lastTime)) / _sinceLast;
                    }
                    break;
                } else {
                    if (_sinceLast == 0 && _nextWeek == _lastTime) {
                        weeklyRewards[_token][_thisWeek] += _amount;
                    } else {
                        weeklyRewards[_token][_thisWeek] += (_amount * (_nextWeek - _lastTime)) / _sinceLast;
                    }
                }
                _lastTime = _nextWeek;
                _thisWeek = _nextWeek;
                unchecked {
                    ++i;
                }
            }
        }
        emit CheckpointReward(block.timestamp, _token, _amount);
    }
}