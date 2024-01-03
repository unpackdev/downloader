/**
 *Submitted for verification at Etherscan.io on 2020-09-12
*/

pragma solidity =0.6.6;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// 
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// 
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// 
/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// 
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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// 
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
    using SafeMath for uint256;
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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
        _;
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

// 
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

//import "./UniswapV2Library.sol";
library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }
}

contract NitroProtocol {
    /// Struct for timelocked bonus tokens
    struct TimelockedBonus {
        uint256 bonusAmount;
        uint releaseBlock;
    }

    /// @notice Mapping of owed bonus tokens from buy orders. Includes bonus amounts and releaseTimestamps
    mapping (address => TimelockedBonus) private _timelockedBonuses;
    
    /// @notice max sell percentage allowed. If pre-calculated nitro is greater than this, it becomes equal
    uint256 private _maxSellRemoval; //units are %

    /// @notice max percentage bonus tokens per buy order. If pre-calculated nitro is greater than this, it becomes equal
    uint256 private _maxBuyBonus; //units are %

//////////////////----------------Public View Variables----------------///////////////

    //Return the maxSellRemoval
    function maxSellRemoval() public view returns (uint256) {
        return _maxSellRemoval;
    }

    function maxBuyBonus() public view returns (uint256) {
        return _maxBuyBonus;
    }

    /**
     * Return the block unlock time for a given mapping.
     */
    function getBonusUnlockTime(address bonusAddress) public view returns (uint) {
        return _timelockedBonuses[bonusAddress].releaseBlock; //Using memory, temporary
    }

    /**
     * Get the available bonus for this address (once it is unlocked)
     */
    function getBonusAmount(address bonusAddress) public view returns (uint256) {
        return _timelockedBonuses[bonusAddress].bonusAmount;
    }

//////////////////----------------Modify Variables, Internal----------------///////////////

    /**
     * @dev Set the maximum percent order volume of tokens taken in a sell order
     */
    function _changeMaxSellRemoval(uint256 new_maxSellRemoval) internal {
        _maxSellRemoval = new_maxSellRemoval;
    }

    /**
     * @dev Set the maximum percent order volume of bonus tokens for buyers
     */
    function _setMaxBuyBonusPercentage(uint256 new_maxBuyBonus) internal {
        _maxBuyBonus = new_maxBuyBonus;
    }

//////////////////----------------Timelocked Bonuses Interface----------------///////////////

    /**
     * Add/create a TimelockedBonus struct to the _timelockedBonuses mapping
     */
    function _addToTimelockedBonus(address bonusAddress, uint256 tokens_to_add, uint releaseBlockNumber) internal {
        _timelockedBonuses[bonusAddress] = TimelockedBonus((_timelockedBonuses[bonusAddress].bonusAmount + tokens_to_add), releaseBlockNumber);
    }

    /**
     * Sets the timelocked Bonus for a given address to be exactly 0 
     */
    function _removeTimelockedBonus(address bonusAddress) internal {
        uint256 amount = 0;
        _timelockedBonuses[bonusAddress] = TimelockedBonus(amount, block.number);
    }
}




// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@(//(,.............////#@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@///....,,......*,,,,,,,**,,...(/(@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@(/*.,...,,........*,.*..**..*,,,,,,,,.(/@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@//.,...,.*........ ,,,*******(..*...,*.,,,,(/@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@%/,.....**(/*******.*. ,,,,,,,,,,**(....,....,,,//@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@/,,....**/********,,,,,,.... ,,,,,,... ****/,,..,,,(/@@@@@@@@@@@@@
// @@@@@@@@@@@@(/,......*(******,,,,,,,.,...,..........**,****(,...*,*(@@@@@@@@@@@@
// @@@@@@@@@@@(/,.....**/******,,,,,,,,.,,,,,...*...... *,,****/,,...*,(@@@@@@@@@@@
// @@@@@@@@@@((,......**(****,,,,,,,,,,,,,,,,..........,,.,,*****,,,..*,/@@@@@@@@@@
// @@@@@@@@@@/,,,......*,/*,,,,,,,,,,.*,,,,,,.........,,,,,....,,,,*...,*/@@@@@@@@@
// @@@@@@@@@/,,./*........*/,,,,,,..,,,..,,,..........,,,,,,,..,,,,,,...,/@@@@@@@@@
// @@@@@@@@@(,,.***....,...,,,*,,*,,,,,,,,,...........,,.,,,,,,,,,,,....,((@@@@@@@@
// @@@@@@@@@/,,.****..,...,,,,,,,,,,,,,,,........,,,,,.,,,,,,,**,,,./...,//@@@@@@@@
// @@@@@@@@@/,,.*******.,.....,,,,,,,....,,/@@@@******#.,,,,,,,,,,,,/...,/%@@@@@@@@
// @@@@@@@@@(/,.,******.........*,,,&&/*#&/**************//#,,,,,.,,,,.,,/@@@@@@@@@
// @@@@@@@@@@/,,...*....,*.......@%(,@@@@@@@@,*****/*////##%*/(,,,*....,/(@@@@@@@@@
// @@@@@@@@@@@/,,......,..,.......#(//(,@@%(@@@@,***********/##(****#&,,,,/@@@@@@@@
// @@@@@@@@@@@@/,,,.*,*,,..........&&(/#(*,@@@%,,,,****@&****&,,,,,,,,,%&@@@@@@@@@@
// @@@@@@@@@@@@@(,,,,,,,,*...........,,(/&***,#,.,,,,,***@,,,,,,,****#/****%@@@@@@@
// @@@@@@@@@@@@@@#(,*,,,,,,,,.......*...,/(*****,,,@@@*,,,,,**********,*/%*@@@@@@@@
// @@@@@@@@@@@@@@@@((,**,, *,*........,,,,,(((((**,*@@#(&********,....*%@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@//,**,,, ........,...,.@#&((*********,/....@@#@&(,*&@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@(/,,**...............&###((****((&//*(,,,/#@@@@%//&@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@///,,,**,........ &#&&((%,/,.*%@@@@%**,/#@@@@&#(&@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(///////////////&@@@@@@&//&@@@@&(**/#@@@@@&#@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&#/&@@@@@%/*/#@@@@@@%@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&(@@@@@@@#//#@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%@@@@@@@&#(%@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@
// 
/*                               _.-="_-         _
                         _.-="   _-          | ||"""""""---._______     __..
             ___.===""""-.______-,,,,,,,,,,,,`-''----" """""       """""  __'
      __.--""     __        ,'                   o \           __        [__|
 __-""=======.--""  ""--.=================================.--""  ""--.=======:
]       [w] : /        \ : |========================|    : /        \ :  [w] :
V___________:|          |: |========================|    :|          |:   _-"
 V__________: \        / :_|=======================/_____: \        / :__-"
 -----------'  "-____-"  `-------------------------------'  "-____-" */
