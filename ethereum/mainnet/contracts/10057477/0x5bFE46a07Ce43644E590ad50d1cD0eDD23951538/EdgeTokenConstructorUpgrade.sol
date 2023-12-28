// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;



/**
 * @dev Implementation of the `IERC20` interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using `_mint`.
 * For a generic mechanism see `ERC20Mintable`.
 *
 * *For a detailed writeup see our guide [How to implement supply
 * mechanisms](https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226).*
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an `Approval` event is emitted on calls to `transferFrom`.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard `decreaseAllowance` and `increaseAllowance`
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See `IERC20.approve`.
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See `IERC20.totalSupply`.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See `IERC20.balanceOf`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See `IERC20.transfer`.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See `IERC20.allowance`.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See `IERC20.approve`.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev See `IERC20.transferFrom`.
     *
     * Emits an `Approval` event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of `ERC20`;
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to `approve` that can be used as a mitigation for
     * problems described in `IERC20.approve`.
     *
     * Emits an `Approval` event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to `transfer`, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a `Transfer` event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a `Transfer` event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

     /**
     * @dev Destoys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a `Transfer` event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an `Approval` event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See `_burn` and `_approve`.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
     * Ether and Wei.
     *
     * > Note that this information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * `IERC20.balanceOf` and `IERC20.transfer`.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: @sygnum/solidity-base-contracts/contracts/role/interface/IBaseOperators.sol

pragma solidity 0.5.0;

/**
 * @title IBaseOperators
 * @notice Interface for BaseOperators contract
 */
interface IBaseOperators {
    function isOperator(address _account) external view returns (bool);
    function isAdmin(address _account) external view returns (bool);
    function isSystem(address _account) external view returns (bool);
    function confirmFor(address _address) external;
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/Initializable.sol

pragma solidity 0.5.0;

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

  modifier whenInitialized() {
    require(initialized, "Initializable: Contract has not been initialized");
    _;
  }

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Initializable: Contract instance has already been initialized");

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
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  function isInitialized() public view returns (bool) {
    return initialized;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// File: @sygnum/solidity-base-contracts/contracts/role/Operatorable.sol

/**
 * @title Operatorable
 * @author Connor Howe <Connor.howe@sygnum.com>
 * @dev Operatorable contract stores the BaseOperators contract address, and modifiers for
 *       contracts.
 */

pragma solidity 0.5.0;



contract Operatorable is Initializable {
    IBaseOperators internal operatorsInst;
    address private operatorsPending;

    event OperatorsContractChanged(address indexed caller, address indexed operatorsAddress);
    event OperatorsContractPending(address indexed caller, address indexed operatorsAddress);

    /**
     * @dev Reverts if sender does not have operator role associated.
     */
    modifier onlyOperator() {
        require(isOperator(msg.sender), "Operatorable: caller does not have the operator role");
        _;
    }

    /**
     * @dev Reverts if sender does not have admin role associated.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Operatorable: caller does not have the admin role");
        _;
    }

    /**
     * @dev Reverts if sender does not have system role associated.
     */
    modifier onlySystem() {
        require(isSystem(msg.sender), "Operatorable: caller does not have the system role");
        _;
    }

    /**
     * @dev Reverts if sender does not have admin or system role associated.
     */
    modifier onlyAdminOrSystem() {
        require(isAdminOrSystem(msg.sender), "Operatorable: caller does not have the admin role nor system");
        _;
    }

    /**
     * @dev Reverts if sender does not have operator or system role associated.
     */
    modifier onlyOperatorOrSystem() {
        require(isOperatorOrSystem(msg.sender), "Operatorable: caller does not have the operator role nor system");
        _;
    }
    
    /**
     * @dev Initialization instead of constructor, called once. The setOperatorsContract function can be called only by Admin role with
     *       confirmation through the operators contract.
     * @param _baseOperators BaseOperators contract address.
     */
    function initialize(address _baseOperators) public initializer {
        _setOperatorsContract(_baseOperators);
    }

    /**
     * @dev Set the new the address of Operators contract, should be confirmed from operators contract by calling confirmFor(addr)
     *       where addr is the address of current contract instance. This is done to prevent the case when the new contract address is
     *       broken and control of the contract can be lost in such case
     * @param _baseOperators BaseOperators contract address.
     */
    function setOperatorsContract(address _baseOperators) public onlyAdmin {
        require(_baseOperators != address(0), "Operatorable: address of new operators contract can not be zero");
        operatorsPending = _baseOperators;
        emit OperatorsContractPending(msg.sender, _baseOperators);
    }

    /**
     * @dev The function should be called from new operators contract by admin to insure that operatorsPending address
     *       is the real contract address.
     */
    function confirmOperatorsContract() public {
        require(operatorsPending != address(0), "Operatorable: address of new operators contract can not be zero");
        require(msg.sender == operatorsPending, "Operatorable: should be called from new operators contract");
        _setOperatorsContract(operatorsPending);
    }

    /**
     * @return The address of the BaseOperators contract.
     */
    function getOperatorsContract() public view returns(address) {
        return address(operatorsInst);
    }

    /**
     * @return The pending address of the BaseOperators contract.
     */
    function getOperatorsPending() public view returns(address) {
        return operatorsPending;
    }

    /**
     * @return If '_account' has operator privileges.
     */
    function isOperator(address _account) public view returns (bool) {
        return operatorsInst.isOperator(_account);
    }

    /**
     * @return If '_account' has admin privileges.
     */
    function isAdmin(address _account) public view returns (bool) {
        return operatorsInst.isAdmin(_account);
    }

    /**
     * @return If '_account' has system privileges.
     */
    function isSystem(address _account) public view returns (bool) {
        return operatorsInst.isSystem(_account);
    }

    /**
     * @return If '_account' has admin or system privileges.
     */
    function isAdminOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isAdmin(_account) || operatorsInst.isSystem(_account));
    }

