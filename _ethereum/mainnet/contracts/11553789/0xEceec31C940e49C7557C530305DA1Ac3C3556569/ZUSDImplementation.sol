// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/proxy/Initializable.sol

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 * 
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 * 
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// File: contracts/ZUSDImplementation.sol

pragma solidity 0.6.0;




/**
 * @title ZUSDImplementation
 * @dev This contract is a Pausable ERC20 token with issuance
 * controlled by a central Issuer. By implementing ZUSDImplementation
 * this contract also includes external methods for setting
 * a new implementation contract for the Proxy.
 * NOTE: The storage defined here will actually be held in the Proxy
 * contract and all calls to this contract should be made through
 * the proxy, including admin actions done as owner or issuer.
 * Any call to transfer against this contract should fail
 * since the contract is paused and there are no balances.
 */
contract ZUSDImplementation is IERC20, Initializable {
    /**
     * MATH
     */

    using SafeMath for uint256;

    /**
     * DATA
     * NOTE: Do NOT reorder any declared variables and ONLY append variables.
     * The proxy relies on existing variables to remain in the same address space.
     */

    // ERC20 CONSTANT DETAILS
    string public constant name = "Zytara USD";
    string public constant symbol = "ZUSD";
    uint8 public constant decimals = 6;

    // ERC20 DATA
    mapping(address => uint256) internal _balances;
    uint256 public override totalSupply;
    mapping(address => mapping(address => uint256)) internal _allowances;

    // OWNER DATA
    address public owner;
    address public proposedOwner;

    // PAUSABILITY DATA
    bool public paused;

    // COMPLIANCE DATA
    address public complianceRole;
    mapping(address => bool) internal _frozen;

    // ISSUER DATA
    address public issuer;

    /**
     * EVENTS
     */

    // ERC20 EVENTS
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // OWNABLE EVENTS
    event OwnershipTransferProposed(
        address indexed currentOwner,
        address indexed proposedOwner
    );
    event OwnershipTransferDisregarded(address indexed oldProposedOwner);
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    // PAUSABLE EVENTS
    event Pause();
    event Unpause();

    // COMPLIANCE EVENTS
    event FreezeAddress(address indexed addr);
    event UnfreezeAddress(address indexed addr);
    event WipeFrozenAddress(address indexed addr);
    event ComplianceRoleSet(
        address indexed oldComplianceRole,
        address indexed newComplianceRole
    );

    // ISSUER EVENTS
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event IssuerSet(address indexed oldIssuer, address indexed newIssuer);

    /**
     * FUNCTIONALITY
     */

    // INITIALIZATION FUNCTIONALITY

    /**
     * @dev sets 0 initial tokens, the owner, and the issuer.
     * this serves as the constructor for the proxy but compiles to the
     * memory model of the Implementation contract.
     */
    function initialize() public initializer {
        owner = msg.sender;
        proposedOwner = address(0);
        complianceRole = address(0);
        totalSupply = 0;
        issuer = msg.sender;
        paused = false;
    }

    // ERC20 FUNCTIONALITY

    /**
     * @dev Gets the balance of the specified address.
     * @param addr The address to query the the balance of.
     * Returns a uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address addr) external view override returns (uint256) {
        return _balances[addr];
    }

    /**
     * @dev Transfer token to a specified address from msg.sender
     * Note: the use of Safemath ensures that value is nonnegative.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value)
        external
        override
        whenNotPaused
        returns (bool)
    {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override whenNotPaused returns (bool) {
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(
            value
        );
        _transfer(from, to, value);

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, value);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * @param spender The address that will spend the tokens.
     * @param addedValue The increase in the number of tokens that can be spent.
     *
     * This mitigates the problem described in:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     */
    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * @param spender The address that will spend the tokens.
     * @param subtractedValue The decrease in the number of tokens that can be spent.
     *
     * This mitigates the problem described in:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue)
        );
        return true;
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param _owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(
        address _owner,
        address spender,
        uint256 value
    ) internal {
        require(!_frozen[_owner] && !_frozen[spender], "address frozen");
        require(
            spender != address(0),
            "cannot approve allowance for zero address"
        );

        _allowances[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * Returns a uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        require(to != address(0), "cannot transfer to address zero");
        require(!_frozen[from] && !_frozen[to], "address frozen");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    // OWNER FUNCTIONALITY

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    /**
     * @dev Allows the current owner to begin transferring control of the contract to a proposedOwner
     * @param newProposedOwner The address to transfer ownership to.
     */
    function proposeOwner(address newProposedOwner) external onlyOwner {
        require(
            newProposedOwner != address(0),
            "cannot transfer ownership to address zero"
        );
        require(msg.sender != newProposedOwner, "caller already is owner");

        proposedOwner = newProposedOwner;
        emit OwnershipTransferProposed(owner, proposedOwner);
    }

    /**
     * @dev Allows the current owner or proposed owner to cancel transferring control of the contract to a proposedOwner
     */
    function disregardProposeOwner() external {
        require(
            msg.sender == proposedOwner || msg.sender == owner,
            "only proposedOwner or owner"
        );
        require(
            proposedOwner != address(0),
            "can only disregard a proposed owner that was previously set"
        );

        address oldProposedOwner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferDisregarded(oldProposedOwner);
    }

    /**
     * @dev Allows the proposed owner to complete transferring control of the contract to the proposedOwner.
     */
    function claimOwnership() external {
        require(msg.sender == proposedOwner, "onlyProposedOwner");

        address oldOwner = owner;
        owner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferred(oldOwner, owner);
    }

    // PAUSABILITY FUNCTIONALITY

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "whenNotPaused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() external onlyOwner {
        require(!paused, "already paused");

        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyOwner {
        require(paused, "already unpaused");

        paused = false;
        emit Unpause();
    }

    // COMPLIANCE FUNCTIONALITY

    /**
     * @dev Gets the frozen status of the specified address.
     * @param addr The address to query the the status of.
     * Returns a bool representing whether the address is frozen.
     */
    function frozen(address addr) external view returns (bool) {
        return _frozen[addr];
    }

    /**
     * @dev Sets a new compliance role address.
     * @param newComplianceRole The new address allowed to freeze/unfreeze addresses and seize their tokens.
     */
    function setComplianceRole(address newComplianceRole) external {
        require(
            msg.sender == complianceRole || msg.sender == owner,
            "only complianceRole or Owner"
        );

        emit ComplianceRoleSet(complianceRole, newComplianceRole);
        complianceRole = newComplianceRole;
    }

    modifier onlyComplianceRole() {
        require(msg.sender == complianceRole, "onlyComplianceRole");
        _;
    }

    /**
     * @dev Freezes an address balance from being transferred.
     * @param addr The new address to freeze.
     */
    function freeze(address addr) external onlyComplianceRole {
        require(!_frozen[addr], "address already frozen");

        _frozen[addr] = true;
        emit FreezeAddress(addr);
    }

    /**
     * @dev Unfreezes an address balance allowing transfer.
     * @param addr The new address to unfreeze.
     */
    function unfreeze(address addr) external onlyComplianceRole {
        require(_frozen[addr], "address already unfrozen");

        _frozen[addr] = false;
        emit UnfreezeAddress(addr);
    }

    /**
     * @dev Wipes the balance of a frozen address, burning the tokens
     * and setting the approval to zero.
     * @param addr The new frozen address to wipe.
     */
    function wipeFrozenAddress(address addr) external onlyComplianceRole {
        require(_frozen[addr], "address is not frozen");

        uint256 _balance = _balances[addr];
        _burn(addr, _balance);
        emit WipeFrozenAddress(addr);
    }

    // ISSUER FUNCTIONALITY

    /**
     * @dev Sets a new issuer address.
     * @param newIssuer The address allowed to mint tokens to control supply.
     */
    function setIssuer(address newIssuer) external onlyOwner {
        require(newIssuer != address(0), "cannot set issuer to address zero");
        emit IssuerSet(issuer, newIssuer);
        issuer = newIssuer;
    }

    modifier onlyIssuer() {
        require(msg.sender == issuer, "onlyIssuer");
        _;
    }

    /**
     * @dev Increases the total supply by minting the specified number of tokens to the issuer account.
     * @param value The number of tokens to add.
     * Returns a boolean that indicates if the operation was successful.
     */
    function mint(uint256 value)
        external
        onlyIssuer
        whenNotPaused
        returns (bool success)
    {
        _mint(issuer, value);

        return true;
    }

    /**
     * @dev Increases the total supply by minting the specified number of tokens to the specified account.
     * @param value The number of tokens to add.
     * Returns a boolean that indicates if the operation was successful.
     */
    function mintTo(address to, uint256 value)
        external
        onlyIssuer
        whenNotPaused
        returns (bool)
    {
        _mint(to, value);

        return true;
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of _balances such that the
     * proper events are emitted.
     * @param to The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address to, uint256 value) internal {
        require(to != address(0), "cannot mint to address zero");
        require(!_frozen[to], "address frozen");

        totalSupply = totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        emit Mint(to, value);
        emit Transfer(address(0), to, value);
    }

    /**
     * @dev Decreases the total supply by burning the specified number of tokens.
     * @param value The number of tokens to remove.
     * Returns a boolean that indicates if the operation was successful.
     */
    function burn(uint256 value) external returns (bool) {
        require(!_frozen[msg.sender], "address frozen");
        _burn(msg.sender, value);

        return true;
    }

    /**
     * @dev Decreases the total supply by burning the specified number of tokens from the specified address.
     * @param value The number of tokens to remove.
     * Returns a boolean that indicates if the operation was successful.
     */
    function burnFrom(address from, uint256 value) external returns (bool) {
        require(!_frozen[from] && !_frozen[msg.sender], "address frozen");
        _burn(from, value);
        _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(
            value
        );

        return true;
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param addr The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address addr, uint256 value) internal {
        totalSupply = totalSupply.sub(value);
        _balances[addr] = _balances[addr].sub(value);
        emit Burn(addr, value);
        emit Transfer(addr, address(0), value);
    }
}