// $LAMBO (LamboToken)
// @dev DegenerateGameTheorist
contract LamboToken is ERC20, NitroProtocol, Ownable, Pausable {
    using SafeMath for uint256;

    /// @notice Scale factor for NITRO calculations
    uint256 public constant scaleFactor = 1e18;

    /// @notice Total supply
    uint256 public constant total_supply = 2049 ether;

    /// @notice uniswap listing rate
    uint256 public constant INITIAL_TOKENS_PER_ETH = 2.27272727 * 1 ether;

    /// @notice WETH token address
    address public constant WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /// @notice self-explanatory
    address public constant uniswapV2Factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    address public immutable initialDistributionAddress;    

    address public stakingContractAddress;

    address public presaleContractAddress;

    uint256 public presaleInitFunds; 

    /// @notice liquidity sources (e.g. UniswapV2Router) 
    mapping(address => bool) public whitelistedSenders;

    /// @notice exchange addresses (tokens sent here will count as sell orders in NITRO Protocol)
    mapping(address => bool) public exchangeAddresses;

    /// @notice uniswap pair for LAMBO/ETH
    address public uniswapPair;

    /// @notice Whether or not this token is first in uniswap LAMBO<>ETH pair
    bool public isThisToken0;


    /// @notice last TWAP update time (Short calculation)
    uint32 public blockTimestampLast;

    /// @notice last TWAP cumulative price (Short calculation)
    uint256 public priceCumulativeLast;

    /// @notice last TWAP average price (Short calculation)
    uint256 public priceAverageLast;


    /// @notice last TWAP update time
    uint32 public blockTimestampLastLong;

    /// @notice last TWAP cumulative price
    uint256 public priceCumulativeLastLong;

    /// @notice last TWAP average price
    uint256 public priceAverageLastLong;

    /// @notice TWAP min delta (48-hour)
    uint256 public minDeltaTwapLong;

    /// @notice TWAP min delta (Short)
    uint256 public minDeltaTwapShort;

    /// @notice The minimum amount of blocks that must be mined before releasing bonus tokens
    uint public bonusReleaseTime;

    /// @notice percent of the removed funds from sell orders that goes to mechanics
    uint256 public MECHANIC_PCT;

    //Lets us check to see if the user account is moving lambo at this address' request
    address public uniswapv2RouterAddress; 

    //Emittable Events

    event TwapUpdated(uint256 priceCumulativeLast, uint256 blockTimestampLast, uint256 priceAverageLast);

    event LongTwapUpdated(uint256 priceCumulativeLastLong, uint256 blockTimestampLastLong, uint256 priceAverageLastLong);

    event MechanicPercentUpdated(uint256 new_mechanic_PCT);

    event StakingContractAddressUpdated(address newStakingAddress);

    event MaxSellRemovalUpdated(uint256 new_MSR);

    event MaxBuyBonusUpdated(uint256 new_MBB);

    event ExchangeListUpdated(address exchangeAddress, bool isExchange);

    event BonusBalanceUpdated(address userAddress, uint256 newAmount);

    event BonusReleaseTimeUpdated(uint blockDelta);

    event BuyerBonusPaid(address receiver, uint256 bonusAmount);

//                  ------------------ Contract Start Functions ---------------------                //
    constructor(
        uint256 _minDeltaTwapLong,
        uint256 _minDeltaTwapShort,
        uint256 _MECHANIC_PCT
    ) 
    public
    Ownable()
    ERC20("LamboToken", "LAMBO")
    {
        bonusReleaseTime = 13041; 
        setMinDeltaTwap(_minDeltaTwapLong, _minDeltaTwapShort);
        _setMaxBuyBonusPercentage(25);
        _changeMaxSellRemoval(25);
        initialDistributionAddress = owner(); //The contract owner handles all initial distribution, except for presale
        setMechanicPercent(_MECHANIC_PCT);
        _distributeTokens(owner());
        _initializePair();
        _pause();
        setUniswapRouterAddress(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    modifier whenNotPausedOrInitialDistribution(address tokensender) { //Only used on transfer function
        require(!paused() || msg.sender == initialDistributionAddress || _isWhitelistedSender(msg.sender) || (msg.sender == uniswapv2RouterAddress && tokensender == owner()), "!paused && !initialDistributionAddress !InitialLiquidityProvider");
        _;
    }

    modifier onlyInitialDistributionAddress() { //Only used to initialize twap
        require(msg.sender == initialDistributionAddress, "!initialDistributionAddress");
        _;
    }
    
    function _distributeTokens(
        address _initialDistributionAddress
    ) 
    internal
    {
        //Define the initial distribution of funds:
        //Giveaway funds (50) + Uniswap liquidity (320) + Moderator payments (10) = 370
        uint256 initDistributionFunds = 380 ether;
        // 535.6 LAMBO to the presale contract (455.6 whitelist + 80 dev)
        //         We don't know the presale address yet, so just give these tokens to this contract and transfer them later
        //1133.4 to the Nitro Protocol + the 535.6 to the presale contract = 
        presaleInitFunds = 535.6 ether;
        uint256 initContractFunds = total_supply.sub(initDistributionFunds);

        require((initContractFunds+initDistributionFunds)==total_supply, "Fund distribution doesn't match total supply.");

        _mint(address(_initialDistributionAddress), initDistributionFunds);
        setWhitelistedSender(_initialDistributionAddress, true);

        _mint(address(this), initContractFunds);
        setWhitelistedSender(address(this), true);
    }

    /*
     * Initialize the uniswap pair address to predict it and define it as an exchange address.
     */
    function _initializePair() internal {
        (address token0, address token1) = UniswapV2Library.sortTokens(address(this), address(WETH));
        isThisToken0 = (token0 == address(this));
        uniswapPair = UniswapV2Library.pairFor(uniswapV2Factory, token0, token1);
        setExchangeAddress(uniswapPair, true);
    }

    function setUniswapRouterAddress(address newUniRouterAddy) public onlyOwner {
        uniswapv2RouterAddress = newUniRouterAddy;
    }

//////////////////---------------- Administrative Functions ----------------///////////////
    /**
     * @dev Unpauses all transfers from the distribution address (initial liquidity pool).
     */
    function unpause() external virtual onlyOwner {
        super._unpause();
    }

//////////////////----------------Modify Nitro Protocol Variables----------------///////////////

    //Modify the maxSellRemoval 
    function changeMaxSellRemoval(uint256 maxSellRemoval) public onlyOwner {
        require(maxSellRemoval < 100, "Max Sell Removal is too high!");
        require(maxSellRemoval > 0, "Max Sell Removal is too small!");
        //Send it to the NitroProtocol
        _changeMaxSellRemoval(maxSellRemoval);

        //Emit this transaction
        emit MaxSellRemovalUpdated(maxSellRemoval);
    }

    /*
     * Sets the address of the staking contract ; required for project to work properly. 
     * Setting stakingContract to be the zero address will pause emissions to the staking contract.
     */
    function setStakingContractAddress(address stakingContract) public onlyOwner {
        stakingContractAddress = stakingContract;

        emit StakingContractAddressUpdated(stakingContract);
    }
    
    /*
     * Sets the address of the presale contract ; required for project to work properly.
     * The presale contract address can only be set one time, to prevent re-sending of the 508 lambo. 
     */
    function setPresaleContractAddress(address presaleContract) public onlyOwner {
        //We only want this to fire off once so the dev can't do any shady shit
        if(presaleContractAddress==address(0)){
            //Store address for posterity
            presaleContractAddress = presaleContract;

            //Whitelist the presale contract so that it can transfer tokens while contract is paused
            setWhitelistedSender(presaleContractAddress, true);

            //Send the tokens to the presale contract. presale Tokens should equal 
            super._transfer(address(this), presaleContractAddress, presaleInitFunds);
        }
    }

    /**
     * @dev Set the maximum percent order volume of bonus tokens for buyers
     */
    function setMaxBuyBonusPercentage(uint256 _maxBuyBonus) public onlyOwner {
        require(_maxBuyBonus < 100, "Max Buy Bonus is too high!");
        require(_maxBuyBonus > 0, "Max Buy Bonus is too small!");
        _setMaxBuyBonusPercentage(_maxBuyBonus);

        //Emit Buy Bonus was updated
        emit MaxBuyBonusUpdated(_maxBuyBonus);
    }

    /**
     * @dev Set the percentage that goes to the mechanics. Implicitly, (1-MECHANIC_PCT) = how much goes to Nitro.
     */
    function setMechanicPercent(uint256 _MECHANIC_PCT) public onlyOwner {
        require(_MECHANIC_PCT < 100, "Percent going to mechanics is too high!");
        require(_MECHANIC_PCT > 0, "Percent going to mechanics is too small!");
        MECHANIC_PCT = _MECHANIC_PCT;

        //Emit Mechanic Percent was updated
        emit MechanicPercentUpdated(MECHANIC_PCT);
    }

    /**
     * Set the minimum number of blocks that have to pass for a bonus to be claimable
     */
    function setBonusReleaseTime(uint releasetime) public onlyOwner {
        bonusReleaseTime = releasetime;
        
        //Emit that the bonus release time was updated
        emit BonusReleaseTimeUpdated(bonusReleaseTime);
    }

    /*
     * Sets the bonus tokens amount for a given address. 
     */
    function addBonusTokensBalance(address bonusAddress, uint256 bonus_tokens_amount) internal {
        //Get the current block, and add the delta block number for reward release
        uint releaseBlock = block.number + bonusReleaseTime;

        //Tell Nitro protocol to update token balance for this address
        _addToTimelockedBonus(bonusAddress, bonus_tokens_amount, releaseBlock);
    }

//////////////////----------------Modify Contract Variables----------------///////////////

    /**
     * @dev Min time elapsed before twap is updated.
     */
    function setMinDeltaTwap(uint256 _minDeltaTwapLong, uint256 _minDeltaTwapShort) public onlyOwner {
        require(_minDeltaTwapLong > 1 seconds, "Minimum delTWAP (Long) is too small!");
        require(_minDeltaTwapShort > 1 seconds, "Minimum delTWAP (Short) is too small!");
        require(_minDeltaTwapLong > _minDeltaTwapShort, "Long delta is smaller than short delta!");
        minDeltaTwapLong = _minDeltaTwapLong;
        minDeltaTwapShort = _minDeltaTwapShort;
    }

    /**
     * @dev Sets a whitelisted sender/receiver (nitro protocol does not apply).
     */
    function setWhitelistedSender(address _address, bool _whitelisted) public onlyOwner {
        whitelistedSenders[_address] = _whitelisted;
    }

    /**
     * @dev Sets a known exchange address (tokens sent from these addresses will count as buy orders, tokens sent to these addresses count as sell orders)
     */
    function setExchangeAddress(address _address, bool _isexchange) public onlyOwner {
        exchangeAddresses[_address] = _isexchange;

        emit ExchangeListUpdated(_address, _isexchange);
    }


    function _isWhitelistedSender(address _sender) internal view returns (bool) {
        return whitelistedSenders[_sender];
    }    

    //Public to allow us to easily update exchange addresses in the future
    function isExchangeAddress(address _sender) public view returns (bool) {
        return exchangeAddresses[_sender];
    }

//                  ------------------ Nitro Implementation ---------------------                //

    function _transfer(address sender, address recipient, uint256 amount)
        internal
        virtual
        override
        whenNotPausedOrInitialDistribution(sender)
    {
        //If this isn't a whitelisted sender(such as, this contract itself, the distribution address, or the router)
        if(!_isWhitelistedSender(sender)){

            //if msg sender is an exchange, then this was a buy
            if(isExchangeAddress(sender)){
                _updateShortTwap();
                _updateLongTwap();

                //Calculate how many bonus tokens they've received
                uint256 currentNitro = calculateCurrentNitroRate(true);
                uint256 bonus_tokens_amount = currentNitro.mul(amount).div(scaleFactor);

                //These bonus tokens have to be saved in the timelockedBonuses
                //call nitro function for adding bonus tokens to this address
                addBonusTokensBalance(recipient, bonus_tokens_amount);

                //Emit a bonus tokens balance update
                emit BonusBalanceUpdated(recipient, getBonusAmount(recipient));

            //if recipient is an exchange, then this was a sell
            }else if(isExchangeAddress(recipient)) {
                _updateShortTwap();
                _updateLongTwap();

                //Calculate how many tokens need to be removed from the order
                uint256 currentNitro = calculateCurrentNitroRate(false);
                uint256 removed_tokens_amount = currentNitro.mul(amount).div(scaleFactor);
                //Remove the tokens from the amount to be sent
                amount = amount.sub(removed_tokens_amount);

                //Split the removed tokens amount between mechanics and nitro protocol
                uint256 mechanics_tokens = MECHANIC_PCT.mul(removed_tokens_amount).div(100);
                uint256 nitro_tokens = removed_tokens_amount.sub(mechanics_tokens);

                //Send the nitro tokens to this contract
                super._transfer(sender, address(this), nitro_tokens);

                //Send the mechanics tokens to the staking contract, if there is one
                if(stakingContractAddress!=address(0)){
                    super._transfer(sender, address(stakingContractAddress), mechanics_tokens); //TEST address wrapper on stakingcontractaddress crashing transfer function
                }

            }
        }
        
        super._transfer(sender, recipient, amount);
    }


//                  ------------------ TWAP Functions ---------------------                //  
    /*
     * This function updates the long TWAP, if minDeltaTwapLong has passed
     */
    function _updateLongTwap() internal virtual returns (uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLastLong; // overflow is desired

        if (timeElapsed > minDeltaTwapLong) {
            uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224((priceCumulative - priceCumulativeLastLong) / timeElapsed)
            );

            priceCumulativeLastLong = priceCumulative;
            blockTimestampLastLong = blockTimestamp;

            priceAverageLastLong = FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));

            emit LongTwapUpdated(priceCumulativeLastLong, blockTimestampLastLong, priceAverageLastLong);
        }

        return priceAverageLastLong;
    }

    /*  
     * This function updates the most realtime price you can possibly get, given a short mindeltatwapshort (5-10 minutes)
     */
    function getCurrentShortTwap() public view returns (uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
        );

        return FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));
    }

    /*
     * Use this function to get the current short TWAP
     */
    function getLastShortTwap() public view returns (uint256) {
        return priceAverageLast;
    }

    /*
     * Use this function to get the current 48-hour TWAP
     */
    function getLastLongTwap() public view returns (uint256) {
        return priceAverageLastLong;
    }
    
    /*
     * This function updates the short TWAP Given the short TWAP period has passed
     */
    function _updateShortTwap() internal virtual returns (uint256) {
        (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        if (timeElapsed > minDeltaTwapShort) {
            uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;

            // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
            FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
                uint224((priceCumulative - priceCumulativeLast) / timeElapsed)
            );

            priceCumulativeLast = priceCumulative;
            blockTimestampLast = blockTimestamp;

            priceAverageLast = FixedPoint.decode144(FixedPoint.mul(priceAverage, 1 ether));

            emit TwapUpdated(priceCumulativeLast, blockTimestampLast, priceAverageLast);
        }

        return priceAverageLast;
    }

    /** 
     * @dev Initializes the TWAP cumulative values for the burn curve.
     */
    function initializeTwap() external onlyInitialDistributionAddress {
        require(blockTimestampLast == 0, "Both TWAPS already initialized");
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = 
            UniswapV2OracleLibrary.currentCumulativePrices(uniswapPair);

        uint256 priceCumulative = isThisToken0 ? price1Cumulative : price0Cumulative;
        
        //Initialize the short TWAP values
        blockTimestampLast = blockTimestamp;
        priceCumulativeLast = priceCumulative;
        priceAverageLast = INITIAL_TOKENS_PER_ETH;

        //Initialize the long TWAP values
        blockTimestampLastLong = blockTimestamp;
        priceCumulativeLastLong = priceCumulative;
        priceAverageLastLong = INITIAL_TOKENS_PER_ETH;
    }
