// File: contracts/CVEPresale.sol

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value: amount}("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage)
        internal
        view
        returns (bytes memory)
    {
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
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
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage)
        internal
        pure
        returns (bytes memory)
    {
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.7;

contract CVEPreSale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    //Consturctor Args
    uint256 public constant totalPhases=6;
uint256 public tokenCollected;

    // Globally changeable
    uint256 public tokenSold;
    uint256 private _totalUSDTInvestment;
    uint256 public currentPhase;
    uint256 public constant scalingDivisor = 1e12;
    /// Pre-sets
    address private  constant Funds_Wallet = 0xFB92E7c21CC43988Ed3676D187380BCf249e8853;
    address private constant Default_Refer_Wallet = 0x3826620Fc649D17917B0AC24a39E8a783b5d21EF;
    IERC20 private  USDT;
    IERC20 private  SaleToken;
    uint256 private constant totalSupply = 25000000 ether;
    uint256[] public phasePrice = [0.04 ether, 0.05 ether, 0.06 ether, 0.065 ether, 0.07 ether, 0.08 ether, 0.085 ether];
    uint256[] public phaseLimit =
        [5000000 ether, 9000000 ether, 12750000 ether, 16250000 ether, 19500000 ether, 22500000 ether, 25000000 ether];
    uint256[] public phaseMinAmount = [120 ether, 150 ether, 180 ether, 195 ether, 210 ether, 240 ether, 255 ether];
    uint256[] referLevels = [15, 5, 3];



    struct Sale {
      
        uint256 claimedDate;
        uint256 totalAmount;
        uint256 claimed;
        uint256 claimStrikes;
    }
    //Mappings

    mapping(address => mapping(uint256 => Sale)) public sales;
    mapping(address => address) public referralAddress;
    mapping(address => address[]) public myReferrals;
    mapping(address => uint256) public referralRewards;
    mapping(address => mapping(uint256 => address[])) private levels;

    //Events
    event VestingStart(address indexed userAddress, uint256 quantity, uint256 indexed SalePhase);
    event TransferSaleToken(address indexed fromAddress, address indexed toAddress, uint256 amount, uint256 date);
    event ReferralRewarded(address indexed user,address indexed referrer, uint256 amount);
    event Received(address, uint256);

    constructor(address _usdt, address _saleToken) {
        referralAddress[Default_Refer_Wallet] = address(0);
        USDT = IERC20(_usdt);
        SaleToken = IERC20(_saleToken);
    }

 function buyTokens(uint256 amount, address _referralAddress) external nonReentrant {
    require(currentPhase <= totalPhases, "Sale has ended");
    uint256 balance = USDT.balanceOf(msg.sender);
    uint256 transferAmount = amount / scalingDivisor;
    require(balance >= transferAmount, "Insufficient balance");
    
    uint256 allowance = USDT.allowance(msg.sender, address(this));
    require(allowance >= transferAmount, "Insufficient allowance");
    require(_referralAddress != address(0), "Invalid referral address0");
    if (_referralAddress != Default_Refer_Wallet) {
            require(referralAddress[_referralAddress] != address(0), "Invalid referral address");
    }
    if (totalSupply - tokenSold > 3000 ether) {
        require(amount >= phaseMinAmount[currentPhase], "Quantity should be more than 3000");
    }
    (uint256 remainingUSD, uint256 quantity) = getTokenForUSD(amount);
    require(quantity > 0, "Invalid quantity");
    tokenSold += quantity;
    require(tokenSold <= totalSupply, "Sale amount exceeded");
    USDT.safeTransferFrom(msg.sender, address(this), remainingUSD / scalingDivisor);
    if (referralAddress[msg.sender] == address(0)) {
        referralAddress[msg.sender] = _referralAddress;
        myReferrals[_referralAddress].push(msg.sender);
    }
       _referralAddress = referralAddress[msg.sender];
    _totalUSDTInvestment += remainingUSD;
    setCurrentPhase(tokenSold);
    uint256 _remainingTokens = payReferRew(_referralAddress, remainingUSD);
    // USDT.safeTransfer(Funds_Wallet, _remainingTokens / scalingDivisor);
    tokenCollected+=(_remainingTokens/scalingDivisor);
    tokenVesting(quantity, currentPhase);
}

function withdrawFunds() public onlyOwner{
    require(tokenCollected> 0,"NO Funds collected");
    USDT.safeTransfer(Funds_Wallet, tokenCollected );
    tokenCollected=0;

}
    function setCurrentPhase(uint256 _tokens) private {
        for (uint8 i = 0; i < phaseLimit.length; i++) {
            if (_tokens > phaseLimit[i]) {
                currentPhase = i + 1;
            }
        }
    }

    function getCurrentPrice() public view returns (uint256) {
        for (uint8 i = 0; i < phaseLimit.length; i++) {
            if (tokenSold <= phaseLimit[i]) {
                return phasePrice[i];
            }
        }
        return 0;
    }

    function payReferRew(address _referralAddress, uint256 _amount) private returns (uint256) {
        address uplineAddress = _referralAddress;
        uint256 rewPaid;
        for (uint256 i = 0; i < referLevels.length && uplineAddress != address(0); i++) {
            uint256 _rewards = (_amount * referLevels[i]) / 100;
            referralRewards[uplineAddress] += _rewards;
            rewPaid += _rewards;
            setReferredUser(i + 1, uplineAddress);
            emit ReferralRewarded(msg.sender,uplineAddress, _rewards);
         
            uplineAddress = referralAddress[uplineAddress];
        }
        return (_amount - rewPaid);
    }
    function claimRewards() external {
            uint256 rewards = referralRewards[msg.sender];
            USDT.safeTransfer(msg.sender, rewards / scalingDivisor);
            referralRewards[msg.sender]=0;
    }

    function tokenVesting(uint256 quantity, uint256 phase) internal {
        require(phase <= totalPhases, "Not enough tokens Left");
        Sale storage sale = sales[msg.sender][phase];
        
        sale.claimedDate = block.timestamp;     
        sale.totalAmount -= sale.claimed;
        sale.claimed = 0;
        sale.totalAmount += quantity;
        sale.claimStrikes = 0;
        emit VestingStart(msg.sender, quantity, phase);
    }
    function claimTokens(uint256 saleIndex) public nonReentrant {
    Sale storage sale = sales[msg.sender][saleIndex];
    require(sale.totalAmount > 0 && sale.claimedDate <= block.timestamp, "Invalid claim parameters");
    require(sale.claimStrikes <= 12, "Claim strikes exceeded");

    uint256 tokensToClaim = (sale.claimStrikes == 0) ? (sale.totalAmount * 10) / 100 : (sale.totalAmount * 75) / 1000;

    uint256 remainingTokens = sale.totalAmount - sale.claimed;
    require(remainingTokens > 0, "No remaining tokens to claim");
    tokensToClaim = (remainingTokens < tokensToClaim) ? remainingTokens : tokensToClaim;
    require(tokensToClaim + sale.claimed <= sale.totalAmount, "Token claim exceeds limit");

    sale.claimed += tokensToClaim;
    sale.claimStrikes = (sale.claimStrikes < totalPhases) ? sale.claimStrikes + 1 : sale.claimStrikes;
    sale.claimedDate = block.timestamp + 30 days;

    emit TransferSaleToken(msg.sender, address(this), tokensToClaim, block.timestamp);
    SaleToken.safeTransfer(msg.sender, tokensToClaim);
}
    function getNextClaims(address _userAddress, uint256 saleIndex) public view returns (uint256) {
        Sale storage sale = sales[_userAddress][saleIndex];

        if (sale.totalAmount == 0) return 0;
        uint256 tokensToClaim = (sale.claimStrikes == 0) ? (sale.totalAmount * 10) / 100 : (sale.totalAmount * 75) / 1000;
        uint256 remainingTokens = sale.totalAmount - sale.claimed;
        if (remainingTokens == 0) return 0;
        if (remainingTokens < tokensToClaim) {
            tokensToClaim = remainingTokens;
        }
        return tokensToClaim;
    }

    function tokenBalance() public view returns (uint256) {
        uint256 balance = SaleToken.balanceOf(address(this));
        return balance;
    }

    function getMyReferrals() external view returns (address[] memory) {
        return myReferrals[msg.sender];
    }

    function getTotalUSDTInvestment() external view returns (uint256) {
        return _totalUSDTInvestment;
    }

    function getReferralData(address _referralAddress) external view returns (address _referral) {
        _referral = referralAddress[_referralAddress];
        return _referral;
    }

    function getRemSaleTokens() public view returns (uint256 remAmount) {
        remAmount = phaseLimit[currentPhase] - tokenSold;
        return remAmount;
    }

    function setReferredUser(uint256 level, address userAddress) internal {
        levels[userAddress][level].push(msg.sender);
    }

    function getLevelReffers(uint256 level, address userAddress) external view returns (address[] memory) {
        address[] memory array = levels[userAddress][level];
        return array;
    }

    function getTokenForUSD(uint256 _usdAmount) public view returns (uint256, uint256 tokenAmountRequired) {
        // Calculate the token amount required for the given USD amount at the current price
        tokenAmountRequired = (_usdAmount * 1 ether) / getCurrentPrice();
        // Calculate the tokens available in the current phase
        uint256 tokensAvailable = phaseLimit[currentPhase] - tokenSold;
        // If the required tokens can be fulfilled from the current phasse, return the required token amount
        if (tokenAmountRequired < tokensAvailable) {
            return (_usdAmount, tokenAmountRequired); // Return token amount in whole units (tokens, not wei)
        } else if (currentPhase == totalPhases) {
            uint256 remainingTokens = tokenAmountRequired - tokensAvailable;
            // Calculate the remaining USD equivalent to cover the remaining tokens
            uint256 remUSD = (remainingTokens * getCurrentPrice()) / 1 ether;
            return (_usdAmount - remUSD, tokensAvailable);
        } else {
            uint256 remainingTokens = tokenAmountRequired - tokensAvailable;
            // Calculate the remaining USD equivalent to cover the remaining tokens
            uint256 remUSD = (remainingTokens * getCurrentPrice()) / 1 ether;

            // Calculate the tokens needed from the next phase
            uint256 tokensNeededFromNextPhase = (remUSD * 1 ether) / phasePrice[currentPhase + 1];
            uint256 usdRem;
            tokenAmountRequired = tokensAvailable + tokensNeededFromNextPhase;

           uint256 phaseAmount = phaseLimit[currentPhase+1] - phaseLimit[currentPhase];
            if (tokensNeededFromNextPhase > phaseAmount) {
                uint256 av = tokensNeededFromNextPhase - phaseAmount;
                usdRem = (av * phasePrice[currentPhase + 1]) / 1 ether;
                tokenAmountRequired = tokenAmountRequired - av;
            }
            require(phaseLimit[currentPhase + 1] > tokenAmountRequired, "Can't buy more than current sale ");
            // Calculate the total tokens receivable by combining tokens from the current and next phases

            return (_usdAmount - usdRem, tokenAmountRequired); // Return token amount in whole units (tokens, not wei)
        }
    }
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}