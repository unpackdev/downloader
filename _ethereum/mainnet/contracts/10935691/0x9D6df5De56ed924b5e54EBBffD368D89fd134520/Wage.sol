// SPDX-License-Identifier: none

pragma solidity ^0.6.0;


// 
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

// 
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/// @dev AuthorizedAccess allows to define simple access control for multiple authorized
/// Think of it as a simple two tiered access control contract. It has an owner which can
/// execute functions with the `onlyOwner` modifier, and the owner can give access to other
/// addresses which then can execute functions with the `onlyAuthorized` modifier.
contract AuthorizedAccess is Ownable {
    event GrantedAccess(address user);
    event RevokedAccess(address user);

    mapping(address => bool) private authorized;

    constructor () public Ownable() {}

    /// @dev Restrict usage to authorized users
    modifier onlyAuthorized(string memory err) {
        require(authorized[msg.sender], err);
        _;
    }

    /// @dev Add user to the authorized users list
    function grantAccess(address user) public onlyOwner {
        authorized[user] = true;
        emit GrantedAccess(user);
    }

    /// @dev Remove user to the authorized users list
    function revokeAccess(address user) public onlyOwner {
        authorized[user] = false;
        emit RevokedAccess(user);
    }
}

// 
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

// 
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// 
//Had to copy-paste this contract to make the balanceOf function virtual
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

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 internal _totalSupply;

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
    function balanceOf(address account) public view virtual override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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
     * Requirements:
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
     * Requirements:
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

interface IWage is IERC20 {
    
    /**
    * @dev Event emitted when enabling transfers
    */
    event TransfersEnabled();
    
    /**
    * @dev Event emitted on each rebase
    * @param epoch The rebase timestamp
    * @param totalSupply the new totalSupply after the rebase
    */
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    /**
    * @dev Event emitted when enabling transfers
    * @param enabled Whether rebases have been enabled or disabled
    */
    event RebaseToggled(bool enabled);
    /**
     * @dev Event emitted when the rebase rate changes 
     * @param newRate the new rabase rate
     * @param oldRate the old rebase rate
     */
    event RebaseRateChanged(uint256 newRate, uint256 oldRate);
    /**
     * @dev Event emitted when the rebase amount changes
     * @param newAmount the new supply increase applied for each rebase
     * @param oldAmount the old supply increase
     */
    event RebaseAmountChanged(uint256 newAmount, uint256 oldAmount);
    
    /**
     * @dev Event emitted when changing syncer
     * @param newSyncer the new syncer's address
     * @param oldSyncer the old syncer's address
     */
    event WageSyncerChanged(address newSyncer, address oldSyncer);
    
    /**
     * @dev Event emitted when locking tokens.
     * @dev We are locking gons, not fragments - this causes the locked amount to change after each rebase.
     * @param target the address whose tokens have been locked
     * @param initialAmount the initial amount of tokens locked
     */
    event TokensLocked(address target, uint256 initialAmount);
    /**
     * @dev Event emitted when unlocking tokens.
     * @param target the address whose tokens have been unlocked
     * @param initialAmount the initial amount of tokens unlocked
     */
    event TokensUnlocked(address target, uint256 initialAmount);
    
    /**
     * @dev Enables transfers when called. Once enabled, transfers cannot be disabled.
     */ 
    function enableTransfers() external;

    /**
     * @dev Notifies Fragments contract about a new rebase cycle. Can only be called by the contract owner
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 supplyDelta) external returns (uint256);
    /**
     * @dev Toggles rebases. Can only be called by the owner
     * @param enabled Whether to enable or disable rebases
     */ 
    function toggleRebase(bool enabled) external;
    /**
     * @dev Changes the amount of time between each rebase. Can only be called by the owner
     * @param newRate the new rebase rate (seconds)
     */ 
    function changeRebaseRate(uint256 newRate) external;
    /**
     * @dev Changes the inflation amount after each rebase. Can only be called by the owner
     * @param newAmount the new inflation amount
     */ 
    function changeRebaseAmount(uint256 newAmount) external;

    /**
     * @dev Sets a new syncer smart contract. Can only be called by the owner.
     * Syncers are used to sync trading pairs across dexes.
     * @param newSyncer the address of the new syncer smart contract
     */ 
    function changeWageSyncer(address newSyncer) external;
    
    /**
     * @dev Returns the gons per fragment rate. Can only be called by the owner.
     * @return the gons per fragment rate
     */
    function gonsPerFragment() external view returns (uint256);
    
    /**
     * @dev Locks part of an address' gon balance. Needed for governance.
     * The amount of locked fragments inflates after each rebase.
     * @param target The target address
     * @param gonAmount the amount of gons to lock
     */
    function lock(address target, uint256 gonAmount) external;
    /**
     * @dev Unlocks part of an adress' locked gon balane. Needed for governance.
     * @param target The target address
     * @param gonAmount the amount of gons to unlock
     */
    function unlock(address target, uint256 gonAmount) external;
    
