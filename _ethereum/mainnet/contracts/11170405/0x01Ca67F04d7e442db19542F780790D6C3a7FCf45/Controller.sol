
// File: @openzeppelin/contracts-ethereum-package/contracts/Initializable.sol

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol

pragma solidity ^0.6.0;


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
contract ContextUpgradeSafe is Initializable {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.

    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {


    }


    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/access/Ownable.sol

pragma solidity ^0.6.0;


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
contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {


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

    uint256[49] private __gap;
}

// File: @daostack/infra-experimental/contracts/Reputation.sol

// : GPL-3.0
pragma solidity 0.6.12;



/**
 * @title Reputation system
 * @dev A DAO has Reputation System which allows peers to rate other peers in order to build trust .
 * A reputation is use to assign influence measure to a DAO'S peers.
 * Reputation is similar to regular tokens but with one crucial difference: It is non-transferable.
 * The Reputation contract maintain a map of address to reputation value.
 * It provides an onlyOwner functions to mint and burn reputation _to (or _from) a specific address.
 */
contract Reputation is OwnableUpgradeSafe {

    uint8 public decimals = 18;             //Number of decimals of the smallest unit
    // Event indicating minting of reputation to an address.
    event Mint(address indexed _to, uint256 _amount);
    // Event indicating burning of reputation for an address.
    event Burn(address indexed _from, uint256 _amount);
    uint256 constant private ZERO_HALF_256 =  0xffffffffffffffffffffffffffffffff;

      /// @dev `Checkpoint` is the structure that attaches a block number to a
      ///  given value, the block number attached is the one that last changed the
      ///  value
      //Checkpoint is uint256 :
      // bits 0-127 `fromBlock` is the block number that the value was generated from
      // bits 128-255 `value` is the amount of reputation at a specific block number

      // `balances` is the map that tracks the balance of each address, in this
      //  contract when the balance changes the block number that the change
      //  occurred is also included in the map
    mapping (address => uint256[]) public balances;

      // Tracks the history of the `totalSupply` of the reputation
    uint256[] public totalSupplyHistory;

    /// @notice Generates `_amount` reputation that are assigned to `_owner`
    /// @param _user The address that will be assigned the new reputation
    /// @param _amount The quantity of reputation generated
    /// @return True if the reputation are generated correctly
    function mint(address _user, uint256 _amount) external onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply, "total supply overflow"); // Check for overflow
        uint256 previousBalanceTo = balanceOf(_user);
        require(previousBalanceTo + _amount >= previousBalanceTo, "balace overflow"); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_user], previousBalanceTo + _amount);
        emit Mint(_user, _amount);
        return true;
    }

    /// @notice Burns `_amount` reputation from `_owner`
    /// @param _user The address that will lose the reputation
    /// @param _amount The quantity of reputation to burn
    /// @return True if the reputation are burned correctly
    function burn(address _user, uint256 _amount) external onlyOwner returns (bool) {
        uint256 curTotalSupply = totalSupply();
        uint256 amountBurned = _amount;
        uint256 previousBalanceFrom = balanceOf(_user);
        if (previousBalanceFrom < amountBurned) {
            amountBurned = previousBalanceFrom;
        }
        updateValueAtNow(totalSupplyHistory, curTotalSupply - amountBurned);
        updateValueAtNow(balances[_user], previousBalanceFrom - amountBurned);
        emit Burn(_user, amountBurned);
        return true;
    }

    /**
    * @dev initialize
    */
    function initialize(address _owner)
    public
    initializer {
        __Ownable_init_unchained();
        transferOwnership(_owner);
    }

    /// @dev This function makes it easy to get the total number of reputation
    /// @return The total number of reputation
    function totalSupply() public view returns (uint256) {
        return totalSupplyAt(block.number);
    }

  ////////////////
  // Query balance and totalSupply in History
  ////////////////
    /**
    * @dev return the reputation amount of a given owner
    * @param _owner an address of the owner which we want to get his reputation
    */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

      /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
      /// @param _owner The address from which the balance will be retrieved
      /// @param _blockNumber The block number when the balance is queried
      /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint256 _blockNumber)
    public view returns (uint256)
    {
        if ((balances[_owner].length == 0) || (uint128(balances[_owner][0]) > _blockNumber)) {
            return 0;
          // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

      /// @notice Total amount of reputation at a specific `_blockNumber`.
      /// @param _blockNumber The block number when the totalSupply is queried
      /// @return The total amount of reputation at `_blockNumber`
    function totalSupplyAt(uint256 _blockNumber) public view returns(uint256) {
        if ((totalSupplyHistory.length == 0) || (uint128(totalSupplyHistory[0]) > _blockNumber)) {
            return 0;
          // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

  ////////////////
  // Internal helper functions to query and set a value in a snapshot array
  ////////////////
      /// @dev `getValueAt` retrieves the number of reputation at a given block number
      /// @param checkpoints The history of values being queried
      /// @param _block The block number to retrieve the value at
      /// @return The number of reputation being queried
    function getValueAt(uint256[] storage checkpoints, uint256 _block) internal view returns (uint256) {
        if (checkpoints.length == 0) {
            return 0;
        }

          // Shortcut for the actual value
        if (_block >= uint128(checkpoints[checkpoints.length-1])) {
            return checkpoints[checkpoints.length-1]>>128;
        }
        if (_block < uint128(checkpoints[0])) {
            return 0;
        }

          // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length-1;
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (uint128(checkpoints[mid]) <= _block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min]>>128;
    }

      /// @dev `updateValueAtNow` used to update the `balances` map and the
      ///  `totalSupplyHistory`
      /// @param checkpoints The history of data being updated
      /// @param _value The new number of reputation
    function updateValueAtNow(uint256[] storage checkpoints, uint256 _value) internal {
        require(uint128(_value) == _value, "reputation overflow"); //check value is in the 128 bits bounderies
        if ((checkpoints.length == 0) || (uint128(checkpoints[checkpoints.length - 1]) < block.number)) {
            checkpoints.push(uint256(uint128(block.number)) | _value<<128);
        } else {
            checkpoints[checkpoints.length-1] =
            uint256((checkpoints[checkpoints.length-1] & uint256(ZERO_HALF_256)) | (_value<<128));
        }
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/utils/Address.sol

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.6.0;






/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20MinterPauser}.
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
contract ERC20UpgradeSafe is Initializable, ContextUpgradeSafe, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

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

    function __ERC20_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
    }

    function __ERC20_init_unchained(string memory name, string memory symbol) internal initializer {


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
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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

    uint256[44] private __gap;
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.6.0;




/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeSafe is Initializable, ContextUpgradeSafe, ERC20UpgradeSafe {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {


    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }

    uint256[50] private __gap;
}

// File: contracts/controller/DAOToken.sol

pragma solidity ^0.6.12;
// : GPL-3.0





/**
 * @title DAOToken, base on zeppelin contract.
 * @dev ERC20 compatible token. It is a mintable, burnable token.
 */
contract DAOToken is ERC20BurnableUpgradeSafe, OwnableUpgradeSafe {

    uint256 public cap;

    /**
    * @dev initialize
    * @param _name - token name
    * @param _symbol - token symbol
    * @param _cap - token cap - 0 value means no cap
    */
    function initialize(string calldata _name, string calldata _symbol, uint256 _cap, address _owner)
    external
    initializer {
        cap = _cap;
        __ERC20_init_unchained(_name, _symbol);
        __Ownable_init_unchained();
        transferOwnership(_owner);
    }

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) {
        if (cap > 0) {
            require(totalSupply().add(_amount) <= cap, "override cap");
        }
        _mint(_to, _amount);
        return true;
    }
}

// File: contracts/controller/Vault.sol

pragma solidity ^0.6.12;
// : GPL-3.0



//Proxy contracts cannot recive eth via fallback function.
//For now , we will use this vault to overcome that
contract Vault is OwnableUpgradeSafe {
    event ReceiveEther(address indexed _sender, uint256 _value);
    event SendEther(address indexed _to, uint256 _value);

    /**
    * @dev initialize
    * @param _owner vault owner
    */
    function initialize(address _owner)
    external
    initializer {
        __Ownable_init_unchained();
        transferOwnership(_owner);
    }

    /**
    * @dev enables this contract to receive ethers
    */
    /* solhint-disable */
    receive() external payable {
        emit ReceiveEther(msg.sender, msg.value);
    }

    function sendEther(uint256 _amountInWei, address payable _to) external onlyOwner returns(bool) {
        // solhint-disable-next-line avoid-call-value
        (bool success, ) = _to.call{value:_amountInWei}("");
        require(success, "sendEther failed.");
        emit SendEther(_to, _amountInWei);
    }
}

// File: @openzeppelin/contracts-ethereum-package/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/controller/Avatar.sol

pragma solidity ^0.6.12;
// : GPL-3.0







/**
 * @title An Avatar holds tokens, reputation and ether for a controller
 */
contract Avatar is Initializable, OwnableUpgradeSafe {
    using SafeERC20 for IERC20;

    string public orgName;
    DAOToken public nativeToken;
    Reputation public nativeReputation;
    Vault public vault;
    mapping(string=>string) public db;

    event GenericCall(address indexed _contract, bytes _data, uint _value, bool _success);
    event ExternalTokenTransfer(address indexed _externalToken, address indexed _to, uint256 _value);
    event ExternalTokenTransferFrom(address indexed _externalToken, address _from, address _to, uint256 _value);
    event ExternalTokenApproval(address indexed _externalToken, address _spender, uint256 _value);
    event MetaData(string _metaData);

    /**
    * @dev enables an avatar to receive ethers
    */
    /* solhint-disable */
    receive() external payable {
       if (msg.sender != address(vault)) {
          sendEthToVault();
        }
    }

    /**
    * @dev initialize takes organization name, native token and reputation system
    and creates an avatar for a controller
    */
    function initialize(string calldata _orgName,
                        DAOToken _nativeToken,
                        Reputation _nativeReputation,
                        address _owner)
    external
    initializer {
        orgName = _orgName;
        nativeToken = _nativeToken;
        nativeReputation = _nativeReputation;
        __Ownable_init_unchained();
        transferOwnership(_owner);
        vault = new Vault();
        vault.initialize(address(this));
    }

    /**
    * @dev perform a generic call to an arbitrary contract
    * @param _contract  the contract's address to call
    * @param _data ABI-encoded contract call to call `_contract` address.
    * @param _value value (ETH) to transfer with the transaction
    * @return success  success or fail
    *         returnValue - the return bytes of the called contract's function.
    */
    function genericCall(address _contract, bytes calldata _data, uint256 _value)
    external
    onlyOwner
    returns(bool success, bytes memory returnValue) {
        if (_value > 0) {
            vault.sendEther(_value, address(this));
        }
        // solhint-disable-next-line avoid-call-value
        (success, returnValue) = _contract.call{value:_value}(_data);
        emit GenericCall(_contract, _data, _value, success);
    }

    /**
    * @dev send ethers from the avatar's wallet
    * @param _amountInWei amount to send in Wei units
    * @param _to send the ethers to this address
    * @return bool which represents success
    */
    function sendEther(uint256 _amountInWei, address payable _to) external onlyOwner returns(bool) {
        vault.sendEther(_amountInWei, _to);
        return true;
    }

    /**
    * @dev external token transfer
    * @param _externalToken the token contract
    * @param _to the destination address
    * @param _value the amount of tokens to transfer
    * @return bool which represents success
    */
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value)
    external onlyOwner returns(bool)
    {
        _externalToken.safeTransfer(_to, _value);
        emit ExternalTokenTransfer(address(_externalToken), _to, _value);
        return true;
    }

    /**
    * @dev external token transfer from a specific account
    * @param _externalToken the token contract
    * @param _from the account to spend token from
    * @param _to the destination address
    * @param _value the amount of tokens to transfer
    * @return bool which represents success
    */
    function externalTokenTransferFrom(
        IERC20 _externalToken,
        address _from,
        address _to,
        uint256 _value
    )
    external onlyOwner returns(bool)
    {
        _externalToken.safeTransferFrom(_from, _to, _value);
        emit ExternalTokenTransferFrom(address(_externalToken), _from, _to, _value);
        return true;
    }

    /**
    * @dev externalTokenApproval approve the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _value the amount of ether (in Wei) which the approval is referring to.
    * @return bool which represents a success
    */
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value)
    external onlyOwner returns(bool)
    {
        _externalToken.safeApprove(_spender, _value);
        emit ExternalTokenApproval(address(_externalToken), _spender, _value);
        return true;
    }

    /**
    * @dev metaData emits an event with a string, should contain the hash of some meta data.
    * @param _metaData a string representing a hash of the meta data
    * @return bool which represents a success
    */
    function metaData(string calldata _metaData) external onlyOwner returns(bool) {
        emit MetaData(_metaData);
        return true;
    }

    /**
    * @dev setDBValue set a key value in the dao db
    * @param _key a string
    * @param _value a string
    * @return true if successful
    */
    function setDBValue(string calldata _key, string calldata _value) external onlyOwner returns(bool) {
        db[_key] = _value;
        return true;
    }

    /**
    * @dev sendEthToVault send eth to Vault. (if such balance exist)
    * For a case where ETH is beeing sent to the contrtact bypass the fallback function(e.g by destroyself).
    */
    function sendEthToVault() public {
        address(vault).transfer(address(this).balance);
    }

}

// File: contracts/globalConstraints/GlobalConstraintInterface.sol

pragma solidity ^0.6.12;
// : GPL-3.0

// solhint-disable-next-line indent
abstract contract GlobalConstraintInterface {

    enum CallPhase { Pre, Post, PreAndPost }

    function pre( address _scheme, bytes32 _method ) public virtual returns(bool);
    function post( address _scheme, bytes32 _method ) public virtual returns(bool);
    /**
     * @dev when return if this globalConstraints is pre, post or both.
     * @return CallPhase enum indication  Pre, Post or PreAndPost.
     */
    function when() public virtual returns(CallPhase);
}

// File: contracts/controller/Controller.sol

pragma solidity ^0.6.12;
// : GPL-3.0




/**
 * @title Controller contract
 * @dev A controller controls the organizations tokens, reputation and avatar.
 * It is subject to a set of schemes and constraints that determine its behavior.
 */
contract Controller is Initializable {

    struct GlobalConstraintRegister {
        bool isRegistered; //is registered
        uint256 index;    //index at globalConstraints
    }

    // A bitwise flags of permissions,
                         // All 0: Not registered,
                         // 1st bit: Flag if the scheme is registered,
                         // 2nd bit: Scheme can register other schemes
                         // 3rd bit: Scheme can add/remove global constraints
                         // 4th bit: Scheme can upgrade the controller
                         // 5th bit: Scheme can call genericCall on behalf of
                         //          the organization avatar
    mapping(address=>bytes4) public schemesPermissions;

    Avatar public avatar;
    DAOToken public nativeToken;
    Reputation public nativeReputation;
  // newController will point to the new controller after the present controller is upgraded
    address public newController;
  // globalConstraintsPre that determine pre conditions for all actions on the controller

    address[] public globalConstraintsPre;
  // globalConstraintsPost that determine post conditions for all actions on the controller
    address[] public globalConstraintsPost;
  // globalConstraintsRegisterPre indicate if a globalConstraints is registered as a pre global constraint
    mapping(address=>GlobalConstraintRegister) public globalConstraintsRegisterPre;
  // globalConstraintsRegisterPost indicate if a globalConstraints is registered as a post global constraint
    mapping(address=>GlobalConstraintRegister) public globalConstraintsRegisterPost;

    event MintReputation (address indexed _sender, address indexed _to, uint256 _amount);
    event BurnReputation (address indexed _sender, address indexed _from, uint256 _amount);
    event MintTokens (address indexed _sender, address indexed _beneficiary, uint256 _amount);
    event RegisterScheme (address indexed _sender, address indexed _scheme);
    event UnregisterScheme (address indexed _sender, address indexed _scheme);
    event UpgradeController(address indexed _oldController, address _newController);

    event AddGlobalConstraint(
        address indexed _globalConstraint,
        GlobalConstraintInterface.CallPhase _when);

    event RemoveGlobalConstraint(address indexed _globalConstraint, uint256 _index, bool _isPre);

    function initialize( Avatar _avatar, address initialScheme ) external initializer {
        avatar = _avatar;
        nativeToken = avatar.nativeToken();
        nativeReputation = avatar.nativeReputation();
        schemesPermissions[initialScheme] = bytes4(0x0000001F);
        emit RegisterScheme(msg.sender, initialScheme);
    }

  // Modifiers:
    modifier onlyRegisteredScheme() {
        require(schemesPermissions[msg.sender]&bytes4(0x00000001) == bytes4(0x00000001),
        "sender is not registered scheme");
        _;
    }

    modifier onlyRegisteringSchemes() {
        require(schemesPermissions[msg.sender]&bytes4(0x00000002) == bytes4(0x00000002),
        "sender unautorized to register scheme");
        _;
    }

    modifier onlyGlobalConstraintsScheme() {
        require(schemesPermissions[msg.sender]&bytes4(0x00000004) == bytes4(0x00000004),
        "sender is not globalConstraint scheme");
        _;
    }

    modifier onlyUpgradingScheme() {
        require(schemesPermissions[msg.sender]&bytes4(0x00000008) == bytes4(0x00000008),
        "sender is not UpgradingScheme");
        _;
    }

    modifier onlyGenericCallScheme() {
        require(schemesPermissions[msg.sender]&bytes4(0x00000010) == bytes4(0x00000010),
        "sender is not a Generic Scheme");
        _;
    }

    modifier onlyMetaDataScheme() {
        require(schemesPermissions[msg.sender]&bytes4(0x00000010) == bytes4(0x00000010),
        "sender is not a MetaData Scheme");
        _;
    }

    modifier onlySubjectToConstraint(bytes32 func) {
        uint256 idx;
        for (idx = 0; idx < globalConstraintsPre.length; idx++) {
            require(
            (GlobalConstraintInterface(globalConstraintsPre[idx]))
            .pre(msg.sender, func), "not allowed by globalConstraint");
        }
        _;
        for (idx = 0; idx < globalConstraintsPost.length; idx++) {
            require(
            (GlobalConstraintInterface(globalConstraintsPost[idx]))
            .post(msg.sender, func), "not allowed by globalConstraint");
        }
    }

    /**
     * @dev Mint `_amount` of reputation that are assigned to `_to` .
     * @param  _amount amount of reputation to mint
     * @param _to beneficiary address
     * @return bool which represents a success
     */
    function mintReputation(uint256 _amount, address _to)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("mintReputation")
    returns(bool)
    {
        emit MintReputation(msg.sender, _to, _amount);
        return nativeReputation.mint(_to, _amount);
    }

    /**
     * @dev Burns `_amount` of reputation from `_from`
     * @param _amount amount of reputation to burn
     * @param _from The address that will lose the reputation
     * @return bool which represents a success
     */
    function burnReputation(uint256 _amount, address _from)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("burnReputation")
    returns(bool)
    {
        emit BurnReputation(msg.sender, _from, _amount);
        return nativeReputation.burn(_from, _amount);
    }

    /**
     * @dev mint tokens .
     * @param  _amount amount of token to mint
     * @param _beneficiary beneficiary address
     * @return bool which represents a success
     */
    function mintTokens(uint256 _amount, address _beneficiary)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("mintTokens")
    returns(bool)
    {
        emit MintTokens(msg.sender, _beneficiary, _amount);
        return nativeToken.mint(_beneficiary, _amount);
    }

  /**
   * @dev register a scheme
   * @param _scheme the address of the scheme
   * @param _permissions the permissions the new scheme will have
   * @return bool which represents a success
   */
    function registerScheme(address _scheme, bytes4 _permissions)
    external
    onlyRegisteringSchemes
    onlySubjectToConstraint("registerScheme")
    returns(bool)
    {

        bytes4 permissions = schemesPermissions[_scheme];

    // Check scheme has at least the permissions it is changing, and at least the current permissions:
    // Implementation is a bit messy. One must recall logic-circuits ^^

    // produces non-zero if sender does not have all of the perms that are changing between old and new
        require(bytes4(0x0000001f)&(_permissions^permissions)&(~schemesPermissions[msg.sender]) == bytes4(0),
        "sender unautorize to register scheme");

    // produces non-zero if sender does not have all of the perms in the old scheme
        require(bytes4(0x0000001f)&(permissions&(~schemesPermissions[msg.sender])) == bytes4(0),
        "sender unautorize to register scheme");

    // Add or change the scheme:
        schemesPermissions[_scheme] = _permissions|bytes4(0x00000001);
        emit RegisterScheme(msg.sender, _scheme);
        return true;
    }

    /**
     * @dev unregister a scheme
     * @param _scheme the address of the scheme
     * @return bool which represents a success
     */
    function unregisterScheme(address _scheme)
    external
    onlyRegisteringSchemes
    onlySubjectToConstraint("unregisterScheme")
    returns(bool)
    {
    //check if the scheme is registered
        if (_isSchemeRegistered(_scheme) == false) {
            return false;
        }
    // Check the unregistering scheme has enough permissions:
        require(bytes4(0x0000001f)&(schemesPermissions[_scheme]&(~schemesPermissions[msg.sender])) == bytes4(0),
        "sender unautorized to unregister scheme");

    // Unregister:
        emit UnregisterScheme(msg.sender, _scheme);
        delete schemesPermissions[_scheme];
        return true;
    }

    /**
     * @dev unregister the caller's scheme
     * @return bool which represents a success
     */
    function unregisterSelf() external returns(bool) {
        if (_isSchemeRegistered(msg.sender) == false) {
            return false;
        }
        delete schemesPermissions[msg.sender];
        emit UnregisterScheme(msg.sender, msg.sender);
        return true;
    }

    /**
     * @dev add or update Global Constraint
     * @param _globalConstraint the address of the global constraint to be added.
     * @return bool which represents a success
     */
    function addGlobalConstraint(address _globalConstraint)
    external
    onlyGlobalConstraintsScheme
    returns(bool)
    {
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        if ((when == GlobalConstraintInterface.CallPhase.Pre)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!globalConstraintsRegisterPre[_globalConstraint].isRegistered) {
                globalConstraintsPre.push(_globalConstraint);
                globalConstraintsRegisterPre[_globalConstraint] =
                GlobalConstraintRegister(true, globalConstraintsPre.length-1);
            }
        }
        if ((when == GlobalConstraintInterface.CallPhase.Post)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            if (!globalConstraintsRegisterPost[_globalConstraint].isRegistered) {
                globalConstraintsPost.push(_globalConstraint);
                globalConstraintsRegisterPost[_globalConstraint] =
                GlobalConstraintRegister(true, globalConstraintsPost.length-1);
            }
        }
        emit AddGlobalConstraint(_globalConstraint, when);
        return true;
    }

    /**
     * @dev remove Global Constraint
     * @param _globalConstraint the address of the global constraint to be remove.
     * @return bool which represents a success
     */
     // solhint-disable-next-line code-complexity
    function removeGlobalConstraint (address _globalConstraint)
    external
    onlyGlobalConstraintsScheme
    returns(bool)
    {
        GlobalConstraintRegister memory globalConstraintRegister;
        address globalConstraint;
        GlobalConstraintInterface.CallPhase when = GlobalConstraintInterface(_globalConstraint).when();
        bool retVal = false;

        if ((when == GlobalConstraintInterface.CallPhase.Pre)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            globalConstraintRegister = globalConstraintsRegisterPre[_globalConstraint];
            if (globalConstraintRegister.isRegistered) {
                if (globalConstraintRegister.index < globalConstraintsPre.length-1) {
                    globalConstraint = globalConstraintsPre[globalConstraintsPre.length-1];
                    globalConstraintsPre[globalConstraintRegister.index] = globalConstraint;
                    globalConstraintsRegisterPre[globalConstraint].index = globalConstraintRegister.index;
                }
                globalConstraintsPre.pop();
                delete globalConstraintsRegisterPre[_globalConstraint];
                retVal = true;
            }
        }
        if ((when == GlobalConstraintInterface.CallPhase.Post)||
            (when == GlobalConstraintInterface.CallPhase.PreAndPost)) {
            globalConstraintRegister = globalConstraintsRegisterPost[_globalConstraint];
            if (globalConstraintRegister.isRegistered) {
                if (globalConstraintRegister.index < globalConstraintsPost.length-1) {
                    globalConstraint = globalConstraintsPost[globalConstraintsPost.length-1];
                    globalConstraintsPost[globalConstraintRegister.index] = globalConstraint;
                    globalConstraintsRegisterPost[globalConstraint].index = globalConstraintRegister.index;
                }
                globalConstraintsPost.pop();
                delete globalConstraintsRegisterPost[_globalConstraint];
                retVal = true;
            }
        }
        if (retVal) {
            emit RemoveGlobalConstraint(
            _globalConstraint,
            globalConstraintRegister.index,
            when == GlobalConstraintInterface.CallPhase.Pre
            );
        }
        return retVal;
    }

  /**
    * @dev upgrade the Controller
    *      The function will trigger an event 'UpgradeController'.
    * @param  _newController the address of the new controller.
    * @return bool which represents a success
    */
    function upgradeController(address _newController)
    external
    onlyUpgradingScheme
    returns(bool)
    {
        // make sure upgrade could be done once for a contract.
        require(newController == address(0), "this controller was already upgraded");
        require(_newController != address(0), "new controller cannot be 0");
        newController = _newController;
        avatar.transferOwnership(_newController);
        require(avatar.owner() == _newController, "failed to transfer avatar ownership to the new controller");
        if (nativeToken.owner() == address(this)) {
            nativeToken.transferOwnership(_newController);
            require(nativeToken.owner() == _newController, "failed to transfer token ownership to the new controller");
        }
        if (nativeReputation.owner() == address(this)) {
            nativeReputation.transferOwnership(_newController);
            require(nativeReputation.owner() == _newController,
            "failed to transfer reputation ownership to the new controller");
        }
        emit UpgradeController(address(this), newController);
        return true;
    }

    /**
    * @dev perform a generic call to an arbitrary contract
    * @param _contract  the contract's address to call
    * @param _data ABI-encoded contract call to call `_contract` address.
    * @param _value value (ETH) to transfer with the transaction
    * @return bool -success
    *         bytes  - the return value of the called _contract's function.
    */
    function genericCall(address _contract, bytes calldata _data, uint256 _value)
    external
    onlyGenericCallScheme
    onlySubjectToConstraint("genericCall")
    returns (bool, bytes memory)
    {
        return avatar.genericCall(_contract, _data, _value);
    }

  /**
   * @dev send some ether
   * @param _amountInWei the amount of ether (in Wei) to send
   * @param _to address of the beneficiary
   * @return bool which represents a success
   */
    function sendEther(uint256 _amountInWei, address payable _to)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("sendEther")
    returns(bool)
    {
        return avatar.sendEther(_amountInWei, _to);
    }

    /**
    * @dev send some amount of arbitrary ERC20 Tokens
    * @param _externalToken the address of the Token Contract
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @return bool which represents a success
    */
    function externalTokenTransfer(IERC20 _externalToken, address _to, uint256 _value)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenTransfer")
    returns(bool)
    {
        return avatar.externalTokenTransfer(_externalToken, _to, _value);
    }

    /**
    * @dev transfer token "from" address "to" address
    *      One must to approve the amount of tokens which can be spend from the
    *      "from" account.This can be done using externalTokenApprove.
    * @param _externalToken the address of the Token Contract
    * @param _from address of the account to send from
    * @param _to address of the beneficiary
    * @param _value the amount of ether (in Wei) to send
    * @return bool which represents a success
    */
    function externalTokenTransferFrom(
    IERC20 _externalToken,
    address _from,
    address _to,
    uint256 _value)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenTransferFrom")
    returns(bool)
    {
        return avatar.externalTokenTransferFrom(_externalToken, _from, _to, _value);
    }

    /**
    * @dev externalTokenApproval approve the spender address to spend a specified amount of tokens
    *      on behalf of msg.sender.
    * @param _externalToken the address of the Token Contract
    * @param _spender address
    * @param _value the amount of ether (in Wei) which the approval is referring to.
    * @return bool which represents a success
    */
    function externalTokenApproval(IERC20 _externalToken, address _spender, uint256 _value)
    external
    onlyRegisteredScheme
    onlySubjectToConstraint("externalTokenIncreaseApproval")
    returns(bool)
    {
        return avatar.externalTokenApproval(_externalToken, _spender, _value);
    }

    /**
    * @dev setDBValue set a key value in the dao db
    * @param _key a string
    * @param _value a string
    * @return bool success
    */
    function setDBValue(string calldata _key, string calldata _value)
    external
    onlyRegisteredScheme returns(bool) {
        return avatar.setDBValue(_key, _value);
    }

    /**
    * @dev metaData emits an event with a string, should contain the hash of some meta data.
    * @param _metaData a string representing a hash of the meta data
    * @return bool which represents a success
    */
    function metaData(string calldata _metaData)
        external
        onlyMetaDataScheme
        returns(bool)
        {
        return avatar.metaData(_metaData);
    }

    function isSchemeRegistered(address _scheme) external view returns(bool) {
        return _isSchemeRegistered(_scheme);
    }

   /**
    * @dev globalConstraintsCount return the global constraint pre and post count
    * @return uint256 globalConstraintsPre count.
    * @return uint256 globalConstraintsPost count.
    */
    function globalConstraintsCount()
        external
        view
        returns(uint, uint)
        {
        return (globalConstraintsPre.length, globalConstraintsPost.length);
    }

    function isGlobalConstraintRegistered(address _globalConstraint)
        external
        view
        returns(bool)
        {
        return (globalConstraintsRegisterPre[_globalConstraint].isRegistered ||
                globalConstraintsRegisterPost[_globalConstraint].isRegistered);
    }

    function _isSchemeRegistered(address _scheme) private view returns(bool) {
        return (schemesPermissions[_scheme]&bytes4(0x00000001) != bytes4(0));
    }
}
