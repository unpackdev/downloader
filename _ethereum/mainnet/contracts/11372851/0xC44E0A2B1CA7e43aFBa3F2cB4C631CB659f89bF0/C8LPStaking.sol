// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol



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

// File: @openzeppelin/contracts/utils/Address.sol



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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
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

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: @openzeppelin/contracts/GSN/Context.sol



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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: contracts/staking/interfaces/IC8LPStaking.sol

pragma solidity ^0.6.12;

interface IC8LPStaking {
  function announceReward(uint256 _reward) external returns (bool);
}

// File: contracts/staking/interfaces/IC8PNAVTracker.sol

pragma solidity ^0.6.12;

interface IC8PNAVTracker {
  function updateReward() external returns (bool);

  function getStakingRewardNow() external view returns (uint256);
}

// File: contracts/staking/C8LPStaking.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.12;







contract C8LPStaking is Ownable, IC8LPStaking {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct Announcement {
    uint256 rewardCarryFromPrevious;
    uint256 reward;
    uint256 rewardClaimed;
    uint256 stakingTotal;
  }

  struct User {
    uint32 blockTimestampGetReward;
    uint32 blockTimestampStakingAction;
    uint256 staking;
    uint256 totalClaimed;
  }

  uint256 private _currentRound;
  uint256 private _stakingTotal;
  uint32 private _blockTimestampAnnounce;

  mapping(uint256 => Announcement) private historicalAnnouncement;
  mapping(address => User) private Users;

  uint256 private _ableToClaim;
  uint256 private _ableToStake;

  address public usdt;
  address public c8_lp;
  address public nav_tracker;

  mapping(address => uint256) public dedicated;

  modifier onlyTrackerContract() {
    require(msg.sender == nav_tracker, "Staking: caller is not the nav_tracker contract");
    _;
  }

  modifier toGetReward() {
    require(_ableToClaim == 1, 'Reward updating in progress');
    _ableToClaim = 0;
    _;
    _ableToClaim = 1;
  }

  modifier toStaking() {
    require(_ableToStake == 1, 'Stake updating in progress');
    _ableToStake = 0;
    _;
    _ableToStake = 1;
  }

  event AddStake(
    address user,
    uint256 staking,
    uint256 staking_total_old,
    uint256 staking_total_new
  );

  event RemoveStake(
    address user,
    uint256 staking,
    uint256 staking_total_old,
    uint256 staking_total_new
  );

  event HasAnnouncement(
    uint256 new_reward,
    uint256 carry_previous_reward,
    uint256 staking_total,
    uint32 block_timestamp
  );

  event ClaimReward(
    address user,
    uint256 rewardClaimed,
    uint256 rewardRemaining,
    uint32 block_timestamp
  );

  constructor (address _usdt, address _c8_lp) public {
    usdt = _usdt;
    c8_lp = _c8_lp;
    nav_tracker = address(0);

    _ableToClaim = 1;
    _ableToStake = 1;

    _currentRound = 0;
    _stakingTotal = 0;
    _blockTimestampAnnounce = uint32(block.timestamp % 2 ** 32);
    emit HasAnnouncement(0, 0, 0, _blockTimestampAnnounce);
  }

  function updateTrackerContract(address _trackerContract) external onlyOwner {
    nav_tracker = _trackerContract;
  }

  function getLatestAnnouncementTimestamp() public view returns (uint256 latestAnnouncementTimestamp) {
    return _blockTimestampAnnounce;
  }

  function getCurrentRound() public view returns (uint256 currentRound) {
    return _currentRound;
  }

  function ableToClaimReward() public view returns (uint256) {
    return _ableToClaim;
  }

  function ableToStake() public view returns (uint256) {
    return _ableToStake;
  }

  function getCurrentStakingAmount(address _account) public view returns (uint256 currentStakingAmount) {
    return Users[_account].staking;
  }

  function getStakingUser(address _account) public view returns (
    uint32 blockTimestampGetReward,
    uint32 blockTimestampStakingAction,
    uint256 staking,
    uint256 totalClaimed) {

    return (
    Users[_account].blockTimestampGetReward,
    Users[_account].blockTimestampStakingAction,
    Users[_account].staking,
    Users[_account].totalClaimed
    );
  }

  function getStakingData(uint256 _round) public view returns (
    uint256 rewardCarryFromPrevious,
    uint256 reward,
    uint256 rewardClaimed,
    uint256 stakingTotal) {
    reward = historicalAnnouncement[_round].reward;
    uint256 _prev_round = _round - 1;
    rewardCarryFromPrevious = historicalAnnouncement[_prev_round].reward.add(historicalAnnouncement[_prev_round].rewardCarryFromPrevious).sub(historicalAnnouncement[_prev_round].rewardClaimed);
    if (_round == _currentRound) {
      reward = IC8PNAVTracker(nav_tracker).getStakingRewardNow();
    }

    return (
    rewardCarryFromPrevious,
    reward,
    historicalAnnouncement[_round].rewardClaimed,
    historicalAnnouncement[_round].stakingTotal
    );
  }

  function getCurrentTimestamp() public view returns (uint32 latestTimestamp){
    return uint32(block.timestamp % 2 ** 32);
  }

  function addStake(uint256 _amount) public toStaking {
    address _account = msg.sender;
    require(_amount > 0 && _account != address(0), 'Could not add stake');
    require(_amount <= IERC20(c8_lp).balanceOf(_account), 'Insufficient C8 LP token');

    if (rewardChecking(_account) == true) {
      claimReward();
    }

    IERC20(c8_lp).safeTransferFrom(msg.sender, address(this), _amount);

    Announcement storage _thisRound = historicalAnnouncement[_currentRound];
    _thisRound.stakingTotal = _thisRound.stakingTotal.add(_amount);

    User storage _user = Users[_account];
    uint32 _blockTimestamp = getCurrentTimestamp();
    if (_user.staking == 0) {
      _user.blockTimestampGetReward = _blockTimestamp;
    }
    _user.staking = _user.staking.add(_amount);
    _user.blockTimestampStakingAction = _blockTimestamp;

    uint256 _stakingTotal_old = _stakingTotal;
    _stakingTotal = _stakingTotal.add(_amount);
    emit AddStake(_account, _user.staking, _stakingTotal_old, _stakingTotal);
  }

  function removeStake(uint256 _amount) public toStaking {
    address _account = msg.sender;
    require(_amount > 0 && _account != address(0) && getCurrentStakingAmount(_account) >= _amount, 'Could not remove stake');
    if (rewardChecking(_account) == true) {
      claimReward();
    }

    IERC20(c8_lp).safeTransfer(msg.sender, _amount);

    Announcement storage _thisRound = historicalAnnouncement[_currentRound];
    _thisRound.stakingTotal = _thisRound.stakingTotal.sub(_amount);

    User storage _user = Users[_account];
    _user.staking = _user.staking.sub(_amount);
    _user.blockTimestampStakingAction = getCurrentTimestamp();

    uint256 _stakingTotal_old = _stakingTotal;
    _stakingTotal = _stakingTotal.sub(_amount);
    emit RemoveStake(_account, _user.staking, _stakingTotal_old, _stakingTotal);
  }

  function timeControl() public view returns (bool) {
    if (getCurrentTimestamp() >= _blockTimestampAnnounce + 8 days) {
      return false;
    } else {
      return true;
    }
  }

  function rewardChecking(address _account) public view returns (bool hasReward) {
    if (!timeControl()) {
      return false;
    }

    if (_currentRound == 0) {
      return false;
    } else if (Users[_account].blockTimestampGetReward < _blockTimestampAnnounce && Users[_account].staking > 0) {
      return true;
    } else {
      return false;
    }
  }

  function claimReward() public toGetReward {
    address _account = msg.sender;
    require(rewardChecking(_account) == true, 'No reward');
    Announcement storage _announcementRound = historicalAnnouncement[_currentRound - 1];
    User storage _user = Users[_account];
    uint256 _reward = _user.staking.mul(_announcementRound.reward.add(_announcementRound.rewardCarryFromPrevious)).div(_announcementRound.stakingTotal);

    require(_reward <= IERC20(usdt).balanceOf(address(this)), "Insufficient token");
    IERC20(usdt).safeTransfer(msg.sender, _reward);

    uint32 _blockTimestamp = getCurrentTimestamp();
    _user.blockTimestampGetReward = _blockTimestamp;
    _user.totalClaimed = _user.totalClaimed.add(_reward);
    _announcementRound.rewardClaimed = _announcementRound.rewardClaimed.add(_reward);

    uint256 remaining = _announcementRound.reward.add(_announcementRound.rewardCarryFromPrevious).sub(_announcementRound.rewardClaimed);
    emit ClaimReward(_account, _reward, remaining, _blockTimestamp);
  }

  function totalRewardClaimed(address _account) public view returns (uint256 total) {
    return Users[_account].totalClaimed;
  }

  function rewardDistributed() external onlyOwner {
    IC8PNAVTracker(nav_tracker).updateReward();
  }

  function announceReward(uint256 _rewardFromPool) public virtual override toGetReward toStaking onlyTrackerContract returns (bool status) {
    status = false;
    require(_rewardFromPool > 0, 'No reward distributed');
    uint256 _prevRound = _currentRound - 1;
    Announcement storage _thisRound = historicalAnnouncement[_currentRound];
    _thisRound.reward = _rewardFromPool;
    _thisRound.rewardClaimed = 0;
    uint256 _rewardRemaining = historicalAnnouncement[_prevRound].reward.add(historicalAnnouncement[_prevRound].rewardCarryFromPrevious).sub(historicalAnnouncement[_prevRound].rewardClaimed);
    _thisRound.rewardCarryFromPrevious = _rewardRemaining;
    _currentRound += 1;

    Announcement storage _nextRound = historicalAnnouncement[_currentRound];
    _nextRound.rewardCarryFromPrevious = 0;
    _nextRound.reward = 0;
    _nextRound.rewardClaimed = 0;
    _nextRound.stakingTotal = _stakingTotal;
    _blockTimestampAnnounce = getCurrentTimestamp();
    status = true;
    emit HasAnnouncement(_rewardFromPool, _rewardRemaining, _stakingTotal, _blockTimestampAnnounce);
  }

  function addReserveUSDT(uint256 _amount) external {
    require(_amount > 0, "Cannot add 0");
    require(_amount <= IERC20(usdt).balanceOf(msg.sender), "Insufficient token");
    dedicated[msg.sender] = dedicated[msg.sender].add(_amount);
    IERC20(usdt).safeTransferFrom(msg.sender, address(this), _amount);
  }

  function removeReserveUSDT(uint256 _amount) external {
    require(_amount > 0, "Cannot remove 0");
    require(_amount <= dedicated[msg.sender] && _amount <= getReserveUSDT(), "Insufficient token");
    dedicated[msg.sender] = dedicated[msg.sender].sub(_amount);
    IERC20(usdt).safeTransfer(msg.sender, _amount);
  }

  function getReserveUSDT() public view returns (uint256 amount) {
    return IERC20(usdt).balanceOf(address(this));
  }
}