    /**
     * @dev Returns the current locked fragments for an address
     * @param target the address
     */ 
    function getLockedFragments(address target) external view returns (uint256);
    
    
    
}

interface IWageSyncer {
    
    /**
     * @dev Event emitted after a successful sync.
     */ 
    event WageSync();
    /**
     * @dev Event emitted when adding a new trading pair.
     * @param pairAddress the pair's address
     * @param callData data needed to perform the low level call
     */ 
    event PairAdded(address pairAddress, bytes callData);
    /**
     * @dev Event emitted when removing a trading pair.
     * @param pairAddress the pair's address
     */ 
    event PairRemoved(address pairAddress);
    
     /**
     * @dev The sync function. Called by Wage's contract after each rebase.
     * This function has been designed to support future trading pairs on different dexes.
     * We are sending a low level function call to apply the same syncing logic to every pair
     */ 
    function sync() external;
    /**
     * @dev Adds a pair to the pairs array. Can only be called  by the owner
     * @param pairAddress the pair's address.
     * @param data the data to send when calling the low level function `functionCall`
     */ 
    function addPair(address pairAddress, bytes calldata data) external;
    /**
     * @dev Removes a pair from tthe pairs array. Can  only be called by the owner.
     * @param pair the pair's address
     */ 
    function removePair(address pair) external;
    
}

