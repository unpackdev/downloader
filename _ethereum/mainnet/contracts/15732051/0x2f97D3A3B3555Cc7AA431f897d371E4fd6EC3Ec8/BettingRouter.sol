// SPDX-License-Identifier: MIT
// File: contracts/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.7;

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
}

// File: contracts/Ownable.sol


pragma solidity 0.8.7;


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

// File: @openzeppelin\contracts\math\SafeMath.sol

pragma solidity ^0.8.7;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.7;

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

pragma solidity ^0.8.7;

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

pragma solidity ^0.8.7;



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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

pragma solidity ^0.8.7;

contract TOKEN is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {}
}

pragma solidity 0.8.7;

interface IBettingPair {
    enum CHOICE { WIN, DRAW, LOSE }
    enum BETSTATUS { BETTING, REVIEWING, CLAIMING }

    function bet(address, uint256, CHOICE) external;

    function claim(address) external returns (uint256[] memory);
    function calcEarning(address) external view returns (uint256[] memory);
    function calcMultiplier() external view returns (uint256[] memory);

    function getBetProfit() external view returns (uint256);
    function setBetProfit(uint256) external;

    function getPlayerBetAmount(address) external view returns (uint256[] memory);
    function getPlayerClaimHistory(address) external view returns (uint256);

    function getBetResult() external view returns (CHOICE);
    function setBetResult(CHOICE _result) external;

    function getBetStatus() external view returns (BETSTATUS);
    function setBetStatus(BETSTATUS _status) external;

    function getTotalBet() external view returns (uint256);
    function getTotalBetPerChoice() external view returns (uint256[] memory);

    function getWciTokenThreshold() external view returns (uint256);
    function setWciTokenThreshold(uint256) external;
}


