/**

   _____  .__  .__                 ____  __.________          .___ 
  /  _  \ |  | |__| ____   ____   |    |/ _|\_____  \    ____ |   |
 /  /_\  \|  | |  |/ __ \ /    \  |      <   /   |   \  / ___\|   |
/    |    \  |_|  \  ___/|   |  \ |    |  \ /    |    \/ /_/  >   |
\____|__  /____/__|\___  >___|  / |____|__ \\_______  /\___  /|___|
        \/             \/     \/          \/        \//_____/      
 


                        $KOGI Launch: 
                        https://alienkogi.com

*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.21;

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ALIENKOGI is Context, ERC20, Ownable {
    using SafeMath for uint256;

    IDEXRouter private _dexRouter;

    mapping (address => uint) private _cooldown;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedMaxTransactionAmount;
    

    bool public tradingOpen;
    bool private _swapping;
    bool public swapEnabled = false;
    bool public cooldownEnabled = false;
    bool public feesEnabled = true;
    bool public transferFeesEnabled = true;

    uint256 private constant _tSupply = 7_100_000_000 ether;

    uint256 public maxBuyAmount = _tSupply;
    uint256 public maxSellAmount = _tSupply;
    uint256 public maxWalletAmount = _tSupply;

    uint256 public tradingOpenBlock = 0;
    uint256 private _cooldownBlocks = 1;

    uint256 public constant FEE_DIVISOR = 1000;

    uint256 private _totalFees;
    uint256 private _marketingFee;
    uint256 private _CEXFee;
    uint256 private _liquidityFee;

    uint256 public buyMarketingFee = 100;
    uint256 private _previousBuyMarketingFee = buyMarketingFee;
    uint256 public buyCEXFee = 20;
    uint256 private _previousBuyCEXFee = buyCEXFee;
    uint256 public buyLiquidityFee = 30;
    uint256 private _previousBuyLiquidityFee = buyLiquidityFee;

    uint256 public sellMarketingFee = 800;
    uint256 private _previousSellMktgFee = sellMarketingFee;
    uint256 public sellCEXFee = 100;
    uint256 private _previousSellDevFee = sellCEXFee;
    uint256 public sellLiquidityFee = 50;
    uint256 private _previousSellLiqFee = sellLiquidityFee;

    uint256 public transferMarketingFee = 800;
    uint256 private _previousTransferMarketingFee = transferMarketingFee;
    uint256 public transferCEXFee = 100;
    uint256 private _previousTransferCEXFee = transferCEXFee;
    uint256 public transferLiquidityFee = 50;
    uint256 private _previousTransferLiquidityFee = transferLiquidityFee;

    uint256 private _tokensForMarketing;
    uint256 private _tokensForCEX;
    uint256 private _tokensForLiquidity;
    uint256 private _swapTokensAtAmount = 0;

    address payable public marketingWalletAddress;
    address payable public CEXWalletAddress;
    address payable public liquidityWalletAddress;

    address private _dexPair;
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant private ZERO = 0x0000000000000000000000000000000000000000;

    enum TransactionType {
        BUY,
        SELL,
        TRANSFER
    }

    event OpenTrading(uint256 tradingOpenBlock);
    event SetMaxBuyAmount(uint256 newMaxBuyAmount);
    event SetMaxSellAmount(uint256 newMaxSellAmount);
    event SetMaxWalletAmount(uint256 newMaxWalletAmount);
    event SetSwapTokensAtAmount(uint256 newSwapTokensAtAmount);
    event SetBuyFee(uint256 buyMarketingFee, uint256 buyCEXFee, uint256 buyLiquidityFee);
	event SetSellFee(uint256 sellMarketingFee, uint256 sellCEXFee, uint256 sellLiquidityFee);
    event SetTransferFee(uint256 transferMarketingFee, uint256 transferCEXFee, uint256 transferLiquidityFee);
    
    constructor () ERC20(unicode"Alien KōGī", unicode"KōGī") {

        marketingWalletAddress = payable(0x80405975FB9fdAD0efc7759c95f9BEA1df37514b);
        CEXWalletAddress = payable(0x5d07F304B8430f34ab6bBd9cdDc64Ce08b909Faa);
        liquidityWalletAddress = payable(0x0AA96931E517a4E9309C06E155bd4417c40eE3fE);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromFees[marketingWalletAddress] = true;
        _isExcludedFromFees[CEXWalletAddress] = true;

        _isExcludedMaxTransactionAmount[owner()] = true;
        _isExcludedMaxTransactionAmount[address(this)] = true;
        _isExcludedMaxTransactionAmount[DEAD] = true;
        _isExcludedMaxTransactionAmount[marketingWalletAddress] = true;
        _isExcludedMaxTransactionAmount[CEXWalletAddress] = true;
        _dexRouter = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_dexRouter), totalSupply());
        _dexPair = IDEXFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());

        _mint(address(owner()), _tSupply);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != ZERO, "ERC20: transfer from the zero address");
        require(to != ZERO, "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        TransactionType txType = (from == _dexPair) ? TransactionType.BUY : (to == _dexPair) ? TransactionType.SELL : TransactionType.TRANSFER;
        if (from != owner() && to != owner() && to != ZERO && to != DEAD && !_swapping) {

            if(!tradingOpen) require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not allowed yet.");

            if (cooldownEnabled) {
                if (to != address(_dexRouter) && to != address(_dexPair)) {
                    require(_cooldown[tx.origin] < block.number - _cooldownBlocks && _cooldown[to] < block.number - _cooldownBlocks, "Transfer delay enabled. Try again later.");
                    _cooldown[tx.origin] = block.number;
                    _cooldown[to] = block.number;
                }
            }

            if (txType == TransactionType.BUY && to != address(_dexRouter) && !_isExcludedMaxTransactionAmount[to]) {
                
                require(amount <= maxBuyAmount, "Transfer amount exceeds the maxBuyAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds maximum wallet token amount.");
            }
            
            if (txType == TransactionType.SELL && from != address(_dexRouter) && !_isExcludedMaxTransactionAmount[from]) require(amount <= maxSellAmount, "Transfer amount exceeds the maxSellAmount.");
        }

        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || !feesEnabled || (!transferFeesEnabled && txType == TransactionType.TRANSFER)) takeFee = false;

        uint256 contractBalance = balanceOf(address(this));
        bool canSwap = (contractBalance > _swapTokensAtAmount) && (txType == TransactionType.SELL);

        if (canSwap && swapEnabled && !_swapping && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            _swapping = true;
            _swapBack(contractBalance);
            _swapping = false;
        }

        _tokenTransfer(from, to, amount, takeFee, txType);
    }

    function _swapBack(uint256 contractBalance) internal {
        uint256 totalTokensToSwap =  _tokensForMarketing.add(_tokensForCEX).add(_tokensForLiquidity);
        bool success;
        
        if (contractBalance == 0 || totalTokensToSwap == 0) return;

        if (contractBalance > _swapTokensAtAmount.mul(5)) contractBalance = _swapTokensAtAmount.mul(5);

        uint256 liquidityTokens = contractBalance.mul(_tokensForLiquidity).div(totalTokensToSwap).div(2);
        uint256 amountToSwapForETH = contractBalance.sub(liquidityTokens);

        uint256 initialETHBalance = address(this).balance;

        _swapTokensForETH(amountToSwapForETH);
        
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMktg = ethBalance.mul(_tokensForMarketing).div(totalTokensToSwap);
        uint256 ethForDev = ethBalance.mul(_tokensForCEX).div(totalTokensToSwap);
        uint256 ethForLiq = ethBalance.sub(ethForMktg).sub(ethForDev);
        
        _tokensForMarketing = 0;
        _tokensForCEX = 0;
        _tokensForLiquidity = 0;

        if(liquidityTokens > 0 && ethForLiq > 0) _addLiquidity(liquidityTokens, ethForLiq);

        (success,) = address(CEXWalletAddress).call{value: ethForDev}("");
        (success,) = address(marketingWalletAddress).call{value: address(this).balance}("");
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _dexRouter.WETH();
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        _approve(address(this), address(_dexRouter), tokenAmount);
        _dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWalletAddress,
            block.timestamp
        );
    }
        
    function _sendETHToFee(uint256 amount) internal {
        marketingWalletAddress.transfer(amount.div(2));
        CEXWalletAddress.transfer(amount.div(2));
    }

    function openTrading() public onlyOwner {
        require(!tradingOpen, "Trading is already open");
        maxBuyAmount = totalSupply().mul(2).div(1000);
        maxSellAmount = totalSupply().mul(2).div(1000);
        maxWalletAmount = totalSupply().mul(2).div(100);
        _swapTokensAtAmount = totalSupply().mul(2).div(10000);
        swapEnabled = true;
        cooldownEnabled = true;
        tradingOpen = true;
        tradingOpenBlock = block.number;
        emit OpenTrading(tradingOpenBlock);
    }
   

    function changeSwapEnabled(bool onoff) public onlyOwner {
        swapEnabled = onoff;
    }


 function changeFeesEnabled(bool onoff) public onlyOwner {
        feesEnabled = onoff;
    }

     function changeTransferFeesEnabled(bool onoff) public onlyOwner {
        transferFeesEnabled = onoff;
    }
    function changeCooldownEnabled(bool onoff) public onlyOwner {
        cooldownEnabled = onoff;
    }
   
    function setMaxBuyAmount(uint256 _maxBuyAmount) public onlyOwner {
        require(_maxBuyAmount >= (totalSupply().mul(1).div(1000)), "Max buy amount cannot be lower than 0.1% total supply.");
        maxBuyAmount = _maxBuyAmount;
        emit SetMaxBuyAmount(maxBuyAmount);
    }
    function setMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        require(_maxSellAmount >= (totalSupply().mul(1).div(1000)), "Max sell amount cannot be lower than 0.1% total supply.");
        maxSellAmount = _maxSellAmount;
        emit SetMaxSellAmount(maxSellAmount);
    }
    
    function setMaxWalletAmount(uint256 _maxWalletAmount) public onlyOwner {
        require(_maxWalletAmount >= (totalSupply().mul(1).div(1000)), "Max wallet amount cannot be lower than 0.1% total supply.");
        maxWalletAmount = _maxWalletAmount;
        emit SetMaxWalletAmount(maxWalletAmount);
    }
    
    function setSwapTokensAtAmount(uint256 swapTokensAtAmount) public onlyOwner {
        require(swapTokensAtAmount >= (totalSupply().mul(1).div(1000000)), "Swap amount cannot be lower than 0.0001% total supply.");
        require(swapTokensAtAmount <= (totalSupply().mul(5).div(1000)), "Swap amount cannot be higher than 0.5% total supply.");
        _swapTokensAtAmount = swapTokensAtAmount;
        emit SetSwapTokensAtAmount(_swapTokensAtAmount);
    }

    function setMarketingWallet(address _marketingWalletAddress) public onlyOwner {
        require(_marketingWalletAddress != ZERO, "marketingWalletAddress cannot be 0");
        _isExcludedFromFees[marketingWalletAddress] = false;
        _isExcludedMaxTransactionAmount[marketingWalletAddress] = false;
        marketingWalletAddress = payable(_marketingWalletAddress);
        _isExcludedFromFees[marketingWalletAddress] = true;
        _isExcludedMaxTransactionAmount[marketingWalletAddress] = true;
    }

    function setCEXWallet(address _CEXWalletAddress) public onlyOwner {
        require(_CEXWalletAddress != ZERO, "CEXWalletAddress cannot be 0");
        _isExcludedFromFees[CEXWalletAddress] = false;
        _isExcludedMaxTransactionAmount[CEXWalletAddress] = false;
        CEXWalletAddress = payable(_CEXWalletAddress);
        _isExcludedFromFees[CEXWalletAddress] = true;
        _isExcludedMaxTransactionAmount[CEXWalletAddress] = true;
    }

    function setLiquidityWallet(address _liquidityWalletAddress) public onlyOwner {
        require(_liquidityWalletAddress != ZERO, "liquidityWalletAddress cannot be 0");
        _isExcludedFromFees[liquidityWalletAddress] = false;
        _isExcludedMaxTransactionAmount[liquidityWalletAddress] = false;
        liquidityWalletAddress = payable(_liquidityWalletAddress);
        _isExcludedFromFees[liquidityWalletAddress] = true;
        _isExcludedMaxTransactionAmount[liquidityWalletAddress] = true;
    }

    function setExcludedFromFees(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedFromFees[accounts[i]] = isEx;
    }
    
    function setExcludeFromMaxTransaction(address[] memory accounts, bool isEx) public onlyOwner {
        for (uint i = 0; i < accounts.length; i++) _isExcludedMaxTransactionAmount[accounts[i]] = isEx;
    }

    function setBuyFee(uint256 _buyMarketingFee, uint256 _buyCEXFee, uint256 _buyLiquidityFee) public onlyOwner {
        buyMarketingFee = _buyMarketingFee;
        buyCEXFee = _buyCEXFee;
        buyLiquidityFee = _buyLiquidityFee;
        emit SetBuyFee(buyMarketingFee, buyCEXFee, buyLiquidityFee);
    }

    function setSellFee(uint256 _sellMarketingFee, uint256 _sellCEXFee, uint256 _sellLiquidityFee) public onlyOwner {
        sellMarketingFee = _sellMarketingFee;
        sellCEXFee = _sellCEXFee;
        sellLiquidityFee = _sellLiquidityFee;
        emit SetSellFee(sellMarketingFee, sellCEXFee, sellLiquidityFee);
    }

    function setTransferFee(uint256 _transferMarketingFee, uint256 _transferCEXFee, uint256 _transferLiquidityFee) public onlyOwner {
        transferMarketingFee = _transferMarketingFee;
        transferCEXFee = _transferCEXFee;
        transferLiquidityFee = _transferLiquidityFee;
        emit SetTransferFee(transferMarketingFee, transferCEXFee, transferLiquidityFee);
    }

    function setCooldownBlocks(uint256 blocks) public onlyOwner {
        require(blocks <= 10, "Invalid blocks count.");
        _cooldownBlocks = blocks;
    }

    function _removeAllFee() internal {
        if (buyMarketingFee == 0 && buyCEXFee == 0 && buyLiquidityFee == 0 && 
        sellMarketingFee == 0 && sellCEXFee == 0 && sellLiquidityFee == 0 &&
        transferMarketingFee == 0 && transferCEXFee == 0 && transferLiquidityFee == 0) return;

        _previousBuyMarketingFee = buyMarketingFee;
        _previousBuyCEXFee = buyCEXFee;
        _previousBuyLiquidityFee = buyLiquidityFee;
        _previousSellMktgFee = sellMarketingFee;
        _previousSellDevFee = sellCEXFee;
        _previousSellLiqFee = sellLiquidityFee;
        _previousTransferMarketingFee = transferMarketingFee;
        _previousTransferCEXFee = transferCEXFee;
        _previousTransferLiquidityFee = transferLiquidityFee;
        
        buyMarketingFee = 0;
        buyCEXFee = 0;
        buyLiquidityFee = 0;
        sellMarketingFee = 0;
        sellCEXFee = 0;
        sellLiquidityFee = 0;
        transferMarketingFee = 0;
        transferCEXFee = 0;
        transferLiquidityFee = 0;
    }
    
    function _restoreAllFee() internal {
        buyMarketingFee = _previousBuyMarketingFee;
        buyCEXFee = _previousBuyCEXFee;
        buyLiquidityFee = _previousBuyLiquidityFee;
        sellMarketingFee = _previousSellMktgFee;
        sellCEXFee = _previousSellDevFee;
        sellLiquidityFee = _previousSellLiqFee;
        transferMarketingFee = _previousTransferMarketingFee;
        transferCEXFee = _previousTransferCEXFee;
        transferLiquidityFee = _previousTransferLiquidityFee;
    }
        
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee, TransactionType txType) internal {
        if (!takeFee) _removeAllFee();
        else amount = _takeFees(sender, amount, txType);

        super._transfer(sender, recipient, amount);
        
        if (!takeFee) _restoreAllFee();
    }

    function _takeFees(address sender, uint256 amount, TransactionType txType) internal returns (uint256) {
        if (txType == TransactionType.SELL) _setSellFees();
        else if (txType == TransactionType.BUY) _setBuyFees();
        else if (txType == TransactionType.TRANSFER) _setTransferFees();
        else revert("Invalid transaction type.");
        
        uint256 fees;
        if (_totalFees > 0) {
            fees = amount.mul(_totalFees).div(FEE_DIVISOR);
            _tokensForMarketing += fees * _marketingFee / _totalFees;
            _tokensForCEX += fees * _CEXFee / _totalFees;
            _tokensForLiquidity += fees * _liquidityFee / _totalFees;
        }

        if (fees > 0) super._transfer(sender, address(this), fees);

        return amount -= fees;
    }

    function _setSellFees() internal {
        _marketingFee = sellMarketingFee;
        _CEXFee = sellCEXFee;
        _liquidityFee = sellLiquidityFee;
        _totalFees = _marketingFee.add(_CEXFee).add(_liquidityFee);
    }

    function _setBuyFees() internal {
        _marketingFee = buyMarketingFee;
        _CEXFee = buyCEXFee;
        _liquidityFee = buyLiquidityFee;
        _totalFees = _marketingFee.add(_CEXFee).add(_liquidityFee);
    }

    function _setTransferFees() internal {
        _marketingFee = transferMarketingFee;
        _CEXFee = transferCEXFee;
        _liquidityFee = transferLiquidityFee;
        _totalFees = _marketingFee.add(_CEXFee).add(_liquidityFee);
    }

    function distributeFees() public onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        _sendETHToFee(contractETHBalance);
    }

    function withdrawStuckETH() public onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function withdrawStuckERCTokens(address token) public onlyOwner {
        require(token != address(this), "Cannot withdraw own token");
        require(IERC20(token).balanceOf(address(this)) > 0, "No tokens");
        uint amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, amount);
    }

    function removeAllLimits() public onlyOwner {
        maxBuyAmount = totalSupply() * 1;
        maxSellAmount = totalSupply() * 1;
        maxWalletAmount = totalSupply() * 1;
        cooldownEnabled = false;
    }

    receive() external payable {}
    fallback() external payable {}

}