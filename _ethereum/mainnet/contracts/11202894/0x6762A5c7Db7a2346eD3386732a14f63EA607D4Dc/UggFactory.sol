// File: contracts\openzeppelin\contracts\utils\ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
    // function average(uint256 a, uint256 b) internal pure returns (uint256) {
    //     // (a + b) / 2 can overflow, so we distribute
    //     return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    // }
}

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
    // function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    //     return mod(a, b, "SafeMath: modulo by zero");
    // }

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
    // function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    //     require(b != 0, errorMessage);
    //     return a % b;
    // }
    
    function sqrt(uint256 y) internal pure returns (uint256) {
        if (y > 3) {
            uint256 z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
            return z;
        } else if (y != 0) {
            return 1;
        } else {
            return 0;
        }
    }
}

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


library UniERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(0));
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value >= amount, "UniERC20: not enough value");
                if (msg.value > amount) {
                    // Return remainder if exist
                    msg.sender.transfer(msg.value.sub(amount));
                }
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
        }
    }

    // function uniSymbol(IERC20 token) internal view returns(string memory) {
    //     if (isETH(token)) {
    //         return "ETH";
    //     }

    //     (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
    //         abi.encodeWithSignature("symbol()")
    //     );
    //     if (!success) {
    //         (success, data) = address(token).staticcall{ gas: 20000 }(
    //             abi.encodeWithSignature("SYMBOL()")
    //         );
    //     }

    //     if (success && data.length >= 96) {
    //         (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
    //         if (offset == 0x20 && len > 0 && len <= 256) {
    //             return string(abi.decode(data, (bytes)));
    //         }
    //     }

    //     if (success && data.length == 32) {
    //         uint len = 0;
    //         while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
    //             len++;
    //         }

    //         if (len > 0) {
    //             bytes memory result = new bytes(len);
    //             for (uint i = 0; i < len; i++) {
    //                 result[i] = data[i];
    //             }
    //             return string(result);
    //         }
    //     }

    //     return _toHex(address(token));
    // }

    function _toHex(address account) private pure returns(string memory) {
        return _toHex(abi.encodePacked(account));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        uint j = 2;
        for (uint i = 0; i < data.length; i++) {
            uint a = uint8(data[i]) >> 4;
            uint b = uint8(data[i]) & 0x0f;
            str[j++] = byte(uint8(a + 48 + (a/10)*39));
            str[j++] = byte(uint8(b + 48 + (b/10)*39));
        }

        return string(str);
    }
}

interface IOracle {
    function fee() external view returns(uint256);
    function ary() external view returns(uint256);
    function year() external view returns(uint256);
    function feeDev() external view returns(uint256);
    function feeFinance() external view returns(uint256);
    function getDeveloper() external view returns(address payable);
    function getFinance() external view returns(address payable);
    function getInvestor() external view returns(address payable);
    function devRatio() external view returns(uint256);
    function investorRatio() external view returns(uint256);
    function weightDenominator() external view returns(uint256);
    function varSwapRatio() external view returns(uint256);
    function dailyStakingReward() external view returns(uint256);
    function varStakingRatio() external view returns(uint256);
    function feeWithdraw() external view returns(uint256);
    function nGenerate() external view returns(uint256);
    function toggleOn() external view returns(bool);
    function standardLiquiditySize() external view returns(uint256);
    function rewardThreshold() external view returns(uint256);
}

interface IFactory {
    function uggCollect(address to, uint256 value) external;
}


library VirtualBalance {
    using SafeMath for uint256;

    struct Data {
        uint216 balance;
        uint40 time;
    }

    uint256 public constant DECAY_PERIOD = 5 minutes;

    function set(VirtualBalance.Data storage self, uint256 balance) internal {
        self.balance = uint216(balance);
        self.time = uint40(block.timestamp);
    }

    function update(VirtualBalance.Data storage self, uint256 realBalance) internal {
        set(self, current(self, realBalance));
    }

    function scale(VirtualBalance.Data storage self, uint256 realBalance, uint256 num, uint256 denom) internal {
        set(self, current(self, realBalance).mul(num).add(denom.sub(1)).div(denom));
    }

    function current(VirtualBalance.Data memory self, uint256 realBalance) internal view returns(uint256) {
        uint256 timePassed = Math.min(DECAY_PERIOD, block.timestamp.sub(self.time));
        uint256 timeRemain = DECAY_PERIOD.sub(timePassed);
        return uint256(self.balance).mul(timeRemain).add(
            realBalance.mul(timePassed)
        ).div(DECAY_PERIOD);
    }
}