    /**
     * @return If '_account' has operator or system privileges.
     */
    function isOperatorOrSystem(address _account) public view returns (bool) {
        return (operatorsInst.isOperator(_account) || operatorsInst.isSystem(_account));
    }

    /** INTERNAL FUNCTIONS */
    function _setOperatorsContract(address _baseOperators) internal {
        require(_baseOperators != address(0), "Operatorable: address of new operators contract cannot be zero");
        operatorsInst = IBaseOperators(_baseOperators);
        emit OperatorsContractChanged(msg.sender, _baseOperators);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/Whitelist.sol

/**
 * @title Whitelist
 * @author Connor Howe <Connor.howe@sygnum.com>
 * @dev Whitelist contract with whitelist/unwhitelist functionality for particular addresses.  Whitelisting/unwhitelisting
        is controlled by operators/system in Operatorable contract which is initialized with the relevant BaseOperators address.
 */

pragma solidity 0.5.0;


contract Whitelist is Operatorable {
    mapping(address => bool) public whitelisted;

    event WhitelistToggled(address indexed account, bool whitelisted);

    /**
     * @dev Reverts if _account is not whitelisted.
     * @param _account address to determine if whitelisted.
     */
    modifier onlyWhitelisted(address _account) {
        require(isWhitelisted(_account), "Whitelist: account is not whitelisted");
        _;
    }

    /**
     * @dev Reverts if address is empty.
     * @param _address address to validate.
     */
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Whitelist: invalid address");
        _;
    }

    /**
    * @dev Getter to determine if address is whitelisted.
    * @param _account address to determine if whitelisted or not.
    * @return bool is whitelisted
    */
    function isWhitelisted(address _account) public view returns (bool) {
        return whitelisted[_account];
    }

    /**
     * @dev Toggle whitelisted/unwhitelisted on _account address, with _toggled being true/false.
     * @param _account address to toggle.
     * @param _toggled whitelist/unwhitelist.
     */
    function toggleWhitelist(address _account, bool _toggled)
        public
        onlyValidAddress(_account)
        onlyOperatorOrSystem
    {
        whitelisted[_account] = _toggled;
        emit WhitelistToggled(_account, whitelisted[_account]);
    }

    /**
     * @dev Batch whitelisted/unwhitelist multiple addresses, with _toggled being true/false.
     * @param _addresses address array.
     * @param _toggled whitelist/unwhitelist.
     */
    function batchToggleWhitelist(address[] memory _addresses, bool _toggled) public {
        require(_addresses.length <= 256, "Whitelist: batch count is greater than 256");
        for (uint256 i = 0; i < _addresses.length; i++) {
            toggleWhitelist(_addresses[i], _toggled);
        }
    }
}

// File: contracts/edge/ERC20/ERC20Whitelist.sol

pragma solidity 0.5.0;




contract ERC20Whitelist is ERC20, Whitelist {
    function transfer(address to, uint256 value) public onlyWhitelisted(msg.sender) onlyWhitelisted(to) returns (bool) {
        return super.transfer(to, value);
    }

    function approve(address spender, uint256 value) public onlyWhitelisted(msg.sender) onlyWhitelisted(spender) returns (bool) {
        return super.approve(spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public onlyWhitelisted(msg.sender) onlyWhitelisted(from) onlyWhitelisted(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function increaseAllowance(address spender, uint addedValue) public onlyWhitelisted(spender) onlyWhitelisted(msg.sender) returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public onlyWhitelisted(spender) onlyWhitelisted(msg.sender) returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function _burn(address account, uint256 value) internal onlyWhitelisted(account) {
        super._burn(account, value);
    }

    function _burnFrom(address account, uint256 amount) internal onlyWhitelisted(msg.sender) onlyWhitelisted(account) {
        super._burnFrom(account, amount);
    }

    function _mint(address account, uint256 amount) internal onlyWhitelisted(account) {
        super._mint(account, amount);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/Pausable.sol

/**
 * @title Pausable
 * @author Connor Howe <connor.howe@sygnum.com>
 * @dev Contract module which allows children to implement an emergency stop
 *      mechanism that can be triggered by an authorized account in the Operatorable
 *      contract.
 */
pragma solidity 0.5.0;


contract Pausable is Operatorable {
    event Paused(address indexed account);
    event Unpaused(address indexed account);

    bool internal _paused;

    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Reverts if contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by operator to pause child contract. The contract
     *      must not already be paused.
     */
    function pause() public onlyOperator whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /** @dev Called by operator to pause child contract. The contract
     *       must already be paused.
     */
    function unpause() public onlyOperator whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * @return If child contract is already paused or not.
     */
    function isNotPaused() public view returns(bool){
        return !_paused;
    }
}

// File: contracts/edge/ERC20/ERC20Pausable.sol

pragma solidity 0.5.0;




contract ERC20Pausable is ERC20, Pausable {
   function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function _burn(address account, uint256 value) internal whenNotPaused {
        super._burn(account, value);
    }

    function _burnFrom(address account, uint256 amount) internal whenNotPaused {
        super._burnFrom(account, amount);
    }

    function _mint(address account, uint256 amount) internal whenNotPaused {
        super._mint(account, amount);
    }
}

// File: @sygnum/solidity-base-contracts/contracts/helpers/Freezable.sol

/**
 * @title Freezable
 * @author Connor Howe <Connor.howe@sygnum.com>
 * @dev Freezable contract to freeze functionality for particular addresses.  Freezing/unfreezing is controlled
 *       by operators in Operatorable contract which is initialized with the relevant BaseOperators address.
 */

pragma solidity 0.5.0;


contract Freezable is Operatorable {
    mapping(address => bool) public frozen;

    event FreezeToggled(address indexed account, bool frozen);

    /**
     * @dev Reverts if address is empty.
     * @param _address address to validate.
     */
    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "Freezable: Empty address");
        _;
    }

    /**
     * @dev Reverts if account address is frozen.
     * @param _account address to validate is not frozen.
     */
    modifier whenNotFrozen(address _account) {
        require(!frozen[_account], "Freezable: account is frozen");
        _;
    }

    /**
     * @dev Reverts if account address is not frozen.
     * @param _account address to validate is frozen.
     */
    modifier whenFrozen(address _account) {
        require(frozen[_account], "Freezable: account is not frozen");
        _;
    }

    /**
     * @dev Getter to determine if address is frozen.
     * @param _account address to determine if frozen or not.
     * @return bool is frozen
     */
    function isFrozen(address _account) public view returns (bool) {
        return frozen[_account];
    }

    /**
     * @dev Toggle freeze/unfreeze on _account address, with _toggled being true/false.
     * @param _account address to toggle.
     * @param _toggled freeze/unfreeze.
     */
    function toggleFreeze(address _account, bool _toggled)
        public
        onlyValidAddress(_account)
        onlyOperator
    {
        frozen[_account] = _toggled;
        emit FreezeToggled(_account, frozen[_account]);
    }

    /**
     * @dev Batch freeze/unfreeze multiple addresses, with _toggled being true/false.
     * @param _addresses address array.
     * @param _toggled freeze/unfreeze.
     */
    function batchToggleFreeze(address[] memory _addresses, bool _toggled) public {
        require(_addresses.length <= 256, 'Freezable: batch count is greater than 256');
        for (uint256 i = 0; i < _addresses.length; i++) {
            toggleFreeze(_addresses[i], _toggled);
        }
    }
}

// File: contracts/edge/ERC20/ERC20Freezable.sol

pragma solidity 0.5.0;




contract ERC20Freezable is ERC20, Freezable {
   function transfer(address to, uint256 value) public whenNotFrozen(msg.sender) whenNotFrozen(to) returns (bool) {
        return super.transfer(to, value);
    }

    function approve(address spender, uint256 value) public whenNotFrozen(msg.sender) whenNotFrozen(spender) returns (bool) {
        return super.approve(spender, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotFrozen(msg.sender) whenNotFrozen(from) whenNotFrozen(to) returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function increaseAllowance(address spender, uint addedValue) public whenNotFrozen(msg.sender) whenNotFrozen(spender) returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotFrozen(msg.sender) whenNotFrozen(spender) returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }

    function _burnFrom(address account, uint256 amount) internal whenNotFrozen(msg.sender) whenNotFrozen(account) {
        super._burnFrom(account, amount);
    }
}

// File: contracts/edge/ERC20/ERC20Mintable.sol

pragma solidity 0.5.0;




contract ERC20Mintable is ERC20, Operatorable {
    function _mint(address account, uint256 amount) internal onlyOperatorOrSystem {
        require(amount > 0, 'ERC20Mintable: amount has to be greater than 0');
        super._mint(account, amount);
    }
}

// File: contracts/edge/ERC20/ERC20Burnable.sol

pragma solidity 0.5.0;



contract ERC20Burnable is ERC20, Operatorable {
    function _burnFor(address account, uint256 amount) internal onlyOperator {
        super._burn(account, amount);
    }
}

// File: contracts/edge/EdgeToken.sol

/**
 * @title EdgeToken
 * @author Connor Howe <connor.howe@sygnum.com>
 * @dev EdgeToken is a ERC20 token that is upgradable and pausable.
 *      User addresses require to be whitelisted for transfers
 *      to execute.  Addresses can be frozen, and funds from
 *      particular addresses can be confiscated.
 */
pragma solidity 0.5.0;










contract EdgeToken is ERC20, ERC20Detailed("Digital CHF", "DCHF", 2), Initializable, ERC20Whitelist,
                        ERC20Pausable, ERC20Freezable, ERC20Mintable, ERC20Burnable {

    event Minted(address indexed minter, address indexed account, uint256 value);
    event Burned(address indexed burner, uint256 value);
    event BurnedFor(address indexed burner, address indexed account, uint256 value);

    uint16 constant BATCH_LIMIT = 256;

    /**
     * @dev Initialization instead of constructor, only called once.
     * @param _baseOperators Address of baseOperators contract.
     */
    function initialize(address _baseOperators) public initializer {
        super.initialize(_baseOperators);
    }

    /**
    * @dev Burn.
    * @param _amount Amount of tokens to burn.
    */
    function burn(uint256 _amount) public {
        require(!isFrozen(msg.sender), "EdgeToken: Account must not be frozen");
        super._burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }

    /**
    * @dev BurnFor.
    * @param _account Account to burn tokens from.
    * @param _amount Amount of tokens to burn.
    */
    function burnFor(address _account, uint256 _amount) public {
        super._burnFor(_account, _amount);
        emit BurnedFor(msg.sender, _account, _amount);
    }

    /**
    * @dev burnFrom.
    * @param _account Account to burn from.
    * @param _amount Amount of tokens to burn.
    */
    function burnFrom(address _account, uint256 _amount) public {
        super._burnFrom(_account, _amount);
        emit Burned(_account, _amount);
    }

    /**
    * @dev Mint.
    * @param _account Address to mint tokens to.
    * @param _amount Amount to mint.
    */
    function mint(address _account, uint256 _amount) public {
        if(isSystem(msg.sender)){
            require(!isFrozen(_account), 'EdgeToken: Account must be frozen if system calling.');
        }
        super._mint(_account, _amount);
        emit Minted(msg.sender, _account, _amount);
    }

    /**
    * @dev confiscate.
    * @param _confiscatee Account to confiscate funds from.
    * @param _receiver Account to transfer confiscated funds too.
    * @param _amount Amount of tokens to burn.
    */
    function confiscate(address _confiscatee, address _receiver, uint256 _amount)
        public
        onlyOperator
        whenNotPaused
        onlyWhitelisted(_receiver)
        onlyWhitelisted(_confiscatee)
    {
        super._transfer(_confiscatee, _receiver, _amount);
     }

    /**
     * @dev Batch burn from an operator or admin address.
     * @param _recipients Array of recipient addresses.
     * @param _values Array of amount to burn.
     */
    function batchBurnFor(address[] memory _recipients, uint256[] memory _values) public returns (bool) {
        require(_recipients.length == _values.length, "EdgeToken: values and recipients are not equal.");
        require(_recipients.length <= BATCH_LIMIT, "EdgeToken: batch count is greater than BATCH_LIMIT.");
        for(uint256 i = 0; i < _recipients.length; i++) {
            burnFor(_recipients[i], _values[i]);
        }
    }

     /**
     * @dev Batch mint to a maximum of 255 addresses, for a custom amount for each address.
     * @param _recipients Array of recipient addresses.
     * @param _values Array of amount to mint.
     */
    function batchMint(address[] memory _recipients, uint256[] memory _values) public returns (bool) {
        require(_recipients.length == _values.length, "EdgeToken: values and recipients are not equal.");
        require(_recipients.length <= BATCH_LIMIT, "EdgeToken: greater than BATCH_LIMIT.");
        for(uint256 i = 0; i < _recipients.length; i++) {
            mint(_recipients[i], _values[i]);
        }
    }

     /**
    * @dev Batch confiscate to a macimum of 255 addresses. 
    * @param _confiscatees array addresses who's funds are being confiscated
    * @param _receivers array addresses who's receiving the funds
    * @param _values array of values of funds being confiscated
    */
    function batchConfiscate(address[] memory _confiscatees, address[] memory _receivers, uint256[] memory _values) public returns (bool) {
        require(_confiscatees.length == _values.length && _receivers.length == _values.length, "EdgeToken: values and recipients are not equal");
        require(_confiscatees.length <= BATCH_LIMIT, "EdgeToken: batch count is greater than BATCH_LIMIT");
        for(uint256 i = 0; i < _confiscatees.length; i++) {
            confiscate(_confiscatees[i], _receivers[i], _values[i]);
        }
    }
}

// File: contracts/edge/upgradeExample/EdgeTokenConstructorUpgrade.sol

/**
 * @title EdgeTokenConstructor
 * @author Connor Howe <connor.howe@sygnum.com> 
 * @dev This contract will be used in the first version of upgrading the EdgeToken to mitigate
 *      variables initialized in EdgeToken.sol constructor '_name, _symbol, _decimals' that are
 *      not initialized inside of EdgeTokenProxy.sol.  Additionally, as '_name, symbol, _decimals'
 *      were declared private, the getter functions 'name(), symbol(), decimals()' required to be
 *      overloaded to point to the correct/new/overloaded variables.
*/
pragma solidity 0.5.0;


contract EdgeTokenConstructorUpgrade is EdgeToken {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    bool public initializedConstructorUpgrade;

    function initializeConstructor() public {
      require(!initializedConstructorUpgrade, "EdgeTokenConstructorUpgrade: already initialized");
      _name = "Digital CHF";
      _symbol = "DCHF";
      _decimals = 2;
      initializedConstructorUpgrade = true;
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
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}