contract BettingPair is Ownable, IBettingPair {
    using SafeMath for uint256;

    mapping (address => mapping(CHOICE => uint256)) players;
    mapping (address => mapping(CHOICE => uint256)) betHistory;
    mapping (address => uint256) claimHistory;
    CHOICE betResult;
    BETSTATUS betStatus;
    uint256 betProfit;

    uint256 totalBet;
    mapping(CHOICE => uint256) totalBetPerChoice;

    TOKEN public wciToken;
    uint256 wciTokenThreshold;

    constructor() {
        betStatus = BETSTATUS.BETTING;
        totalBet = 0;
        betProfit = 0;
        totalBetPerChoice[CHOICE.WIN] = 0;
        totalBetPerChoice[CHOICE.DRAW] = 0;
        totalBetPerChoice[CHOICE.LOSE] = 0;
        wciToken = TOKEN(0xC5a9BC46A7dbe1c6dE493E84A18f02E70E2c5A32);
        wciTokenThreshold = 50000000000000; // 50,000 WCI as a threshold.
    }

    modifier betConditions(uint _amount) {
        require(_amount >= 0.01 ether, "Insuffisant amount, please increase your bet!");
        _;
    }

    function bet(address _player, uint256 _amount, CHOICE _choice) external override betConditions(_amount) {
        require(betStatus == BETSTATUS.BETTING, "You can not bet at this time.");
        totalBet += _amount;
        totalBetPerChoice[_choice] += _amount;
        players[_player][_choice] += _amount;
        betHistory[_player][_choice] += _amount;
    }

    function calculateEarning(address _player, CHOICE _choice) internal view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](2);

        uint256 userBal = players[_player][_choice];
        if (totalBetPerChoice[_choice] == 0) {
            res[0] = 0;
            res[1] = 0;
            return res;
        }

        uint256 _wciTokenBal = wciToken.balanceOf(_player);

        // The player will take 5% tax if he holds enough WCI token. Otherwise he will take 10% tax.
        if (_wciTokenBal > wciTokenThreshold) {
            res[0] = totalBet.mul(19).mul(userBal).div(20).div(totalBetPerChoice[_choice]) + userBal.div(20);
            res[1] = totalBet.mul(userBal).div(20).div(totalBetPerChoice[_choice]) - userBal.div(20);
            return res;
        } else {
            res[0] = totalBet.mul(9).mul(userBal).div(10).div(totalBetPerChoice[_choice]) + userBal.div(10);
            res[1] = totalBet.mul(userBal).div(10).div(totalBetPerChoice[_choice]) - userBal.div(10);
            return res;
        }
    }

    function calcEarning(address _player) external override view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](3);
        res[0] = calculateEarning(_player, CHOICE.WIN)[0];
        res[1] = calculateEarning(_player, CHOICE.DRAW)[0];
        res[2] = calculateEarning(_player, CHOICE.LOSE)[0];
        return res;
    }

    // Calculate how much times reward will player take. It uses 10% tax formula to give users the approximate multiplier before bet.
    function calculateMultiplier(CHOICE _choice) internal view returns (uint256) {
        if (totalBetPerChoice[_choice] == 0) return 1000;
        return totalBet.mul(900).div(totalBetPerChoice[_choice]) + 100;
    }

    function calcMultiplier() external override view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](3);
        res[0] = calculateMultiplier(CHOICE.WIN);
        res[1] = calculateMultiplier(CHOICE.DRAW);
        res[2] = calculateMultiplier(CHOICE.LOSE);
        return res;
    }

    function claim(address _player) external override returns (uint256[] memory) {
        require(betStatus == BETSTATUS.CLAIMING, "You can not claim at this time.");
        require(_player != address(0), "This address doesn't exist.");
        require(players[_player][betResult] > 0, "You don't have any earnings to withdraw.");

        uint256[] memory res = new uint256[](2);
        res[0] = calculateEarning(_player, betResult)[0];
        res[1] = calculateEarning(_player, betResult)[1];
        claimHistory[_player] = res[0];
        players[_player][CHOICE.WIN] = 0;
        players[_player][CHOICE.DRAW] = 0;
        players[_player][CHOICE.LOSE] = 0;

        return res;
    }

    function getBetProfit() external override view onlyOwner returns (uint256) {
        return betProfit;
    }
    function setBetProfit(uint256 _profit) external override onlyOwner {
        betProfit = _profit;
    }

    function getPlayerBetAmount(address _player) external override view returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](3);
        arr[0] = betHistory[_player][CHOICE.WIN];
        arr[1] = betHistory[_player][CHOICE.DRAW];
        arr[2] = betHistory[_player][CHOICE.LOSE];

        return arr;
    }

    function getPlayerClaimHistory(address _player) external override view returns (uint256) {
        return claimHistory[_player];
    }

    function getBetResult() external view override returns (CHOICE) {
        return betResult;
    }
    function setBetResult(CHOICE _result) external override onlyOwner {
        betResult = _result;
        betStatus = BETSTATUS.REVIEWING;
    }

    function getBetStatus() external view override returns (BETSTATUS) {
        return betStatus;
    }
    function setBetStatus(BETSTATUS _status) external override onlyOwner {
        if (_status == IBettingPair.BETSTATUS.CLAIMING) {
            betProfit = (totalBet - totalBetPerChoice[betResult]).div(10);
        }
        betStatus = _status;
    }

    function getTotalBet() external view override returns (uint256) {
        return totalBet;
    }
    function getTotalBetPerChoice() external view override returns (uint256[] memory) {
        uint256[] memory arr = new uint256[](3);
        arr[0] = totalBetPerChoice[CHOICE.WIN];
        arr[1] = totalBetPerChoice[CHOICE.DRAW];
        arr[2] = totalBetPerChoice[CHOICE.LOSE];

        return arr;
    }
    function getWciTokenThreshold() external view override returns (uint256) {
        return wciTokenThreshold;
    }
    function setWciTokenThreshold(uint256 _threshold) external override onlyOwner {
        wciTokenThreshold = _threshold;
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.7;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract BettingRouter is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    mapping (uint256 => address) pairs;
    Counters.Counter matchId;
    address taxCollectorAddress;
    uint256 totalClaim;
    uint256 totalWinnerCount;

    event Bet(uint256 pairId, address player, uint256 amount, IBettingPair.CHOICE choice);
    event Claim(uint256 pairId, address player, uint256 amount, IBettingPair.CHOICE choice);
    event CreatePair(uint256 pairId, address pairAddress);
    event SetBetResult(uint256 pairId, IBettingPair.CHOICE result);
    event SetBetStatus(uint256 pairId, IBettingPair.BETSTATUS status);
    event WithdrawFromPair(uint256 pairId, uint256 amount);
    event WithdrawFromRouter(uint256 amount);

    constructor() {
        taxCollectorAddress = 0x37FC70ca2Db17E13767aE7161EA3275585BE9837;
    }

    modifier onlyValidPair(uint256 _id) {
        require(_id >= 0, "Pair id should not be negative.");
        require(_id < matchId.current(), "Invalid pair id.");
        _;
    }

    function createOne() public onlyOwner {
        BettingPair _pair = new BettingPair();
        pairs[matchId.current()] = address(_pair);
        matchId.increment();
    }

    function createMany(uint256 _count) external onlyOwner {
        for (uint256 i=0; i<_count; i++) {
            createOne();
        }
    }

    function bet(uint256 _pairId, IBettingPair.CHOICE _choice) external payable onlyValidPair(_pairId) {
        require(msg.value > 0.011 ether, "Minimum bet amount is 0.011 ether.");
        IBettingPair(pairs[_pairId]).bet(msg.sender, msg.value, _choice);
        emit Bet(_pairId, msg.sender, msg.value, _choice);
    }

    function claim(uint256 _pairId) external onlyValidPair(_pairId) {
        uint256[] memory claimInfo = IBettingPair(pairs[_pairId]).claim(msg.sender);
        uint256 _amountClaim = claimInfo[0];
        uint256 _amountTax = claimInfo[1];
        require(_amountClaim > 0, "You do not have any profit in this betting.");

        payable(msg.sender).transfer(_amountClaim);
        payable(taxCollectorAddress).transfer(_amountTax);
        
        totalWinnerCount ++;
        totalClaim += _amountClaim;
        emit Claim(_pairId, msg.sender, _amountClaim, IBettingPair(pairs[_pairId]).getBetResult());
    }

    function getPlayerBetAmount(address _player) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId.current() * 3);

        for (uint256 i=0; i<matchId.current(); i++) {
            uint256[] memory temp = IBettingPair(pairs[i]).getPlayerBetAmount(_player);
            res[i*3] = temp[0];
            res[i*3 + 1] = temp[1];
            res[i*3 + 2] = temp[2];
        }
        
        return res;
    }

    function getPlayerClaimHistory(address _player) external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId.current());

        for (uint256 i=0; i<matchId.current(); i++) {
            res[i] = IBettingPair(pairs[i]).getPlayerClaimHistory(_player);
        }

        return res;
    }

    function getContractAddresses() external view returns (address[] memory) {
        address[] memory arr = new address[](matchId.current());
        for (uint256 i=0; i<matchId.current(); i++) {
            arr[i] = pairs[i];
        }

        return arr;
    }

    function getPairInformation(uint256 _pairId) external view onlyValidPair(_pairId) returns (uint256[] memory) {
        uint256[] memory res = new uint256[](6);
        res[0] = uint256(IBettingPair(pairs[_pairId]).getBetResult());
        res[1] = uint256(IBettingPair(pairs[_pairId]).getBetStatus());
        res[2] = IBettingPair(pairs[_pairId]).getTotalBet();

        uint256[] memory _choiceBetAmount = IBettingPair(pairs[_pairId]).getTotalBetPerChoice();
        res[3] = _choiceBetAmount[0];
        res[4] = _choiceBetAmount[1];
        res[5] = _choiceBetAmount[2];

        return res;
    }

    function getMatchId() external view returns (uint256) {
        return matchId.current();
    }

    function getClaimAmount() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId.current() * 3);
        
        for (uint256 i=0; i<matchId.current(); i++) {
            uint256[] memory pairRes = IBettingPair(pairs[i]).calcEarning(msg.sender);
            res[i*3] = pairRes[0];
            res[i*3+1] = pairRes[1];
            res[i*3+2] = pairRes[2];
        }

        return res;
    }

    function getMultiplier() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId.current() * 3);
        
        for (uint256 i=0; i<matchId.current(); i++) {
            uint256[] memory pairRes = IBettingPair(pairs[i]).calcMultiplier();
            res[i*3] = pairRes[0];
            res[i*3+1] = pairRes[1];
            res[i*3+2] = pairRes[2];
        }

        return res;
    }

    function getBetStatus() external view returns (IBettingPair.BETSTATUS[] memory) {
        IBettingPair.BETSTATUS[] memory res = new IBettingPair.BETSTATUS[](matchId.current());

        for (uint256 i=0; i<matchId.current(); i++) {
            res[i] = IBettingPair(pairs[i]).getBetStatus();
        }

        return res;
    }

    function getBetResult() external view returns (IBettingPair.CHOICE[] memory) {
        IBettingPair.CHOICE[] memory res = new IBettingPair.CHOICE[](matchId.current());

        for (uint256 i=0; i<matchId.current(); i++) {
            res[i] = IBettingPair(pairs[i]).getBetResult();
        }

        return res;
    }

    function getBetProfit() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId.current());

        for (uint256 i=0; i<matchId.current(); i++) {
            res[i] = IBettingPair(pairs[i]).getBetProfit();
        }

        return res;
    }

    function getTotalBet() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId.current());

        for (uint256 i=0; i<matchId.current(); i++) {
            res[i] = IBettingPair(pairs[i]).getTotalBet();
        }

        return res;
    }

    function getTotalBetPerChoice() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](matchId.current() * 3);

        for (uint256 i=0; i<matchId.current(); i++) {
            uint256[] memory pairAmount = IBettingPair(pairs[i]).getTotalBetPerChoice();
            res[3*i] = pairAmount[0];
            res[3*i + 1] = pairAmount[1];
            res[3*i + 2] = pairAmount[2];
        }

        return res;
    }

    function getTaxCollectorAddress() external view returns (address) {
        return taxCollectorAddress;
    }

    function getBetStatsData() external view returns (uint256[] memory) {
        uint256[] memory res = new uint256[](2);
        res[0] = totalClaim;
        res[1] = totalWinnerCount;
        return res;
    }

    function getWciTokenThreshold() external view returns (uint256) {
        if (matchId.current() == 0) return 50000000000000;
        else return IBettingPair(pairs[0]).getWciTokenThreshold();
    }

    function setBetResult(uint256 _pairId, IBettingPair.CHOICE _result) external onlyOwner onlyValidPair(_pairId) {
        IBettingPair(pairs[_pairId]).setBetResult(_result);
        emit SetBetResult(_pairId, _result);
    }

    function setBetStatus(uint256 _pairId, IBettingPair.BETSTATUS _status) external onlyValidPair(_pairId) {
        IBettingPair(pairs[_pairId]).setBetStatus(_status);
        emit SetBetStatus(_pairId, _status);
    }

    function setTaxCollectorAddress(address _address) external onlyOwner {
        taxCollectorAddress = _address;
    }

    function setWciTokenThreshold(uint256 _threshold) external onlyOwner {
        for (uint256 i=0; i<matchId.current(); i++) {
            IBettingPair(pairs[i]).setWciTokenThreshold(_threshold);
        }
    }

    function withdrawProfitFromPair(uint256 _pairId) external onlyOwner onlyValidPair(_pairId) {
        require(IBettingPair(pairs[_pairId]).getBetStatus() == IBettingPair.BETSTATUS.CLAIMING, "Bet is not completed.");
        uint256 _amount = IBettingPair(pairs[_pairId]).getBetProfit();
        require(_amount > 0, "No profit to withdraw.");
        payable(msg.sender).transfer(_amount);
        IBettingPair(pairs[_pairId]).setBetProfit(0);
        emit WithdrawFromPair(_pairId, _amount);
    }

    function withdrawFromRouter(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount should be bigger than 0.");
        require(_amount <= address(this).balance, "Exceed the contract balance.");
        payable(msg.sender).transfer(_amount);
        emit WithdrawFromRouter(_amount);
    }
}