//                  ------------------ User Functions ---------------------                //

    /**
     * Public function that allows users to claim their bonus $LAMBO.
     * We need to ensure we only interact with msg.sender to make sure no one can claim another's tokens by submitting an address
     */
    function claimBonusTokens() public {

        //Save bonus amount
        uint256 bonusTokens = getBonusAmount(msg.sender);

        //Assert that the bonus tokens amount is not zero
        require(bonusTokens > 0, "There are no bonus tokens to be claimed");
        //Assert that the current block number is 
        require(getBonusUnlockTime(msg.sender) <= block.number, "The token release time has not been reached yet.");
        //Assert that this contrat can actually afford to give this user their bonus tokens
        require(balanceOf(address(this)) > bonusTokens, "The contract can't afford to pay this bonus.");

        /////////Contract is cleared to transfer the bonus tokens

        //Remove the bonus tokens from the nitro protocol
        _removeTimelockedBonus(msg.sender);

        //Emit a bonus tokens balance update
        emit BonusBalanceUpdated(msg.sender, getBonusAmount(msg.sender));

        //Transfer the removed bonus tokens 
        _transfer(address(this), msg.sender, bonusTokens);

        //Emit a paid bonus balance
        emit BuyerBonusPaid(msg.sender, bonusTokens);
    }

    /*
     * Function if for some reason the predicted trading pair address doesn't match real life trading pair address.
     */
    function setUniswapPair(address newUniswapPair) public onlyOwner {
        setExchangeAddress(uniswapPair, false);

        uniswapPair = newUniswapPair;

        setExchangeAddress(uniswapPair, true);
    }

    /*
     * Calculates the current running % for the Nitro protocol. That is,
     * The percent bonus tokens for any buyers at the current moment
     * The percent tokens removed for any sellers at the current moment
     * This is calculated using the TWAP and the realtimeprice. Calling this DOESN'T Update the TWAP. 
     *
     * Returns a uint256 of 0.XX * 1 eth units, where XX is the current % (6% will return 0.06*1ether)
     */
    function calculateCurrentNitroRate(bool isBuy) public view returns (uint256) {
        //The units on both of these is tokens per eth
        uint256 currentRealTimePrice = getLastShortTwap(); 
        
        uint256 currentTwap = getLastLongTwap();
        uint256 nitro;

        //Calculate the Nitro rate based on which is larger to keep it positive
        if(currentRealTimePrice > currentTwap){
            //Calculation explanation:
            //(RTP-TWAP)*scaleFactor/TWAP is typical percent calc but with the scaleFactor moved up b/c uint256
            // The *scaleFactor.dv has to cancel out the scaleFactor to get back to fractions of 100, but in units of ether
            nitro = (currentRealTimePrice.sub(currentTwap).mul(scaleFactor).div(currentTwap))*scaleFactor.div(scaleFactor);
        }
        else{
            //Simply the above calculation * -1 to offset the negative
            nitro = (currentTwap.sub(currentRealTimePrice).mul(scaleFactor).div(currentTwap))*scaleFactor.div(scaleFactor);
        }

        //Validate that the nitro value is within the defined bounds
        uint256 refBuyBonus = (maxBuyBonus()*scaleFactor.div(100));
        uint256 refMaxSell  = (maxSellRemoval()*scaleFactor.div(100));
        if(isBuy && nitro > refBuyBonus){
            return refBuyBonus;
        }else if (!isBuy && nitro > refMaxSell){
            return refMaxSell;
        }
        return nitro;
    }
}