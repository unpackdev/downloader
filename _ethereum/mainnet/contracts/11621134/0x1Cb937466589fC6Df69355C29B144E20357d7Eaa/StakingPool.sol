// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


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

contract ReentrancyGuard {
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
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract LPTokenWrapper is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //Total amount locked info contract
    uint256 public totalSupply;
    //User's balances
    mapping(address => uint256) private balances;
    struct HistoryBalance {
        uint256 value;
        bool isSet;
    }
    mapping (uint256 => HistoryBalance) internal historyTotalSupply;
    struct UserData {
        //Period last time rewards claimed
        uint256 period;
        //Last time deposited. used to implement holdDays
        uint256 lastTime;
        bool exists;
        mapping (uint256 => HistoryBalance) historyBalance;
    }
    mapping (address => UserData) private userData;

    //Interface to wrapped token
    IERC20 public lpToken;
    //Hold in seconds before withdrawal after last time staked
    uint256 public holdTime;

    /**
     * @dev LPTokenWrapper constructor
     * @param _lpToken Wrapped token to be staked
     * @param _holdDays Hold days after last deposit
     */
    constructor(address _lpToken, uint256 _holdDays) internal {
        lpToken = IERC20(_lpToken);
        holdTime = _holdDays.mul(1 days);
    }

    /**
     * @dev Deposits a given amount of lpToken from sender
     * @param _amount Units of lpToken
     */
    function _stake(uint256 _amount, uint256 _period)
        internal
        nonReentrant
    {
        
        UserData storage _user = userData[msg.sender]; 
        if(!_user.exists){
            _user.period = _period;
            _user.exists = true;
        }
        totalSupply = totalSupply.add(_amount);
        _updateHistoryTotalSupply(_period, totalSupply);
        balances[msg.sender] = balances[msg.sender].add(_amount);
        _user.historyBalance[_period].value = balances[msg.sender];
        _user.historyBalance[_period].isSet = true;
        _user.lastTime = block.timestamp;
        lpToken.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev Withdraws a given stake from sender
     * @param _amount Units of lpToken
     */
    function _withdraw(uint256 _amount, uint256 _period)
        internal
        nonReentrant
    {
        //Check first if user has sufficient balance, added due to hold requrement 
        //("Cannot withdraw, tokens on hold" will be fired even if user  has no balance)
        require(balances[msg.sender] >= _amount, "Not enough balance");
        UserData storage _user = userData[msg.sender]; 
        require(block.timestamp.sub(_user.lastTime) >= holdTime, "Cannot withdraw, tokens on hold");
        totalSupply = totalSupply.sub(_amount);
        _updateHistoryTotalSupply(_period, totalSupply);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        _user.historyBalance[_period].value = balances[msg.sender];
        _user.historyBalance[_period].isSet = true;
        lpToken.safeTransfer(msg.sender, _amount);
    }

    /**
     * @dev Returns User Data
     * @param _address Address of the User
     */
     function _getUserData(address _address)
        internal
        view
        returns (UserData storage)
    {
        return userData[_address];
    }
    
    /**
     * @dev Updates history total supply
     * @param _period period
     * @param _totalSupply total supply for period
     */
     function _updateHistoryTotalSupply(uint256 _period, uint256 _totalSupply)
        internal
    {
        historyTotalSupply[_period].value = _totalSupply;
        historyTotalSupply[_period].isSet = true;
    }    

    /**
     * @dev Sets user's period and historyBalance at this period (last period rewards claimed)
     * @param _address address of the User
     * @param _period period till which balance claimed
     * @param _periodBalance user's historyBalance at period above
     */
     function _updateUser(address _address, uint256 _period, uint256 _periodBalance)
        internal
    {
        UserData storage _user = userData[_address]; 
        _user.period = _period;
        _user.historyBalance[_period].value = _periodBalance;
        _user.historyBalance[_period].isSet = true;
    }   

    /**
     * @dev Get the balance of a given account
     * @param _address User for which to retrieve balance
     */
    function balanceOf(address _address)
        public
        view
        returns (uint256)
    {
        return balances[_address];
    }    
}

// 
contract StakingPool is Ownable, ReentrancyGuard, LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    //Conctact status states
    enum Status {Setup, Running, Ended}
    //Status of contract
    Status public status;
    //Time when contracts starts
    uint256 public startTime;
    //Time when contract ends 
    uint256 public endTime;
    //Time when contract closes (endTime + gracePeriodTime)
    uint256 public closeTime;
    //Last Period
    uint256 public period;
    
    //Constants
    uint256 constant public CALC_PRECISION = 1e18;

    //Interface for Rewards Token
    IERC20 public rewardsToken;
    //Interface for Extra Rewards Token
    IERC20 public rewardsExtraToken;
    //Address where to send remaining tokens after contract closes
    address rewardsExtraOwner;
    //Rewards for period
    uint256 public rewardsPerPeriodCap;
    //Rewards Extra for period
    uint256 public rewardsExtraPerPeriodCap;
    //Staking Period in seconds
    uint256 public periodTime;
    //Total Periods
    uint256 public totalPeriods;
    //Grace Periods Time (time window after contract is Ended when users have to claim their Reward Tokens)
    //after this period ends, no reward withdrawal is possible and contact owner can withdraw unclamed Reward Tokens
    uint256 public gracePeriodTime;
    //Address where fees will be sent if fee isn't 0
    address public feeBeneficiary;
    //Fee in PPM (Parts Per Million), can be 0
    uint256 public fee;
    //Hold in periods for rewards
    uint256 public holdRewardsPeriods;
    
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardExtraPaid(address indexed user, uint256 rewardExtra);
    event WithdrawnERC20(address indexed user, address token, uint256 amount);
    

    /** @dev Updates Period before executing function */
    modifier updatePeriod() {
        _updatePeriod();
        _;
    }
    
    /** @dev Make sure setup is finished */
    modifier onlyAfterSetup() {
        require(status != Status.Setup, "Setup is not finished");
        _;
    }

    /** @dev Make sure setup is finished */
    modifier onlyAfterStart() {
        require(startTime != 0, "Staking is not started");
        _;
    }

    /**
     * @dev Contract constructor
     * @param _lpToken Contract address of LP Token
     * @param _rewardsToken Contract address of Rewards Token
     * @param _rewardsPerPeriodCap Amount of tokens to be distributed each period
     * @param _periodDays Period time in days
     * @param _totalPeriods Total periods contract will be running
     * @param _gracePeriodDays Grace period in days 
     * @param _holdDays Time in days LP Tokens will be on hold for user after each stake
     * @param _feeBeneficiary Address where fees will be sent
     * @param _fee Fee in ppm
     * @param _holdRewardsPeriods hold for rewards in periods
     */
    constructor(
        address _lpToken,
        address _rewardsToken,
        uint256 _rewardsPerPeriodCap,
        uint256 _periodDays, 
        uint256 _totalPeriods,
        uint256 _gracePeriodDays,
        uint256 _holdDays,
        address _feeBeneficiary,
        uint256 _fee,
        uint256 _holdRewardsPeriods
    )
        public
        LPTokenWrapper(_lpToken, _holdDays)
    {
        require(_lpToken.isContract(), "LP Token address must be a contract");
        require(_rewardsToken.isContract(), "Rewards Token address must be a contract");
        rewardsToken = IERC20(_rewardsToken);
        rewardsPerPeriodCap = _rewardsPerPeriodCap;
        periodTime = _periodDays.mul(1 days);
        totalPeriods = _totalPeriods;
        gracePeriodTime = _gracePeriodDays.mul(1 days);
        feeBeneficiary = _feeBeneficiary;
        fee = _fee;
        holdRewardsPeriods = _holdRewardsPeriods;
    }

    /***************************************
                    ADMIN
    ****************************************/

    /**
     * @dev Adds Rewards Extra token to contract, can be done only during setup
     * @param _rewardsExtraToken Contract address of Extra Rewards Token
     * @param _rewardsExtraPerPeriodCap Amount of tokens to be distributed each period
     * @param _rewardsExtraOwner address where to send remaining tokens after contract closes
     */    
    function adminAddRewardsExtraToken(
        address _rewardsExtraToken,
        uint256 _rewardsExtraPerPeriodCap,
        address _rewardsExtraOwner
    ) 
        external 
        onlyOwner
    {
        require(status == Status.Setup, "Already started");
        require(_rewardsExtraToken.isContract(), "Rewards Token address must be a contract");
        rewardsExtraToken = IERC20(_rewardsExtraToken);
        rewardsExtraPerPeriodCap = _rewardsExtraPerPeriodCap;
        rewardsExtraOwner = _rewardsExtraOwner;
    }

    /**
     * @dev Updates contract setup and mark contract status as Running if all requirements are met
     * @param _now Start contract immediatly if true
     */    
    function adminStart(bool _now) 
        external 
        onlyOwner
    {
        require(status == Status.Setup, "Already started");
        require(
            rewardsToken.balanceOf(address(this)) >= rewardsPerPeriodCap.mul(totalPeriods),
            "Not enough reward tokens to start"
        );
        if(address(rewardsExtraToken) != address(0)){
            require(
                rewardsExtraToken.balanceOf(address(this)) >= rewardsExtraPerPeriodCap.mul(totalPeriods),
                "Not enough extra reward tokens to start"
            );
        }
        status = Status.Running;
        if(_now) _startNow();
    }
    
    /**
     * @dev Option to start contract even there is no deposits yet
     */
    function adminStartNow()
        external
        onlyOwner
        onlyAfterSetup
    {
        require(startTime == 0 && status == Status.Running, "Already started");
        _startNow();
        
    }
    
    /**
     * @dev Option to end contract 
     */
    function adminEnd()
        external
        onlyOwner
        onlyAfterSetup
    {
        require(block.timestamp >= endTime && endTime != 0, "Cannot End");
        _updatePeriod();
    }
    
    /**
     * @dev Close contract after End and Grace period and withdraw unclamed rewards tokens
     */
     function adminClose()
        external
        onlyOwner
        onlyAfterSetup
    {
        require(block.timestamp >= closeTime && closeTime != 0, "Cannot Close");
        uint256 _rewardsBalance = rewardsToken.balanceOf(address(this));
        if(_rewardsBalance > 0) rewardsToken.safeTransfer(msg.sender, _rewardsBalance);
        if(address(rewardsExtraToken) != address(0)){
            _rewardsBalance = rewardsExtraToken.balanceOf(address(this));
            if(_rewardsBalance > 0) rewardsExtraToken.safeTransfer(rewardsExtraOwner, _rewardsBalance);
        }
    }
    
    /**
     * @dev Withdraw other than LP or Rewards tokens 
     * @param _tokenAddress address of the token contract to withdraw
     */
     function adminWithdrawERC20(address _tokenAddress)
        external
        onlyOwner
    {
        require(
            _tokenAddress != address(rewardsToken) 
            && _tokenAddress != address(rewardsExtraToken) 
            && _tokenAddress != address(lpToken), 
            "Cannot withdraw Reward or LP Tokens"
        );
        IERC20 _token = IERC20(_tokenAddress);
        uint256 _balance = _token.balanceOf(address(this));
        require(_balance != 0, "Not enough balance");
        uint256 _fee = _balance.mul(fee).div(1e6);
        if(_fee != 0){
            _token.safeTransfer(feeBeneficiary, _fee);
            emit WithdrawnERC20(feeBeneficiary, _tokenAddress, _fee);
        }
        _token.safeTransfer(msg.sender, _balance.sub(_fee));
        emit WithdrawnERC20(msg.sender, _tokenAddress, _balance.sub(_fee));
    }
    
    /***************************************
                    PRIVATE
    ****************************************/
    
    /**
     * @dev Starts the contract
     */
    function _startNow()
        private
    {
        startTime = block.timestamp;
        endTime = startTime.add(periodTime.mul(totalPeriods));  
        closeTime = endTime.add(gracePeriodTime);
    }

    /**
     * @dev Updates last period to current and set status to Ended if needed
     */
    function _updatePeriod()
        private
    {
        uint256 _currentPeriod = currentPeriod();
        if(_currentPeriod != period){
            period = _currentPeriod;
            if(_currentPeriod == totalPeriods){
                status = Status.Ended;
                //release hold of LP tokens
                holdTime = 0;
                //release hold of rewards
                holdRewardsPeriods = 0;
            }
        }
    }

    /**
     * @dev Calculates rewards share, balance for the user and history total supply
     * since last period claimed rewards to period provided
     * @param _address address of the user
     * @param _period last period to include
     */
    function _calculateRewardShare(address _address, uint256 _period) 
        private
        view
        returns (uint256 rewardShare_, uint256 periodBalance_, uint256 periodTotalSupply_)
    {
        UserData storage _user = _getUserData(_address);
        if(_period > _user.period){
            uint256 _savedTotalSupply;
            uint256 _savedBalance;
            for(uint256 i = _user.period; i < _period; i++){
                if(historyTotalSupply[i].isSet){
                    periodTotalSupply_ = historyTotalSupply[i].value;
                    _savedTotalSupply = periodTotalSupply_;
                }else{
                    periodTotalSupply_ = _savedTotalSupply;
                } 
                if(_user.historyBalance[i].isSet){
                    periodBalance_ = _user.historyBalance[i].value;
                    _savedBalance = periodBalance_;
                }else{
                    periodBalance_ = _savedBalance;
                }        
                if(periodTotalSupply_ != 0){
                    rewardShare_ = rewardShare_.add(
                        periodBalance_.mul(
                            CALC_PRECISION
                        ).div(
                            periodTotalSupply_
                        )
                    );
                }
            }
            if(historyTotalSupply[_period].isSet)
                    periodTotalSupply_ = historyTotalSupply[_period].value;
            if(_user.historyBalance[_period].isSet)
                    periodBalance_ = _user.historyBalance[_period].value;
        }
    }
    
    /**
     * @dev Calculates rewards since last period claimed rewards to period provided
     * @param _address address of the user
     * @param _period last period to include
     * @param _rewardsPerPeriodCap rewards per period cap
     */
    function _calculateReward(address _address, uint256 _period, uint256 _rewardsPerPeriodCap) 
        private
        view
        returns (uint256 reward_)
    {
        if(block.timestamp >= closeTime) return 0;
        (reward_, , ) = _calculateRewardShare(_address, _period);
        reward_ = _rewardsPerPeriodCap.mul(reward_).div(CALC_PRECISION);
    } 

    /***************************************
                    ACTIONS
    ****************************************/
    
    /**
     * @dev Stakes an amount for the sender, assumes sender approved allowace at LP Token contract _amount for this contract address
     * @param _amount of LP Tokens
     */
    function stake(uint256 _amount)
        external
        onlyAfterSetup
        updatePeriod
    {
        require(_amount > 0, "Cannot stake 0");
        require(status != Status.Ended, "Contract is Ended");
        if(startTime == 0) _startNow();
        _stake(_amount, period);
        emit Staked(msg.sender, _amount);
    }

    /**
     * @dev Withdraws given LP Token stake amount from the pool
     * @param _amount LP Tokens to withdraw
     */
    function withdraw(uint256 _amount)
        public
        onlyAfterStart
        updatePeriod
    {
        require(_amount > 0, "Cannot withdraw 0");
        _withdraw(_amount, period);
        emit Withdrawn(msg.sender, _amount);
    }
    
    /**
     * @dev Claims outstanding rewards for the sender.
     * First updates outstanding reward allocation and then transfers.
     */
    function claimReward()
        public
        nonReentrant
        onlyAfterStart
        updatePeriod
        returns (uint256 reward_, uint256 rewardExtra_)
    {
        require(block.timestamp < closeTime, "Contract is Closed");
        if(period > holdRewardsPeriods){
            uint256 _period = period.sub(holdRewardsPeriods);
            uint256 _rewardShare;
            uint256 _periodBalance;
            uint256 _periodTotalSupply;
            (_rewardShare, _periodBalance, _periodTotalSupply) = _calculateRewardShare(
                msg.sender, 
                _period
            );
            if (_rewardShare > 0) {            
                _updateUser(msg.sender, _period, _periodBalance);
                _updateHistoryTotalSupply(_period, _periodTotalSupply);
                reward_ = rewardsPerPeriodCap.mul(_rewardShare).div(CALC_PRECISION);
                rewardsToken.safeTransfer(msg.sender, reward_);
                emit RewardPaid(msg.sender, reward_);
                if(address(rewardsExtraToken) != address(0)){
                    rewardExtra_ = rewardsExtraPerPeriodCap.mul(_rewardShare).div(CALC_PRECISION);
                    rewardsExtraToken.safeTransfer(msg.sender, rewardExtra_);
                    emit RewardExtraPaid(msg.sender, rewardExtra_);
                }
            }
        }
    }    
    
    /**
     * @dev Withdraws LP Tokens stake from pool and claims any rewards
     */
    function exit() 
        external
    {
        uint256 _amount = balanceOf(msg.sender);
        if(_amount !=0) withdraw(_amount);
        claimReward();
    }
    
    /***************************************
                    GETTERS
    ****************************************/

    /**
     * @dev Calculates current period, if contract is ended returns currentPeriod + 1 (totalPeriods)
     */
    function currentPeriod() 
        public 
        view 
        returns (uint256 currentPeriod_)
    {
        if(startTime != 0 && endTime != 0)
        {
            if(block.timestamp >= endTime){
                currentPeriod_ = totalPeriods;
            }else{
                currentPeriod_ = block.timestamp.sub(startTime).div(periodTime);
            }
        }
    }

    /**
     * @dev Calculates rewards for the user since last period claimed rewards 
     * available for withdraw (taking into account hold periods for rewards)
     * @param _address address of the user
     */
    function calculateReward(address _address) 
        external
        view
        returns (uint256 reward_)
    {
        uint256 _period = currentPeriod();
        if(_period == totalPeriods)
            return calculateRewardTotal(_address);
        if(_period > holdRewardsPeriods)
            reward_ = _calculateReward(_address, _period.sub(holdRewardsPeriods), rewardsPerPeriodCap);
    }

    /**
     * @dev Calculates extra rewards for the user since last period claimed rewards 
     * available for withdraw (taking into account hold periods for rewards)
     * @param _address address of the user
     */
    function calculateRewardExtra(address _address) 
        external
        view
        returns (uint256 rewardExtra_)
    {
        if(address(rewardsExtraToken) != address(0)){
            uint256 _period = currentPeriod();
            if(_period == totalPeriods)
                return calculateRewardExtraTotal(_address);
            if(_period > holdRewardsPeriods)
                rewardExtra_ = _calculateReward(_address, 
                    _period.sub(holdRewardsPeriods), 
                    rewardsExtraPerPeriodCap
                );
        }  
    }

    /**
     * @dev Calculates total rewards (including those on hold if any) for the user till current period 
     * @param _address address of the user
     */
    function calculateRewardTotal(address _address) 
        public
        view
        returns (uint256)
    {
        return _calculateReward(_address, currentPeriod(), rewardsPerPeriodCap);
    }

    /**
     * @dev Calculates total rewards extra (including those on hold if any) for the user till current period 
     * @param _address address of the user
     */
    function calculateRewardExtraTotal(address _address) 
        public
        view
        returns (uint256)
    {
        if(address(rewardsExtraToken) != address(0))
            return _calculateReward(_address, currentPeriod(), rewardsExtraPerPeriodCap);
        
    }

    /**
     * @dev Returns estimated current period reward for the user based on current total supply and his balance
     * @param _address address of the user
     */
    function estimateReward(address _address) 
        external
        view
        returns (uint256)
    {
        if(totalSupply == 0 || block.timestamp >= endTime) return 0;
        return rewardsPerPeriodCap.mul(
            balanceOf(_address)
        ).mul(
            CALC_PRECISION
        ).div(
            totalSupply
        ).div(
            CALC_PRECISION
        );
    }

    /**
     * @dev Returns estimated current period reward extra for the user based on current total supply and his balance
     * @param _address address of the user
     */
    function estimateRewardExtra(address _address) 
        external
        view
        returns (uint256)
    {
        if(address(rewardsExtraToken) != address(0)){
            if(totalSupply == 0 || block.timestamp >= endTime) return 0;
            return rewardsExtraPerPeriodCap.mul(
                balanceOf(_address)
            ).mul(
                CALC_PRECISION
            ).div(
                totalSupply
            ).div(
                CALC_PRECISION
            );
        }
    }

    /**
     * @dev Returns Total reward cap for all periods
     */
    function rewardsTotalCap()
        external
        view
        returns (uint256)
    {
        return rewardsPerPeriodCap.mul(totalPeriods);
    }

    /**
     * @dev Returns Total reward extra cap for all periods
     */
    function rewardsExtraTotalCap()
        external
        view
        returns (uint256)
    {
        return rewardsExtraPerPeriodCap.mul(totalPeriods);
    }

    /**
     * @dev Returns true if hold for withdraw is active for given user address
     * @param _address address of the user
     */
    function isOnHold(address _address)
        external
        view
        returns (bool _hold)
    {
        UserData storage _user = _getUserData(_address);
        if(_user.lastTime == 0 || block.timestamp >= endTime){
            _hold = false;
        }else{
            _hold = block.timestamp.sub(_user.lastTime) < holdTime;
        }
    }
}