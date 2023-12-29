// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;


interface IERC20 {
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

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}


// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}


// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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


// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)
/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}


/**
 * @title WrappedVoxaLinkPro
 * @dev ERC20 Token, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract WrappedVoxaLinkPro is ERC20, Ownable {

    /**
     * @dev Sets the values for {name}, {symbol}, and mints the initial supply to the creator.
     * All three of these values are immutable: they can only be set once during construction.
     * @param owner Address to whom the initial tokens will be minted.
     * @param amount The amount of tokens to mint initially.
     */
    
    constructor(address owner, uint256 amount) ERC20("Wrapped VoxaLinkPro", "wVXLP") Ownable(msg.sender) {
        _mint(owner, amount);
    }

        /**
     * @dev Burns a specific amount of tokens from the caller's account.
     * @param amount The amount of token to be burned.
     */

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}

/**
 * @title VoxaLinkProICO
 * @dev This contract manages the ICO for VoxaLinkPro tokens. It allows for buying tokens in different phases,
 * with different rates and bonuses, and tracks funds raised in each phase.
 */
contract VoxaLinkProICO is ReentrancyGuard, Ownable, Pausable {
    WrappedVoxaLinkPro public wVXLP;
    address payable public wallet;
    uint256 public constant MAX_PURCHASE = 2.5e6 ether;
    uint256[] public phaseRates = [50, 65, 80]; // Prices in USD cents
    uint256[] public fixedRates = [50, 65, 80];
    uint256[] public bonusRates = [7, 5, 0]; // Bonus rates in percentage
    uint256[] public phaseTokenAllocations = [100e6 ether, 60e6 ether, 80e6 ether]; // 200M, 120M, 80M
    uint256 public fundsRaisedPrivateSale = 0;
    uint256 public fundsRaisedPreSale = 0;
    uint256 public fundsRaisedPublicSale = 0;
    AggregatorV3Interface internal priceFeed;

    enum Phase { NotStarted, PrivateSale, PreSale, PublicSale, Ended }
    Phase public currentPhase;

    uint256 public icoStartTime;
    uint256[] public phaseEndTimes = [0, 0, 0];
    uint256[] public phaseDurations = [3456000, 2592000, 1728000]; // 40, 30, 20 days in seconds

    uint256 public constant pollDuration = 3600; // RATES UPDATED EVERY HOUR

    uint256 public lastPolledTime;
    
    mapping(address => uint256) public purchases; 

        /**
     * @dev Constructor sets the initial wallet to collect funds, creates the token, and sets the price feed.
     * @param _wallet Address where collected funds will be sent.
     * @param _priceFeed Address of the Chainlink Price Feed contract.
     */

    constructor(address payable _wallet, address _priceFeed) payable Ownable(msg.sender) {
        require(_wallet != address(0), "Wallet address cannot be zero");
        wVXLP = new WrappedVoxaLinkPro(address(this), 420e24); // 420M
        wallet = _wallet;
        lastPolledTime = block.timestamp; 
        currentPhase = Phase.NotStarted;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }
    // Only owner function that transfer 170,000,000 tokens to P2B for IEO.
    function transferToP2BIEO(address P2BWallet, uint256 amount) public onlyOwner {
        require(currentPhase == Phase.NotStarted, "This action could only have been done before ICO start!");
        wVXLP.transfer(P2BWallet, amount*(10**18));
    }
    
        /**
     * @dev Starts the ICO by changing the phase to PrivateSale and setting the start time and end times for phases.
     * Requires that the ICO has not started or already completed.
     */
    
    function startICO() public onlyOwner {
        require(currentPhase == Phase.NotStarted, "ICO has already started or completed"); // 
        currentPhase = Phase.PrivateSale;
        icoStartTime = block.timestamp;
        updateRate();
        updatePhaseEndTimes();
    }


       /**
     * @dev Allows users to buy tokens. Checks if the phase has ended and moves to next phase if necessary.
     * Updates the rate every hour. Transfers the purchased tokens to the buyer and forwards the funds to the wallet.
     * Requires that the ICO is in an active phase and not paused.
     */

    function buyTokens() external payable nonReentrant whenNotPaused {
        require(currentPhase != Phase.NotStarted && currentPhase != Phase.Ended, "Can't buy tokens in this phase.");
        if (phaseEndTimes[uint8(currentPhase)-1] <= block.timestamp) {
            moveToNextPhase();
            lastPolledTime = block.timestamp - 3600;
            updateRate();
        }
        if (block.timestamp  >= (pollDuration + lastPolledTime)) {
            updateRate();
        }
        uint256 currentRate = phaseRates[uint(currentPhase) - 1]; 
        processPurchase(msg.sender, msg.value, currentRate);
        wallet.transfer(msg.value); 
    }

    /**
     * @dev Internal function to process the token purchase. Calculates the total number of tokens (including bonuses)
     * and updates the token allocation for the phase. Also updates the funds raised.
     * @param purchaser Address of the buyer.
     * @param weiAmount The amount of Ether sent by the buyer.
     * @param currentRate The current rate of tokens per Ether.
     */

    function processPurchase(address purchaser, uint256 weiAmount, uint256 currentRate) internal {
        require(weiAmount > 0, "Zero purchase not allowed");

        (uint256 baseTokens, uint256 totalTokens) = calculateTotalTokens(weiAmount, currentRate, uint(currentPhase)-1);
        
        uint256 cumulativeAmount = purchases[purchaser];

        require(cumulativeAmount + baseTokens <= MAX_PURCHASE, "Purchase exceeds maximum limit");

        require(baseTokens <= phaseTokenAllocations[uint(currentPhase)-1], "Insufficient tokens available for purchase");

        phaseTokenAllocations[uint(currentPhase)-1] = phaseTokenAllocations[uint(currentPhase)-1] - baseTokens;
        purchases[purchaser] = purchases[purchaser] + baseTokens;
        updateFundsRaised(weiAmount);
        wVXLP.transfer(purchaser, totalTokens);
    }

    /**
     * @dev Calculates the total number of tokens a buyer gets for their Ether, including any bonus.
     * @param weiAmount The amount of Ether used for the purchase.
     * @param rate The current rate of tokens per Ether.
     * @param phaseIndex The index of the current phase.
     * @return (uint256, uint256) Returns the base number of tokens and the total number of tokens including bonus.
     */

    function calculateTotalTokens(uint256 weiAmount, uint256 rate, uint phaseIndex) internal view returns (uint256, uint256) {
        uint256 tokens = (weiAmount * rate) / 1e18;
        uint256 bonus = (tokens * bonusRates[phaseIndex]) / 100;
        uint256 totalTokens = tokens + bonus;
        return (tokens, totalTokens);
    }

        /**
     * @dev Updates the funds raised in the current phase by adding the specified wei amount.
     * @param weiAmount The amount of Ether to add to the funds raised.
     */

    function updateFundsRaised(uint256 weiAmount) private {
        if (currentPhase == Phase.PrivateSale) {
            fundsRaisedPrivateSale += weiAmount;
        } else if (currentPhase == Phase.PreSale) {
            fundsRaisedPreSale += weiAmount;
        } else if (currentPhase == Phase.PublicSale) {
            fundsRaisedPublicSale += weiAmount;
        }
    }

    /**
     * @dev Moves the ICO to the next phase. Burns any unsold tokens from the current phase.
     * Requires that the ICO is in a valid phase for transition.
     */

    function moveToNextPhase() public {
        require(currentPhase != Phase.NotStarted && currentPhase != Phase.Ended, "Invalid phase transition");
        if (owner() == _msgSender()) {
            burnUnsoldTokens(); 
            currentPhase = Phase(uint8(currentPhase) + 1);
            if (uint8(currentPhase) != 4) {
                updateRate();
            }
        }
        else {
            require(phaseEndTimes[uint8(currentPhase)-1] <= block.timestamp, "CANNOT MOVE PHASE AT THIS TIME");
            burnUnsoldTokens(); 
            currentPhase = Phase(uint8(currentPhase) + 1);
            if (uint8(currentPhase) != 4) {
                updateRate();
            }
        }
    }
    /**
     * @dev Internal function to burn unsold tokens from the current phase. Calculates and burns the unsold tokens
     * including any bonus tokens.
     */

    function burnUnsoldTokens() internal {
        uint256 unsoldTokens = phaseTokenAllocations[uint(currentPhase) - 1];
        uint256 remainingBonus = (unsoldTokens * bonusRates[uint(currentPhase) - 1])/100; 
        uint256 remainingTokens = unsoldTokens + remainingBonus;
        if (remainingTokens > 0) {
            wVXLP.burn(remainingTokens);
        }
    }


    /**
     * @dev Updates the rate of tokens per Ether based on the current price of Ether in USD. 
     * Requires that the ICO is in an active phase.
     */

    // Owner can updateRate() anytime however others can update rate every hour. It is advised that users DO NOT TRY TO CALL THE
    // updateRate() function themselves as they may lose Ethereum 

    function updateRate() public {
        require(currentPhase != Phase.NotStarted && currentPhase != Phase.Ended, "Can't buy tokens in this phase.");
        if (owner() == _msgSender()) {
            (, int256 price,,,) = priceFeed.latestRoundData();
            require(price > 0, "Invalid price data");

            uint256 ethPriceInUsd = uint256(price) * 1e10; // Convert Chainlink price to Wei for consistency
            uint256 tokenPriceInWei = fixedRates[uint(currentPhase) - 1] * 1e15; // Convert USD cents to Wei
            phaseRates[uint(currentPhase) - 1] = (1e18 * ethPriceInUsd) / tokenPriceInWei;
            lastPolledTime = block.timestamp; 
        }
        else {
            require(block.timestamp  >= (pollDuration + lastPolledTime), "Cannot update rate. Try again later"); 
                (, int256 price,,,) = priceFeed.latestRoundData();
                require(price > 0, "Invalid price data");

                uint256 ethPriceInUsd = uint256(price) * 1e10; // Convert Chainlink price to Wei for consistency
                uint256 tokenPriceInWei = fixedRates[uint(currentPhase) - 1] * 1e15; // Convert USD cents to Wei
                phaseRates[uint(currentPhase) - 1] = (1e18 * ethPriceInUsd) / tokenPriceInWei;
                lastPolledTime = block.timestamp; 
            
        }

        // emit RateUpdated(phaseRates[0], phaseRates[1], phaseRates[2]);
    }

    /**
     * @dev Returns the remaining token allocations for each phase of the ICO.
     * @return privateSaleRemaining Tokens remaining in Private Sale.
     * @return preSaleRemaining Tokens remaining in Pre Sale.
     * @return publicSaleRemaining Tokens remaining in Public Sale.
     */
    
    function getRemainingTokensForPhase() public view returns (uint256 privateSaleRemaining, uint256 preSaleRemaining, uint256 publicSaleRemaining) {
        privateSaleRemaining = phaseTokenAllocations[0];
        preSaleRemaining = phaseTokenAllocations[1];
        publicSaleRemaining = phaseTokenAllocations[2];
        return (privateSaleRemaining, preSaleRemaining, publicSaleRemaining);
    }

    /**
     * @dev Returns the token balance of a given address.
     * @param holder The address to query the balance of.
     * @return The number of tokens owned by the passed address.
     */
     
    function getTokenBalance(address holder) public view returns (uint256) {
        return wVXLP.balanceOf(holder);
    }

    /**
     * @dev Returns the current token allocation for the ongoing ICO phase.
     * @return The number of tokens allocated for the current phase.
     */      

    function getCurrentPhaseTokenAllocation() public view returns (uint256) {
        require(currentPhase != Phase.NotStarted && currentPhase != Phase.Ended, "Can't get allocations in this phase");
        
        return phaseTokenAllocations[uint(currentPhase) - 1];
    }

    /**
     * @dev Returns the amount of funds raised in each phase of the ICO.
     * @return The funds raised in the Private Sale, Pre Sale, and Public Sale, respectively.
     */

    function getFundsRaisedByPhase() public view returns (uint256, uint256, uint256) {
        return (fundsRaisedPrivateSale, fundsRaisedPreSale, fundsRaisedPublicSale);
    }

    /**
     * @dev Returns the current phase of the ICO.
     * @return The current phase of the ICO.
     */
   
    function getCurrentPhase() public view returns (Phase) {
        return currentPhase;
    }

     /**
     * @dev Returns the end time of a specified phase.
     * @param phaseIndex The index of the phase (0 for Private Sale, 1 for Pre Sale, 2 for Public Sale).
     * @return The end time of the specified phase.
     */  
 
    // function getPhaseEndTime(uint8 phaseIndex) public view returns (uint256) {
    //     return phaseEndTimes[phaseIndex];
    // }

    /**
     * @dev Returns the purchase information for a specific address.
     * @param purchaser The address to query purchase information of.
     * @return An array representing the amount of tokens purchased in each phase by the specified address.
     */

    // function getPurchaseInfo(address purchaser) public view returns (uint256[3] memory) {
    //     return purchases[purchaser];
    //  }

    /**
     * @dev Returns the total balance of tokens each phase for a specific address including bonuses.
     * @param purchaser The address to query the balance of.
     * @return An array representing the total balance of tokens for each phase for the specified address.
     */

    // function getTotalBalanceEachPhase (address purchaser) public view returns (uint256[3] memory) {
    //     uint256[3] memory totalBalanceEachPhase;
    //     for (uint i=0; i < purchases[purchaser].length; i++) {
    //         totalBalanceEachPhase[i] = (purchases[purchaser][i] * bonusRates[i] / 100) + purchases[purchaser][i]; 
    //     }
    //     return totalBalanceEachPhase;
    // }

   /**
     * @dev Returns the base amount of tokens purchased by a specific address.
     * @param purchaser The address to query the base purchased amount of.
     * @return The total base amount of tokens purchased by the specified address.
     */

    // function getBasePurchasedAmount(address purchaser) public view returns (uint256) {
    //     uint256 totalAmount = 0;
    //     for (uint i = 0; i < purchases[purchaser].length; i++) {
    //         totalAmount += purchases[purchaser][i];
    //     }
    //     return totalAmount;
    // }

    /**
     * @dev Returns the amount of tokens purchased by a specific address in a given phase.
     * @param purchaser The address to query the purchase amount of.
     * @param phase The phase to query the purchase amount in.
     * @return The amount of tokens purchased by the specified address in the given phase.
     */

    // function getPurchasedAmountInPhase(address purchaser, uint8 phase) public view returns (uint256) {
    //     require (Phase(phase) != Phase.NotStarted && Phase(phase) != Phase.Ended, "Invalid Phase");
    //     return purchases[purchaser][(uint(phase) -1)];
    // }

    /**
     * @dev Returns the start time of the ICO.
     * @return The timestamp of when the ICO started.
     */

    function getICOStartTime() public view returns (uint256) {
        return icoStartTime;
    }

    /**
     * @dev Internal function to update the end times of each phase based on their durations.
     * Used during the start of the ICO.
     */

    function updatePhaseEndTimes() internal {
        uint256 time = icoStartTime;
        for (uint8 i = 0; i < phaseDurations.length; i++) {
            time += phaseDurations[i];
            phaseEndTimes[i] = time;
        }
    }
}