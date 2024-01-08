// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// File: @openzeppelin/contracts/math/SafeMath.sol

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: contracts/VestingVault12.sol

// adpted from https://gist.github.com/rstormsf/7cfb0c6b7a835c0c67b4a394b4fd9383

// pragma solidity 0.4.24;
pragma solidity ^0.5.0;



contract VestingVault12 {
  using SafeMath for uint256;
  using SafeMath for uint16;

  modifier onlyOwner {
    require(msg.sender == owner, "not owner");
    _;
  }

  modifier onlyValidAddress(address _recipient) {
    require(_recipient != address(0) && _recipient != address(this) && _recipient != address(token), "not valid _recipient");
    _;
  }

  uint256 constant internal SECONDS_PER_DAY = 86400;

  struct Grant {
    uint256 startTime;
    uint256 amount;
    uint16 vestingDuration;
    uint16 vestingCliff;
    uint16 daysClaimed;
    uint256 totalClaimed;
    address recipient;
  }

  event GrantAdded(address indexed recipient, uint256 vestingId);
  event GrantTokensClaimed(address indexed recipient, uint256 amountClaimed);
  event GrantRemoved(address recipient, uint256 amountVested, uint256 amountNotVested);
  event ChangedOwner(address owner);

  ERC20 public token;

  mapping (uint256 => Grant) public tokenGrants;
  mapping (address => uint[]) private activeGrants;
  address public owner;
  uint256 public totalVestingCount;

  constructor(ERC20 _token) public {
    require(address(_token) != address(0));
    owner = msg.sender;
    token = _token;
  }

  function addTokenGrant(
    address _recipient, // who'll receive the $$$
    uint256 _startTime, // set to zero to start today and make sure it's in the future
    uint256 _amount, // how many tokens we want them to get
    uint16 _vestingDurationInDays, // the total vesting duration
    uint16 _vestingCliffInDays // the cliff
  )
  external
  onlyOwner
  {
    require(_vestingCliffInDays <= 10*365, "more than 10 years");
    require(_vestingDurationInDays <= 25*365, "more than 25 years");
    require(_vestingDurationInDays >= _vestingCliffInDays, "Duration < Cliff");

    uint256 amountVestedPerDay = _amount.div(_vestingDurationInDays);
    require(amountVestedPerDay > 0, "amountVestedPerDay > 0");

    // Transfer the grant tokens under the control of the vesting contract
    require(token.transferFrom(owner, address(this), _amount), "transfer failed");

    Grant memory grant = Grant({
      startTime: _startTime == 0 ? currentTime() : _startTime,
      amount: _amount,
      vestingDuration: _vestingDurationInDays,
      vestingCliff: _vestingCliffInDays,
      daysClaimed: 0,
      totalClaimed: 0,
      recipient: _recipient
    });

    tokenGrants[totalVestingCount] = grant;
    activeGrants[_recipient].push(totalVestingCount);
    emit GrantAdded(_recipient, totalVestingCount);
    totalVestingCount++;
  }

  function getActiveGrants(address _recipient) public view returns(uint256[] memory){
    return activeGrants[_recipient];
  }

  /// @notice Calculate the vested and unclaimed months and tokens available for `_grantId` to claim
  /// Due to rounding errors once grant duration is reached, returns the entire left grant amount
  /// Returns (0, 0) if cliff has not been reached
  function calculateGrantClaim(uint256 _grantId) public view returns (uint16, uint256) {
    Grant storage tokenGrant = tokenGrants[_grantId];

    // For grants created with a future start date, that hasn't been reached, return 0, 0
    if (currentTime() < tokenGrant.startTime) {
      return (0, 0);
    }

    // 1624382065 - 1624382065 == 0
    uint elapsedTime = currentTime().sub(tokenGrant.startTime);

    // 0 / 86400 == 0
    uint elapsedDays = elapsedTime.div(SECONDS_PER_DAY);

    // 1 < 0 (if the cliff is ) - that's 1 days since time started btw
    if (elapsedDays < tokenGrant.vestingCliff) {
      return (uint16(elapsedDays), 0);
    }

    // If over vesting duration, all tokens vested
    if (elapsedDays >= tokenGrant.vestingDuration) {
      uint256 remainingGrant = tokenGrant.amount.sub(tokenGrant.totalClaimed);
      return (tokenGrant.vestingDuration, remainingGrant);
    } else {
      // 0 days minus 0 days
      uint16 daysVested = uint16(elapsedDays.sub(tokenGrant.daysClaimed));

      // 1000000 tokens / 10 days == 100000
      uint256 amountVestedPerDay = tokenGrant.amount.div(uint256(tokenGrant.vestingDuration));

      // 0 * 100000 === 0
      // which means we cannot claim on day 0.
      uint256 amountVested = uint256(daysVested.mul(amountVestedPerDay));
      return (daysVested, amountVested);
    }
  }

  /// @notice Allows a grant recipient to claim their vested tokens. Errors if no tokens have vested
  /// It is advised recipients check they are entitled to claim via `calculateGrantClaim` before calling this
  function claimVestedTokens(uint256 _grantId) external {
    uint16 daysVested;
    uint256 amountVested;
    (daysVested, amountVested) = calculateGrantClaim(_grantId);
    require(amountVested > 0, "amountVested is 0");

    Grant storage tokenGrant = tokenGrants[_grantId];
    tokenGrant.daysClaimed = uint16(tokenGrant.daysClaimed.add(daysVested));
    tokenGrant.totalClaimed = uint256(tokenGrant.totalClaimed.add(amountVested));

    require(token.transfer(tokenGrant.recipient, amountVested), "no tokens");
    emit GrantTokensClaimed(tokenGrant.recipient, amountVested);
  }

  /// @notice Terminate token grant transferring all vested tokens to the `_grantId`
  /// and returning all non-vested tokens to the V12 owner
  /// Secured to the V12 owner only
  /// @param _grantId grantId of the token grant recipient
  function removeTokenGrant(uint256 _grantId)
  external
  onlyOwner
  {
    Grant storage tokenGrant = tokenGrants[_grantId];
    address recipient = tokenGrant.recipient;
    uint16 daysVested;
    uint256 amountVested;
    (daysVested, amountVested) = calculateGrantClaim(_grantId);

    uint256 amountNotVested = (tokenGrant.amount.sub(tokenGrant.totalClaimed)).sub(amountVested);

    require(token.transfer(recipient, amountVested));
    require(token.transfer(owner, amountNotVested));

    tokenGrant.startTime = 0;
    tokenGrant.amount = 0;
    tokenGrant.vestingDuration = 0;
    tokenGrant.vestingCliff = 0;
    tokenGrant.daysClaimed = 0;
    tokenGrant.totalClaimed = 0;
    tokenGrant.recipient = address(0);

    emit GrantRemoved(recipient, amountVested, amountNotVested);
  }

  function currentTime() private view returns(uint256) {
    return block.timestamp;
  }

  function tokensVestedPerDay(uint256 _grantId) public view returns(uint256) {
    Grant storage tokenGrant = tokenGrants[_grantId];
    return tokenGrant.amount.div(uint256(tokenGrant.vestingDuration));
  }

  function changeOwner(address _newOwner)
  external
  onlyOwner
  onlyValidAddress(_newOwner)
  {
    owner = _newOwner;
    emit ChangedOwner(_newOwner);
  }

}