// used for x ARY x（N / 525600）
library DepositValue {
    using SafeMath for uint256;

    struct Data {
        uint256 stakingSpeed;
        uint40 time;
    }

    function getSpeed(Data memory self) internal pure returns(uint256) {
        return self.stakingSpeed;
    }

    function getValue(Data memory self) internal view returns(uint256) {
        uint40 _now = uint40(block.timestamp);
        if(self.stakingSpeed == 0) {
            return 0;
        }
        uint256 value = self.stakingSpeed.mul(uint256(_now - self.time));
        return value;
    }

    function addValue(Data storage self, uint256 value, uint256 duration) internal {
        self.stakingSpeed = self.stakingSpeed.add(value.div(duration));
        self.time = uint40(block.timestamp);
    }

    function removeValue(Data storage self, uint256 value, uint256 duration) internal {
        if(self.stakingSpeed > value.div(duration)) {
            self.stakingSpeed = self.stakingSpeed.sub(value.div(duration));
        } else {
            self.stakingSpeed = 0;
        }
        self.time = uint40(block.timestamp);
    }
}


contract UggSwap is ERC20, ReentrancyGuard {
    //using Sqrt for uint256;
    using SafeMath for uint256;
    using UniERC20 for IERC20;
    using VirtualBalance for VirtualBalance.Data;
    using DepositValue for DepositValue.Data;

    struct Balances {
        uint256 src;
        uint256 dst;
    }

    struct SwapVolumes {
        uint128 confirmed;
        uint128 result;
    }

    event Deposited(
        address indexed account,
        uint256 amount
    );

    event Withdrawn(
        address indexed account,
        uint256 amount
    );

    event Swapped(
        address indexed account,
        address indexed src,
        address indexed dst,
        uint256 amount,
        uint256 result,
        uint256 srcBalance,
        uint256 dstBalance,
        uint256 totalSupply
    );

    //uint256 public constant REFERRAL_SHARE = 20; // 1/share = 5% of LPs revenue
    uint256 public constant BASE_SUPPLY = 1000;  // Total supply on first deposit
    uint256 public constant FEE_DENOMINATOR = 1e18;
    uint256 public blockWeight = 1000;

    IOracle  public oracle;
    IFactory public factory;
    IERC20[] public tokens;
    mapping(IERC20 => bool) public isToken;
    mapping(IERC20 => SwapVolumes) public volumes;
    mapping(IERC20 => VirtualBalance.Data) public virtualBalancesForAddition;
    mapping(IERC20 => VirtualBalance.Data) public virtualBalancesForRemoval;

    mapping(address => DepositValue.Data) public depositValues;

    mapping(address => uint256) public uggBalances; // inner ugg tokens
    uint256 public uggTotalSupply;
    uint256 public lastGenerate;
    uint256 public blockRewardBalance = 0;

    uint256 public totalStakingSpeed = 0;
    uint256 public totalSwapSpeed = 0;
    uint256 public swapSpeedResetTime = 0;
    uint256 public totalSwapAmount = 0;

    constructor(IERC20[] memory assets, string memory name, string memory symbol, address _oracle) public ERC20(name, symbol) {
        require(bytes(name).length > 0, "Uggswap: name is empty");
        require(bytes(symbol).length > 0, "Uggswap: symbol is empty");
        require(assets.length == 2, "Uggswap: only 2 tokens allowed");

        oracle  = IOracle(_oracle);
        factory = IFactory(msg.sender);
        tokens = assets;
        for (uint256 i = 0; i < assets.length; i++) {
            require(!isToken[assets[i]], "Uggswap: duplicate tokens");
            isToken[assets[i]] = true;
        }
        lastGenerate = block.timestamp;
    }

    function generate() internal view returns(uint256) {
        if(lastGenerate == 0) {
            return 0;
        }
        if(oracle.toggleOn() == false) {
            return 0;
        }

        uint256 lpWeight = uint256(1000);
        
        //uint256 poolSize = uggTotalSupply;
        uint256 poolSize = totalSupply();

        if(uint256(poolSize) <= oracle.standardLiquiditySize()) {
            lpWeight = poolSize.mul(uint256(1000)).div(oracle.standardLiquiditySize());
        }
        uint256 adjustedN = lpWeight.mul(oracle.nGenerate()).div(uint256(1000));
        uint256 adjustedRewardThreshold = lpWeight.mul(oracle.rewardThreshold()).div(uint256(1000));
        uint256 blockReward = 0;
        //uint256 subTotal = block.timestamp.sub(lastGenerate).mul(oracle.nGenerate());
        uint256 subTotal = totalStakingSpeed.add(totalSwapSpeed);

        if(lpWeight == uint256(1000)) {
            blockReward = adjustedN;
        } else if ((subTotal >= adjustedN) || (subTotal >= adjustedRewardThreshold)) {
            blockReward = 0;
        } else if ((subTotal < adjustedRewardThreshold) && (subTotal >= adjustedRewardThreshold.div(uint256(2)))) {
            blockReward = adjustedRewardThreshold.div(uint256(8));   // 0.125 * adjustedRewardThreshold
        } else if ((subTotal < adjustedRewardThreshold.div(uint256(2))) && (subTotal >= adjustedRewardThreshold.div(uint256(4)))) {
            blockReward = adjustedRewardThreshold.div(uint256(4));   // 0.25 * adjustedRewardThreshold
        } else {
            blockReward = adjustedRewardThreshold.div(uint256(2));
        }

        blockReward = blockReward.div(uint256(10000)).mul(blockWeight);

        return blockReward;
    }

    function setOracle(address _oracle) external {
        require(address(factory) == msg.sender, "must be called by factory");
        oracle = IOracle(_oracle);
    }

    function setBlockWeight(uint256 _weight) external {
        require(address(factory) == msg.sender, "must be called by factory");
        blockWeight = _weight;
    }

    function fee() public view returns(uint256) {
        require(address(oracle) != address(0), "oracle can not be null");
        return oracle.fee();
    }

    function getTokens() external view returns(IERC20[] memory) {
        return tokens;
    }

    function decayPeriod() external pure returns(uint256) {
        return VirtualBalance.DECAY_PERIOD;
    }

    function getBalanceForAddition(IERC20 token) public view returns(uint256) {
        uint256 balance = token.uniBalanceOf(address(this));
        return Math.max(virtualBalancesForAddition[token].current(balance), balance);
    }

    function getBalanceForRemoval(IERC20 token) public view returns(uint256) {
        uint256 balance = token.uniBalanceOf(address(this));
        return Math.min(virtualBalancesForRemoval[token].current(balance), balance);
    }

    function getReturn(IERC20 src, IERC20 dst, uint256 amount) external view returns(uint256) {
        return _getReturn(src, dst, amount, getBalanceForAddition(src), getBalanceForRemoval(dst));
    }

    function deposit(uint256[] calldata amounts, uint256[] calldata minAmounts) external payable nonReentrant returns(uint256 fairSupply) {
        IERC20[] memory _tokens = tokens;
        require(address(oracle) != address(0), "oracle can not be null");
        require(amounts.length == _tokens.length, "Uggswap: wrong amounts length");
        require(msg.value == (_tokens[0].isETH() ? amounts[0] : (_tokens[1].isETH() ? amounts[1] : 0)), "Uggswap: wrong value usage");

        uint256[] memory realBalances = new uint256[](amounts.length);
        for (uint256 i = 0; i < realBalances.length; i++) {
            realBalances[i] = _tokens[i].uniBalanceOf(address(this)).sub(_tokens[i].isETH() ? msg.value : 0);
        }

        uint256 totalSupply = totalSupply();
        if (totalSupply == 0) {
            fairSupply = BASE_SUPPLY.mul(99);
            _mint(address(this), BASE_SUPPLY); // Donate up to 1%

            // Use the greatest token amount but not less than 99k for the initial supply
            for (uint256 i = 0; i < amounts.length; i++) {
                fairSupply = Math.max(fairSupply, amounts[i]);
            }
        }
        else {
            // Pre-compute fair supply
            fairSupply = type(uint256).max;
            for (uint256 i = 0; i < amounts.length; i++) {
                fairSupply = Math.min(fairSupply, totalSupply.mul(amounts[i]).div(realBalances[i]));
            }
        }

        uint256 fairSupplyCached = fairSupply;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] > 0, "Uggswap: amount is zero");
            uint256 amount = (totalSupply == 0) ? amounts[i] :
                realBalances[i].mul(fairSupplyCached).add(totalSupply - 1).div(totalSupply);
            require(amount >= minAmounts[i], "Uggswap: minAmount not reached");

            _tokens[i].uniTransferFromSenderToThis(amount);
            if (totalSupply > 0) {
                uint256 confirmed = _tokens[i].uniBalanceOf(address(this)).sub(realBalances[i]);
                fairSupply = Math.min(fairSupply, totalSupply.mul(confirmed).div(realBalances[i]));
            }
        }

        if (totalSupply > 0) {
            for (uint256 i = 0; i < amounts.length; i++) {
                virtualBalancesForRemoval[_tokens[i]].scale(realBalances[i], totalSupply.add(fairSupply), totalSupply);
                virtualBalancesForAddition[_tokens[i]].scale(realBalances[i], totalSupply.add(fairSupply), totalSupply);
            }
        }

        require(fairSupply > 0, "Uggswap: result is not enough");
        _mint(msg.sender, fairSupply);

        // ugg token reward
        uint256 _speedBefore = depositValues[msg.sender].getSpeed();
        uint256 _uggReward = depositValues[msg.sender].getValue();
        if(_uggReward > 0) {
            //factory.rewardDeposit(msg.sender, _uggReward);
            ugg_mint(msg.sender, _uggReward);
        }
        uint256 _newReward = fairSupply.div(uint256(100));
        _newReward = _newReward.mul(uint256(oracle.ary()));
        depositValues[msg.sender].addValue(_newReward, oracle.year()); 

        uint256 _speedAfter = depositValues[msg.sender].getSpeed();
        totalStakingSpeed = totalStakingSpeed.add(_speedAfter).sub(_speedBefore);

        //reset swap
        uint256 swapTime = 0;
        if(swapSpeedResetTime == 0) {
            swapSpeedResetTime = block.timestamp;
            totalSwapAmount = 0;
            swapTime = 20; 
        } else {
            swapTime = block.timestamp.sub(swapSpeedResetTime);
            if(swapTime > 3600) { // reset per hour
                swapSpeedResetTime = block.timestamp;
                totalSwapAmount = 0;
                swapTime = 20;
            } else {
                if(swapTime < 20) {   // swapTime can't be too small
                    swapTime = 20;
                }
            }
        }
        totalSwapSpeed = totalSwapAmount.div(swapTime);

        // block generator
        uint256 _gen = generate();
        _gen = _gen.mul(block.timestamp.sub(lastGenerate));
        if(_gen > 0) {
            //ugg_mint(msg.sender, _gen);
            blockRewardBalance = blockRewardBalance.add(_gen);
        }
        lastGenerate = block.timestamp;
        totalSupply = totalSupply.add(fairSupply);
        
        uint256 myShare = balanceOf(msg.sender);
        uint256 depositShare = blockRewardBalance.mul(1e12).div(totalSupply);
        uint256 depositReward = depositShare.mul(myShare).div(1e12);
        blockRewardBalance = blockRewardBalance.sub(depositReward);
        ugg_mint(msg.sender, depositReward);

        emit Deposited(msg.sender, fairSupply);
    }

    function withdraw(uint256 amount, uint256[] memory minReturns) external nonReentrant {
        require(address(oracle) != address(0), "oracle can not be null");

        uint256 totalSupply = totalSupply();
        _burn(msg.sender, amount);

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];

            uint256 preBalance = token.uniBalanceOf(address(this));
            uint256 value = preBalance.mul(amount).div(totalSupply);
            uint256 valueDev = value.mul(oracle.feeWithdraw()).div(uint256(1000));
            uint256 valueUser = value.sub(valueDev);
            token.uniTransfer(msg.sender, valueUser);
            token.uniTransfer(oracle.getDeveloper(), valueDev);
            require(i >= minReturns.length || value >= minReturns[i], "Uggswap: result is not enough");

            virtualBalancesForAddition[token].scale(preBalance, totalSupply.sub(amount), totalSupply);
            virtualBalancesForRemoval[token].scale(preBalance, totalSupply.sub(amount), totalSupply);
        }

        // ugg token reward
        uint256 _speedBefore = depositValues[msg.sender].getSpeed();
        uint256 _uggReward = depositValues[msg.sender].getValue();
        if(_uggReward > 0) {
            //factory.rewardDeposit(msg.sender, _uggReward);
            ugg_mint(msg.sender, _uggReward);
        }
        uint256 _newReward = amount.div(uint256(100));
        _newReward = _newReward.mul(uint256(oracle.ary()));
        depositValues[msg.sender].removeValue(_newReward, oracle.year()); 
        
        uint256 _speedAfter = depositValues[msg.sender].getSpeed();
        totalStakingSpeed = totalStakingSpeed.add(_speedAfter).sub(_speedBefore);

        emit Withdrawn(msg.sender, amount);
    }

    //function swap(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn, address referral) external payable nonReentrant returns(uint256 result) {
    function swap(IERC20 src, IERC20 dst, uint256 amount, uint256 minReturn) external payable nonReentrant returns(uint256 result) {
        require(msg.value == (src.isETH() ? amount : 0), "Uggswap: wrong value usage");
        require(address(oracle) != address(0), "oracle can not be null");
        
        Balances memory balances = Balances({
            src: src.uniBalanceOf(address(this)).sub(src.isETH() ? msg.value : 0),
            dst: dst.uniBalanceOf(address(this))
        });

        // catch possible airdrops and external balance changes for deflationary tokens
        uint256 srcAdditionBalance = Math.max(virtualBalancesForAddition[src].current(balances.src), balances.src);
        uint256 dstRemovalBalance = Math.min(virtualBalancesForRemoval[dst].current(balances.dst), balances.dst);

        src.uniTransferFromSenderToThis(amount);
        uint256 confirmed = src.uniBalanceOf(address(this)).sub(balances.src);
        result = _getReturn(src, dst, confirmed, srcAdditionBalance, dstRemovalBalance);
        require(result > 0 && result >= minReturn, "Uggswap: return is not enough");
        dst.uniTransfer(msg.sender, result);

        // Update virtual balances to the same direction only at imbalanced state
        if (srcAdditionBalance != balances.src) {
            virtualBalancesForAddition[src].set(srcAdditionBalance.add(confirmed));
        }
        if (dstRemovalBalance != balances.dst) {
            virtualBalancesForRemoval[dst].set(dstRemovalBalance.sub(result));
        }

        // Update virtual balances to the opposite direction
        virtualBalancesForRemoval[src].update(balances.src);
        virtualBalancesForAddition[dst].update(balances.dst);

        // for developer and finance
        uint256 invariantRatio = uint256(1e36);
        invariantRatio = invariantRatio.mul(balances.src.add(confirmed)).div(balances.src);
        invariantRatio = invariantRatio.mul(balances.dst.sub(result)).div(balances.dst);
        if (invariantRatio > 1e36) {
            // calculate share only if invariant increased
            uint256 devShare = invariantRatio.sqrt().sub(1e18).mul(totalSupply()).div(1e18).div(oracle.feeDev());
            if (devShare > 0) {
                _mint(oracle.getDeveloper(), devShare);
            }

            // uint256 financeShare = invariantRatio.sqrt().sub(1e18).mul(totalSupply()).div(1e18).div(oracle.feeFinance());
            // if(financeShare > 0) {
            //     _mint(oracle.getFinance(), financeShare);
            // }
        }

        // Swap Reward = AVG(daily_staking_reward/var_staking_ratio,  swap_value/var_swap_ratio)
        //uint256 swapAmount = (src == tokens[0]) ? amount : result;
        uint256 swapAmount = (amount < result) ? amount : result;
        swapAmount = swapAmount.div(oracle.varSwapRatio());
        uint256 valueStaking = oracle.dailyStakingReward().div(oracle.varStakingRatio());
        swapAmount = swapAmount.add(valueStaking).div(uint256(2));   
        //swapAmount = swapAmount.div(uint256(2));
        ugg_mint(msg.sender, swapAmount);

        totalSwapAmount = totalSwapAmount.add(swapAmount);

        emit Swapped(msg.sender, address(src), address(dst), confirmed, result, balances.src, balances.dst, totalSupply());

        // Overflow of uint128 is desired
        volumes[src].confirmed += uint128(confirmed);
        volumes[src].result += uint128(result);
    }

    function _getReturn(IERC20 src, IERC20 dst, uint256 amount, uint256 srcBalance, uint256 dstBalance) internal view returns(uint256) {
        if (isToken[src] && isToken[dst] && src != dst && amount > 0) {
            uint256 taxedAmount = amount.sub(amount.mul(fee()).div(FEE_DENOMINATOR));
            return taxedAmount.mul(dstBalance).div(srcBalance.add(taxedAmount));
        }
    }

    function ugg_mint(address addr, uint256 value) internal {
        require(addr != address(0));
        uggBalances[addr] = uggBalances[addr].add(value);
        uggTotalSupply = uggTotalSupply.add(value);
    }

    function ugg_collect(uint256 value) external {
        require(uggBalances[msg.sender] >= value);
        uggBalances[msg.sender] = uggBalances[msg.sender].sub(value);
        uggTotalSupply = uggTotalSupply.sub(value);
        factory.uggCollect(msg.sender, value);
    }
}