contract Wage is IWage, ERC20, AuthorizedAccess {
    
    using SafeMath for uint256;
    
    uint256 private constant MAX_UINT256 = 2 ** 256 - 1;
    uint128 private constant MAX_SUPPLY = 2 ** 128 - 1;
    
    uint256 private _gonsPerFragment;
    
    mapping(address => uint256) private _lockedGons;
    
     // Union Governance / Rebase Settings
    uint256 public nextReb; // when's it time for the next rebase?
    uint256 public rebaseAmount = 1e18; // initial is 1
    uint256 public rebaseRate = 10800; // initial is every 3 hours
    bool public rebState; // Is rebase enabled?
    uint256 public rebaseCount = 0;
    
    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private immutable TOTAL_GONS;
    
    //Blocks token transfers when set to false
    bool public _transfersEnabled;
    
    //The address of the wage syncer.
    //Used to sync trading pairs across different exchanges.
    IWageSyncer public _syncer;
    
    
    constructor(string memory name, string memory symbol, uint256 initialSupply, bool shouldEnableTransfers) ERC20(name, symbol) public {
        //A temporary variaable is necessary here.
        //Solidity doesn't allow reading from an immutable variable during contract initialization
        uint256 totalGonsTemp = MAX_UINT256 - (MAX_UINT256 % initialSupply);
        TOTAL_GONS = totalGonsTemp;
        
        _totalSupply = initialSupply;
        
        _gonsPerFragment = totalGonsTemp.div(initialSupply);
        
        _balances[msg.sender] = totalGonsTemp;

        //Enables transfers if specified in the constructor
        _transfersEnabled = shouldEnableTransfers;
        
    }
    
    /**
     * @dev Modifier that prevents transfers from every address (except the owner of the contract) when the _transfersEnabled flag is set to false 
     */
    modifier transfersEnabled() {
        require(_transfersEnabled || msg.sender == owner(), "Transfers are disabled");
        _;
    }
    
    /**
     * @dev Enables transfers when called. Once enabled, transfers cannot be disabled.
     */ 
    function enableTransfers() public onlyOwner override {
        _transfersEnabled = true;
        emit TransfersEnabled();
    }
    
    //REBASE LOGIC FORKED FROM uFragments.
    
    /**
     * @dev Notifies Fragments contract about a new rebase cycle. Can only be called by the contract owner
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 supplyDelta) external onlyOwner override returns (uint256) {
        return _rebase(supplyDelta);
    }
    
    /**
     * @dev Notifies Fragments contract about a new rebase cycle. Can only be called internally.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function _rebase(uint256 supplyDelta) internal returns (uint256) {
        if (supplyDelta == 0) {
            emit LogRebase(now, _totalSupply);
            return _totalSupply;
        }

        _totalSupply = _totalSupply.add(uint256(supplyDelta));

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);

        // From this point forward, _gonsPerFragment is taken as the source of truth.
        // We recalculate a new _totalSupply to be in agreement with the _gonsPerFragment
        // conversion rate.
        // This means our applied supplyDelta can deviate from the requested supplyDelta,
        // but this deviation is guaranteed to be < (_totalSupply^2)/(TOTAL_GONS - _totalSupply).
        //
        // In the case of _totalSupply <= MAX_UIN128 (our current supply cap), this
        // deviation is guaranteed to be < 1, so we can omit this step. If the supply cap is
        // ever increased, it must be re-included.
        // _totalSupply = TOTAL_GONS.div(_gonsPerFragment)

        //Syncing trading pairs
        _syncer.sync();
        
        rebaseCount.add(1);

        emit LogRebase(now, _totalSupply);
        return _totalSupply;
    }
    
    /**
     * @dev Toggles rebases. Can only be called by the owner
     * @param state Whether to enable or disable rebases
     */ 
    function toggleRebase(bool state) external override onlyOwner {
        rebState = state;
        //We are setting the next rebase's timestamp to now + rebaseRate.
        //Done to prevent multiple consecutive rebases
        nextReb =  now + rebaseRate;
        
        emit RebaseToggled(state);
    }
    
    /**
     * @dev Changes the amount of time between each rebase. Can only be called by the owner
     * @param newRate the new rebase rate (seconds)
     */ 
    function changeRebaseRate(uint256 newRate) external override onlyOwner {
        uint256 oldRate = rebaseRate;
        rebaseRate = newRate;
        nextReb = now.add(newRate);
        
        emit RebaseRateChanged(newRate, oldRate);
    }
    
    /**
     * @dev Changes the inflation amount after each rebase. Can only be called by the owner
     * @param newAmount the new inflation amount
     */ 
    function changeRebaseAmount(uint256 newAmount) external override onlyOwner {
        uint256 oldAmount = rebaseAmount;
        rebaseAmount = newAmount;
        
        emit RebaseAmountChanged(newAmount, oldAmount);
    }

    /**
     * @dev Sets a new syncer smart contract. Can only be called by the owner.
     * Syncers are used to sync trading pairs across dexes.
     * @param newSyncer the address of the new syncer smart contract
     */ 
    function changeWageSyncer(address newSyncer) external override onlyOwner {
        address oldSyncer = address(_syncer);
        _syncer = IWageSyncer(newSyncer);
        
        emit WageSyncerChanged(newSyncer, oldSyncer);
    }
    
    /**
     * @dev Returns the gons per fragment rate. Can only be called by the owner.
     * @return the gons per fragment rate
     */
    function gonsPerFragment() external view override onlyAuthorized("Address not authorized") returns (uint256) {
        return _gonsPerFragment;
    }
    
    /**
     * @dev Locks part of an address' gon balance. Needed for governance.
     * The amount of locked fragments inflates after each rebase.
     * @param target The target address
     * @param gonAmount the amount of gons to lock
     */
    function lock(address target, uint256 gonAmount) external override onlyAuthorized("Address not authorized") {
        require(_balances[target].sub(_lockedGons[target]) >= gonAmount, "Insufficient unlocked balance");
        
        _lockedGons[target] = _lockedGons[target].add(gonAmount);
        
        emit TokensLocked(target, gonAmount.div(_gonsPerFragment));
    }
    
    /**
     * @dev Unlocks part of an adress' locked gon balane. Needed for governance.
     * @param target The target address
     * @param gonAmount the amount of gons to unlock
     */
    function unlock(address target, uint256 gonAmount) external override onlyAuthorized("Address not authorized") {
        require(_lockedGons[target] >= gonAmount, "Insufficient locked balance");
        
        _lockedGons[target] = _lockedGons[target].sub(gonAmount);
        
        emit TokensUnlocked(target, gonAmount.div(_gonsPerFragment));
    }
    
    
    /**
     * @dev Returns the current locked fragments for an address
     * @param addr the address
     */ 
    function getLockedFragments(address addr) external view override returns (uint256) {
        return _lockedGons[addr].div(_gonsPerFragment);
    }
    
    /**
     * @dev Executes a token transfer and rebases if the conditions are met. Can only be called internally
     * @param from the address who's sending the tokens
     * @param to the recipient address
     * @param value the amount to transfer
     */
    function _transfer(address from, address to, uint256 value) internal override transfersEnabled {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        
        uint256 gonsAmount = value.mul(_gonsPerFragment);
        require(_balances[from].sub(_lockedGons[from]) >= gonsAmount, "Insufficient unlocked balance");

        //Rebases if the conditions are met. 
        if (rebState && now >= nextReb) {
            _rebase(rebaseAmount);
            nextReb = now.add(rebaseRate);
        }
        
        uint256 gonValue = value.mul(_gonsPerFragment);
        _balances[from] = _balances[from].sub(gonValue);
        _balances[to] = _balances[to].add(gonValue);
        emit Transfer(from, to, value);
    }
    
    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view override(ERC20, IERC20) returns (uint256) {
        return _balances[who].div(_gonsPerFragment);
    }
}