pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


// 
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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

// 
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
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

interface IRewardDistributionRecipient {
    function notifyRewardAmount(uint256 reward) external;
}

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract ERC20TransferLiquidityLock is ERC20 {
    using SafeMath for uint256;

    event LockLiquidity(uint256 tokenAmount, uint256 ethAmount);
    event RewardLiquidityProviders(uint256 tokenAmount);

    address internal constant uniswapV2Router = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address internal constant uniswapFactory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address public uniswapV2Pair;

    address public liquidityLoop;

    // the amount of tokens to lock for liquidity during every transfer, i.e. 100 = 1%, 50 = 2%, 40 = 2.5%
    uint256 public liquidityLockDivisor;

    // receive eth from uniswap swap
    receive() payable external {}

    function rewardLiquidityProviders() external {
        // lock everything that is lockable
        _lockLiquidity(balanceOf(address(this)));
    }

    function _lockLiquidity(uint256 _lockableSupply) internal {
        // lockable supply is the token balance of this contract
        require(_lockableSupply <= balanceOf(address(this)), "ERC20TransferLiquidityLock::lockLiquidity: lock amount higher than lockable balance");
        require(_lockableSupply != 0, "ERC20TransferLiquidityLock::lockLiquidity: lock amount cannot be 0");

        uint256 amountToSwapForEth = _lockableSupply.div(2);
        uint256 amountToAddLiquidity = _lockableSupply.sub(amountToSwapForEth);

        // needed in case contract already owns eth
        uint256 ethBalanceBeforeSwap = address(this).balance;
        _swapTokensForEth(amountToSwapForEth);
        uint256 ethReceived = address(this).balance.sub(ethBalanceBeforeSwap);

        _addLiquidity(amountToAddLiquidity, ethReceived);
        emit LockLiquidity(amountToAddLiquidity, ethReceived);

        uint256 liquidityLoopRewardsAmount = ERC20(uniswapV2Pair).balanceOf(address(this));
        ERC20(uniswapV2Pair).transfer(address(liquidityLoop), liquidityLoopRewardsAmount);
        IRewardDistributionRecipient(liquidityLoop).notifyRewardAmount(liquidityLoopRewardsAmount);
    }    

    function _swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory uniswapPairPath = new address[](2);
        uniswapPairPath[0] = address(this);
        uniswapPairPath[1] = IUniswapV2Router02(uniswapV2Router).WETH();

        _approve(address(this), uniswapV2Router, tokenAmount);

        IUniswapV2Router02(uniswapV2Router)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                tokenAmount,
                0,
                uniswapPairPath,
                address(this),
                block.timestamp
            );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), uniswapV2Router, tokenAmount);

        IUniswapV2Router02(uniswapV2Router)
            .addLiquidityETH{ value: ethAmount }
            (
                address(this),
                tokenAmount,
                0,
                0,
                address(this),
                block.timestamp
            );
    }

    function lockableSupply() external view returns (uint256) {
        return balanceOf(address(this));
    }
}

// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNWMWXKNMMMMNNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXNXKNWkdKN0xKWkl0MMMWkdXMMMMMWKKNNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOKWWxoKXXWMOl0MWdlXOl0MMWXOlxWMMMNxoKWWK0WNKKNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX0KWMXllXMKld0KWMKlkMWkdXOlOWXXXNkl0MMMOcOMMMWW0oxXWKkKMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXdlxXN0odKKolkkOOOloKKOKNOdO0kOXNKdxXNXkldOOkOOloXWMKlkM0oOXXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMMMN0xdxkdcllcccccccccodkO0KKKKKK0K0OxdolccclllllcloxkooX0ldXkoKMNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxxNMMMMMMMX0xccccccccccccccccccldO0KKKK0Odl:clodddddddddddoccdxlx0xx0WNxdKXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNMMWKodXMMNXWNOocccc:;;;;;;;;;::cccccldO0KOdc:coddolllcccllllodddl:lKkoKMKooKKokMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxxOXWNdo0XOk0dlc:;,'''.''.....'',;:ccccoxxo::lddlcccccccccccccclodocldxKklxXXOkOkOKXNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMWXNMMWKkxdxxOxx00Odc:;''............,''.',;:cc::::ldoccccc::;;::::::c:clddclk0kkNWMNklxXWN00WMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMWWXXNWMNKNWKxk0KK0xc;'.',c,..,.     .cOko:,',;c::;:odloxOOo;cc,',,,,;loccldo:o0KKKXN0o0MMW0lkWWNWMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMW0xxkkxdkXK0KKKKKKK0o,'';d0K: 'o,.cxc. ;XMWXx:'';;;,:dxOKNN0c;od:cxxl,,dK0dldo;lOKKK0K0OKX0xokX0dxKNMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMWWWNK000OkxO00KKKKKKKOl'.,dXWWo. ,'.lOo. lXXOo:'..'''':dooxOK0o,:l:lkOl,;kXXKxdo,ckK00KKK00OO0KOdokKkkNMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWNKOkxOXNXKXXKKK0KKKK0Oxl;,',:lxd;.    .. .cc;''..'',,,';odcccldo:;;,,;;,;okkdloxdclkOOO0KKKKKK0dd0OxOx0WMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMK0WWN0ddXX00K0KKKKK0Odlccc:;,'..''.............''',,,,,,,cdoccccccc::::::cccccldkkxxkxxk0KKKKKK00KOoOWMWWNXXWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMM0dkNMMWOOKKKKKKKK0Odlcccccccc:;,''.........'''',,,,,,,,,,,codlcccccccccccccclodocccccc:cdO0KKKKKKKkx0XNXKdoKWMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMKxOXKxdkO000KKKKKKK0xlccccccccccccc:;;,,,,,,,;;;;,,,,,,,,,,,,,;lodollccccccclodddl:::::::;::lx0KKKKKK000NW0odXWNKXMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWXKOxxxk0K00KKKKKKKKOdlcccccccccccccccccccccccc:;;,,,,,,,,,,,,,,,,;clodddddddddooc::::;::;:::::cd0KKKKKKKKKkokNMWXkxKMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMWKOKWMWKkdk0KKKKKKKKOdcccccccccccccccccccccccc:;;,,,,,,,,,,,,,,,,,,,,,,;:clllcc::;:::;:::;::;::;::d0KKKKKKKKO0XXOxxxkOXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWXkxxkKNWWX0KKKKKKKK0xlcccccccccccccccccccccc:;;,,,,,,,,,,,,,,,,,,,,,,,,,,,;;:::::::::::::;::;::::;cx0KKKKKKKK0xdx0NWWKKNMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMN0KNKkxdxOKKKKKKKKKKkoccccccccccccccc:::::cc:;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;::::::::::::::::::::::lkKKKKKKKKK0KWMWXOkdkNMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWWNWWWNKO0KKKKKKKKK0xlcccccccccc::::::::::::::;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:::::::::::::::::::::::::x00KK0KK0KKKOxxxkOKNWMMMMMMMMMMMMMM
// MMMMMMMMMMMMMNOxkxxkxk0KKKKKKKKKK0dcccccccccc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::;:d0KKKKKKKKKKO0X0xxxO0XWMMMMMMMMMMMM
// MMMMMMMMMMMMMWNXKKXWX0KKKKKKKKKKK0dcccccccccc::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::d0KKKKK0KKKKKKOxOXWWNKXMMMMMMMMMMMM
// MMMMMMMMMMMNXNWMWNX00KKKKKKKKKKKK0xlccccccccc:::::::;;,,,,;;;;;;;;::::::::::::::::::;;;;;;;;,,,,;:::::::::::::::::cx0KKKKKKKKKKK00KNWNKkxKMMMMMMMMMMMM
// MMMMMMMMMMMNXNXKkkOO0KKKKKKKKKKKKKOoccccccccc::::::::;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,;;;;:::::::::::::::::lOKKKKKKKKKKKKK00OkxxkXWWMMMMMMMMMMM
// MMMMMMMMMMW0kxxxxO0KKKKKKKKKKKKKKK0xlcccccccccc:::::::::::::;;;;;;;,,,,,,,,,,,,,,,,,;;;;;;;::::::::::::::::::::::cx0KKKKKKKKKKKKKKKXXNNNKxOWMMMMMMMMMM
// MMMMMMMMMMXkxOKNNXKKKKKKKKKKKKKKKKK0xlccccccccccc:::::::::::::::::::::::::::::::::::::::::::::::::::::::::;:::::cd0KKKKKKKKKKKKKKK00NNKxoxXMMMMMMMMMMM
// MMMMMMMMMMWNNWWWN0O0KKKKKKKKKKKKKKKK0xlccccccccccccc:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::cx0KKKKKKKKKKKKKKKKKXKxldKNKXMMMMMMMMMM
// MMMMMMMMMWKkxkOkxkOKKKKKKKKKKKKKKKKKK0koccccccccccccccccc:::::::::::::::::::::::::::::::::::::::::::::::::;:::lk0KKKKKKKKKKKKKKKKKKKOkKNNNNNMMMMMMMMMM
// MMMMMMMMMXkk0xdkO00KKKKKKKKKKKKKKKKKKK00xlccccccccccccccccccccccccccccccc::::::::::::::::::;::::::::::::::::lxOKKKKKKKKKKKKKKKKKK0K0OXMMMMMMMMMMMMMMMM
// MMMMMMMMMNOkkxxkxx0KKKKKKKKKKKKKKKKKKKKK0Oxolccccccccccccccccccccccccccccc::::::::::::::;;:::::;;;:::::;::lxO0KKKKKKKKKKKKKKKKKKKKKKXWMMMMMMMMMMMMMMMM
// MMMMMMMMMNXNMMMN0O0KKKKKKKKKKKKKKKKKKKKKKK0Okdlccccccccccccccccccccccccccc:::::::::::::::::::::;;::::::coxO0KKKKKKKKKKKKKKKKKKKKKKKKNMMMMMMMMMMMMMMMMM
// MMMMMMMMMXKNNKKWKO0KKKKKKKKKKKKKKKKKKKKKKKKK0kl,,;cccccccccccccccccccccccc:::::::::::::::::::::;;;;;,',oO0K0KKKKKKKKKKKKKKKKKKKKKKKKKOxxxk0NMMMMMMMMMM
// MMMMMMMMMXkxxddkxx0KKKKKKKKKKKKKKKKKKKKKK0Od:.    .lxolccccccccccccccccccc:::::::::::::::::::;:clo:.    .:dO0KKKKKKKKKKKKKKKKKKKKKK0O0KXX0OKWMMMMMMMMM
// MMMMMMMMMNK0KXNNNKKKKKKKKKKKKKKKKKKKKK0Odl:.       'ONKOdlcccccccccccccccc:::;:::::;;::;:;;:cdOKXx.       .,cdk0KKKKKKKKKKKKKKKKKK00KXWMMWNXWMMMMMMMMM
// MMMMMMMMMWKKNNNXKOOKKKKKKKKKKKKKKKK0kdc;,,'.        'OWMWKkl:::::::ccccccc:::;::::;;;:;;;:lkKWMWx.         ...,:ok00KK0KKKKKKKKKKK0OkKNMMNKXMMMMMMMMMM
// MMMMMMMMMW0xkkkkxxOKKKKKKKKKKKK0Oxoc;,,,,,'          'OWMMWXOdc;;;;;::::::;;;;;;;;;;;;;cd0NWMMWx.          ......';lxO0KKKKKKK0KKKK0KXXNWMMMMMMMMMMMMM
// MMMMMMMMMMKOKNMMMWNKKKKKKKKK0kdl:,,,,,,,,,.           'OWMMMMWKxl:;;;;;;;;;;;;;;;;;;:okKWMMMMWx.           .........',cdk0KKKKKKKK0KX0kxxkXMMMMMMMMMMM
// MMMMMMMMMMWKKNNN0kOKK0KK00kdc;,,,,,,,,,,,,.            'kWMMMMMWNOdc;;;;;;;;;;;;;;cd0NWMMMMMWx.            .............,:ok0KKKKKkxxxkkO0NMMMMMMMMMMM
// MMMMMMMMMMMXKNKxlkXNK0Oxoc;,,,,,,,,,,,,,,'.             'kWMMMMMMMWKkl:;;;;;;;;:okKWMMMMMMMWx.             ................';lxO0OddO0XWMMMMMMMMMMMMMM
// MMMMMMMMMMMMNOodKNN0xl:,,,,,,,,,,,,,,,,,,,'...           .kWMMMMMMMMWN0dc;;;:lx0NMMMMMMMMMWx.             ....................';lk0Oxdxxx0WMMMMMMMMMMM
// MMMMMMMMMMMMKdONNNNXo,,,,,,,,,,,,,,,,,,,,,,,,''...        .kWMMMMMMMMMMWKxookXWMMMMMMMMMMWd.         ...........................'lkkkkO0OXMMMMMMMMMMMM
// MMMMMMMMMMMMWNNXOkxxdc;,,,,,,,,,,,,,,,,,,,,,,'...          .kWMMMMMMMMMN0occo0NMMMMMMMMMWd.           .........................'dNWWW0xOXMMMMMMMMMMMMM
// MMMMMMMMMMMMMNkdkOKNMNd;,,,,,,,,,,,,,,,,,,,,'.              .kWMMMMMWXOo:;,'';lONMMMMMMNd.              .......................,oOKNMNKXMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMWWMMMMMWx;,,,,,,,,,,,,,,,,,,,,,'..             .kWMMMWXxc;;;,'''':xXWMMMNd.              ......................'o00kxxxkOXMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMWKK0xdko,,,,,,,,,,,,,,,,,,,,,,'..            .xWWXKK0ko:;,',:ok0KKNWNd.             ........................,kWMMWXkxKMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMWOdkOkkxl:;,,,,,,,,,,,,,,,,,,,,,,''.           .d0KKKKKOo;,',oOKKKKK0l.           .........................'lxxdxOXXKXMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMX0kxdxOKOl,,,,,,,,,,,,,,,,,,,,,,,,,'.          .l0KK0Oo:;,'';oOKKKOc.          ....,,....................,l0WXkxxdkNMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMKk0NWMNXKx;',,,,,,,,,,,,,,,,,,,,,,,,'..        .l00kl;;;,''',lkKOc.         ...'ckXKd;.................'cOXWWXXXKXWMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMXKNNOkxdoo:,,,,,,,,,,,,,,,,,,,,,,,,,'..       .lkdlllllccc:,cdc.        ...,lONMMMWXxokOo,.........'lOkdokXWNKNMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMNXKkddkKKOxc,,,,,,,,,,,,,,,,,,,,,,,,,,''.      .cxxxxxxxxdl,'.       ....,o0NWWWWWWWWWWMWKd;.....,ldxkkO0xdkNMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMWKkKN0odOXKd,',,,,,,,,,,,,,,,,,,,,,,,,,,'.      ';:::;,,,,'.      ......;loooooooooooooool:'...:OWMMWKxx0KXWMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMKdOWMXkodxl;,,,,,,,,,,,,,,,,,,,,,,,,,,'..    .,;;,,'''.     .........'''''''''''''''''..,cllkNMMMMNKXWMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMNKXKxoxXWKodd:,,,,,,,,,,,,,,,,,,,',,,,,,'..   .,;,'''.    ............................,cok00xokNMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMWXkxXWNXxc0WOl;,,,,,,,,,,,,,,,,,,,,,,,,,,,'.  .,,''.  ............................',cONXkodXKddXMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNKXNdoXNXXd:lc;,,,,,,,,,,,,,,,,,,,,,,,,,'...'.. ...........................';ck0ddXMMXdkWWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNWNooKNWXldNNxc;,,,,,,,,,,,,,,,,,,,,,,,,,''............................';ckXNXNNXXNWNKXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0OWMMOlkXXNXd:dd:,,,,,,,,,,,,,,,,,,,,,,,'.......................,cook0xdxkO0XWNKKNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWkxXWWMMOlOXOkdll:,,,,,,,,,,,,,,,,,,'...................,ll;lKWKXWWK0Okdd0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMWNN0cxWMWXXXd:doll:,,,,,,,,,,,,'..........,;;';dkkclXMXxodOXWMWKKWWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXKNXodWMWX0klkNNNWxckd:d0Oooxkocclocoxdxkol0NdlXMMKlxWMWXkokWMMWNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW00WXKNKodNMMMNodWXldXXXWMMOllxNXXWXNMXoxWKlkWWWOlOK0WMNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNN0xKMMMMOlOMMklOXWMMMN0xdoxXWXNMWdoXWdlKX0KO0XXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0kNMMXxOWMMMMNKKXKdOWKKWMOdKWXOXWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMMWNXNNXWMNNWMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
// https://Newspaper.finance
contract N3WS is ERC20Burnable, ERC20TransferLiquidityLock, Ownable {

    mapping (address => bool) internal whitelistedSenders;

    enum ArticleType {
        Cover,
        Column,
        Ad
    }

    struct ArticleInfo {
        uint256 id;
        string title;
        string subTitle;
        string body;
        ArticleType articleType;
        string imageUrl;
        uint256 publicationDate;
        uint256 price;
        address owner;
    }

    uint256 public constant MIN_ARTICLE_PRICE = 1 ether; // 1 $N3WS

    uint256 internal maxColumnArticles = 5;

    uint256 internal maxAdArticles = 4;

    mapping (uint256 => ArticleInfo) public articles;

    uint256 public totalArticles;

    uint256 public lastCoverArticle;

    uint256[] public lastColumnArticles;

    uint256[] public lastAdArticles;

    event ArticlePosted(
        uint256 id,
        string title,
        string subTitle,
        string body,
        ArticleType articleType,
        string imageUrl,
        uint256 publicationDate,
        uint256 price,
        address owner
    );

    constructor() 
    public
    Ownable()
    ERC20("Newspaper.finance", "N3WS")
    {
        liquidityLockDivisor = 10;
        _mint(msg.sender, 1_000_000 ether);
    }

    function setUniswapV2Pair() external onlyOwner returns (address) {
        require(uniswapV2Pair == address(0), "N3WS: pair already set");
        uniswapV2Pair = IUniswapV2Factory(address(uniswapFactory)).createPair(
            IUniswapV2Router02(address(uniswapV2Router)).WETH(),
            address(this)
        );        
        setWhitelistedSender(uniswapV2Pair, true);
        return uniswapV2Pair;
    }

    function setLiquidityLoop(address _liquidityLooop) external onlyOwner {
        // require(liquidityLoop == address(0), "N3WS: liquidity loop already set");
        liquidityLoop = _liquidityLooop;
    }

    function setLiquidityLockDivisor(uint256 _liquidityLockDivisor) external onlyOwner {
        if (_liquidityLockDivisor != 0) {
            require(_liquidityLockDivisor >= 10, "N3WS: liquidity lock divisor too small");
        }
        liquidityLockDivisor = _liquidityLockDivisor;
    }

    function setWhitelistedSender(address _address, bool _whitelisted) public onlyOwner {
        whitelistedSenders[_address] = _whitelisted;
    }    

    function postArticle(string calldata _title, string calldata _body, string calldata _subTitle, ArticleType _articleType, string calldata _imageUrl) 
    external 
    {
        uint256 newArticleId = ++totalArticles;

        ArticleInfo memory oldArticle;
        if (_articleType == ArticleType.Cover) {
            oldArticle = articles[lastCoverArticle];
            lastCoverArticle = newArticleId;
        } else if (_articleType == ArticleType.Column) {
            if (lastColumnArticles.length > 0) {
                if (lastColumnArticles.length == maxColumnArticles) {
                    oldArticle = articles[lastColumnArticles[0]];
                    _shiftLeft(lastColumnArticles);
                }
            }
            lastColumnArticles.push(newArticleId);
        } else if (_articleType == ArticleType.Ad) {
            if (lastAdArticles.length > 0) {
                if (lastAdArticles.length == maxAdArticles) {
                    oldArticle = articles[lastAdArticles[0]];
                    _shiftLeft(lastAdArticles);
                }
            }
            lastAdArticles.push(newArticleId);
        } else {
            revert("N3WS: invalid article type");
        }

        uint256 articlePrice = MIN_ARTICLE_PRICE;
        if (oldArticle.price > 0) {
            articlePrice = oldArticle.price;
            if (oldArticle.publicationDate < block.timestamp + 1 weeks) {
                articlePrice *= 2;
            }
        }

        super._burn(msg.sender, articlePrice);
        
        ArticleInfo memory newArticle = ArticleInfo({
            id: totalArticles,
            title: _title,
            body: _body,
            subTitle: _subTitle,
            articleType: _articleType,
            imageUrl: _imageUrl,
            publicationDate: block.timestamp,
            price: articlePrice,
            owner: msg.sender
        });
        articles[newArticle.id] = newArticle;

        emit ArticlePosted(newArticle.id, newArticle.title, newArticle.body, newArticle.subTitle, 
            newArticle.articleType, newArticle.imageUrl, newArticle.publicationDate, newArticle.price, newArticle.owner);
    }

    function setMaxColumnArticles(uint256 _maxColumnArticles) external onlyOwner {
        maxColumnArticles = _maxColumnArticles;
    }

    function setMaxAdArticles(uint256 _maxAdArticles) external onlyOwner {
        maxAdArticles = _maxAdArticles;
    }

    function getCoverArticle() external view returns(ArticleInfo memory) {
        return articles[lastCoverArticle];
    }

    function getColumnArticles() external view returns(ArticleInfo[] memory) {
        ArticleInfo[] memory columnArticles = new ArticleInfo[](lastColumnArticles.length);
        for (uint256 i = 0; i < lastColumnArticles.length; i++) {
            columnArticles[i] = articles[lastColumnArticles[i]];
        }
        return columnArticles;
    }

    function getAdArticles() external view returns(ArticleInfo[] memory) {
        ArticleInfo[] memory adArticles = new ArticleInfo[](lastAdArticles.length);
        for (uint256 i = 0; i < lastAdArticles.length; i++) {
            adArticles[i] = articles[lastAdArticles[i]];
        }
        return adArticles;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        if (liquidityLockDivisor != 0 && from != address(this) && !whitelistedSenders[from]) {
            uint256 liquidityLockAmount = amount.div(liquidityLockDivisor);
            super._transfer(from, address(this), liquidityLockAmount);
            super._transfer(from, to, amount.sub(liquidityLockAmount));
        }
        else {
            super._transfer(from, to, amount);
        }
    }

    // function _initializePair() internal {
    //     (address token0, address token1) = UniswapV2Library.sortTokens(address(this), address(WETH));
    //     isThisToken0 = (token0 == address(this));
    //     uniswapPair = UniswapV2Library.pairFor(uniswapV2Factory, token0, token1);
    //     setWhitelistedSender(uniswapPair, true);
    // }

    function _shiftLeft(uint256[] storage arr) internal {
        for (uint256 i = 0; i < arr.length - 1; i++) {
            arr[i] = arr[i + 1];
        }
        // delete arr[arr.length - 1];
        // arr.length--;
        arr.pop();
    }
}