interface IUggSwapERC20 {
    // function swap_mint(address to, uint256 value) external;
    function collect(address to, uint256 value) external;
}

//contract UggFactory is Ownable {
contract UggFactory {
    using UniERC20 for IERC20;
    using SafeMath for uint256;

    event Deployed(
        address indexed uggswap,
        address indexed token1,
        address indexed token2
    );

    //uint256 public constant MAX_FEE = 0.003e18; // 0.3%

    UggSwap[] public allPools;
    mapping(UggSwap => bool) public isPool;
    mapping(IERC20 => mapping(IERC20 => UggSwap)) public pools;

    IUggSwapERC20 public uggToken;                    // ugg reward address
    mapping(UggSwap => uint256) public poolWeight;

    IOracle public oracle;

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "new owner must be not null");
        owner = _owner;
    }

    function getAllPools() external view returns(UggSwap[] memory) {
        return allPools;
    }

    //function setUgg(address ugg) external {
    function setUgg(address ugg) external onlyOwner {
        require(ugg != address(0), "address can not be null");
        uggToken = IUggSwapERC20(ugg);
    }

    //function setWeight(address pool, uint256 weight) external {
    function setWeight(address pool, uint256 weight) external onlyOwner {
        require(address(oracle) != address(0), "oracle can not be null");
        require(pool != address(0), "pool can not be null");
        require(weight < oracle.weightDenominator(), "weight must be smaller than denominator");
        poolWeight[UggSwap(pool)] = weight;
    }

    //function setOracle(address _oracle) external {
    function setOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "address can not be null");
        oracle = IOracle(_oracle);
    }

    //function setPoolOracle(address _pool, address _oracle) external {
    function setPoolOracle(address _pool, address _oracle) external onlyOwner {
        require(_pool != address(0), "pool can not be null");
        require(isPool[UggSwap(_pool)], "must be deployed pool");
        require(_oracle != address(0), "oracle can not be null");
        UggSwap(_pool).setOracle(_oracle);
    }

    function setPoolBlockWeight(address _pool, uint256 w) external onlyOwner {
        require(_pool != address(0), "pool can not be null");
        require(isPool[UggSwap(_pool)], "must be deployed pool");
        UggSwap(_pool).setBlockWeight(w);
    }

    //function deploy(IERC20 tokenA, IERC20 tokenB) public onlyOwner returns(UggSwap pool) {
    function deploy(IERC20 tokenA, IERC20 tokenB) public returns(UggSwap pool) {
        require(tokenA != tokenB, "Factory: not support same tokens");
        require(pools[tokenA][tokenB] == UggSwap(0), "Factory: pool already exists");
        require(address(oracle) != address(0), "oracle can not be null");

        //(IERC20 token1, IERC20 token2) = sortTokens(tokenA, tokenB);
        (IERC20 token1, IERC20 token2) = (tokenA, tokenB);
        IERC20[] memory tokens = new IERC20[](2);
        tokens[0] = token1;
        tokens[1] = token2;

        // string memory symbol1 = token1.uniSymbol();
        // string memory symbol2 = token2.uniSymbol();

        pool = new UggSwap(
            tokens,
            string(abi.encodePacked("UggSwap")),
            string(abi.encodePacked("UGG")),
            address(oracle)
        );

        pools[token1][token2] = pool;
        pools[token2][token1] = pool;
        allPools.push(pool);
        isPool[pool] = true;

        emit Deployed(
            address(pool),
            address(token1),
            address(token2)
        );
    }

    // function sortTokens(IERC20 tokenA, IERC20 tokenB) public pure returns(IERC20, IERC20) {
    //     if (tokenA < tokenB) {
    //         return (tokenA, tokenB);
    //     }
    //     return (tokenB, tokenA);
    // }

    function uggCollect(address to, uint256 value) external {
        require(to != address(0), "address can not be null");
        require(isPool[UggSwap(msg.sender)], "pool must be exists");
        require(address(uggToken) != address(0), "uggToken can not be null");
        require(address(oracle) != address(0), "oracle can not be null");
        if(poolWeight[UggSwap(msg.sender)] > 0 && value > 0) {
            uint256 valueNew = value.mul(poolWeight[UggSwap(msg.sender)]);
            valueNew = valueNew.div(oracle.weightDenominator());
            uggToken.collect(to, valueNew);
        }
    }
}