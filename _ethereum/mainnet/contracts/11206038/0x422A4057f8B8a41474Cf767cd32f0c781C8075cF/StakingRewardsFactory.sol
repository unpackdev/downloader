pragma solidity 0.5.16;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}


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


/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}



interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable(address rewardToken) external view returns (uint256);

    function rewardPerToken(address rewardToken) external view returns (uint256);

    function earned(address account, address rewardToken) external view returns (uint256);

    function getRewardForDuration(address rewardToken) external view returns (uint256);

    function totalStakesAmount() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20Detailed {
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

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

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
    function decimals() external view returns (uint8);
}


/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
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
}




/**
 * @title SafeERC20Detailed
 * @dev Wrappers around SafeERC20Detailed operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20Detailed for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Detailed {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20Detailed token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Detailed token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20Detailed token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Detailed token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Detailed token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20Detailed token, bytes memory data) private {
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
// SPDX-License-Identifier: MIT


contract RewardsDistributionRecipient {
    address public rewardsDistributor;

    function start() external;

    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "Caller is not RewardsDistribution contract");
        _;
    }
}// SPDX-License-Identifier: MIT








contract StakingRewards is
    IStakingRewards,
    RewardsDistributionRecipient,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20Detailed for IERC20Detailed;

    /* ========== STATE VARIABLES ========== */

    // staking
    IERC20Detailed public stakingToken;
    uint256 private _totalStakesAmount;
    mapping(address => uint256) private _balances;

    // reward
    struct RewardInfo {
        uint256 rewardRate;
        uint256 latestRewardPerTokenSaved;
        uint256 periodFinish;
        uint256 lastUpdateTime;
        uint256 rewardDuration;

        // user rewards
        mapping(address => uint256) userRewardPerTokenRecorded;
        mapping(address => uint256) rewards;
    }

    mapping(address => RewardInfo) public rewardsTokensMap; // structure for fast access to token's data
    address[] public rewardsTokensArr; // structure to iterate over
    uint256[] public rewardsAmountsArr;

    /* ========== EVENTS ========== */

    event RewardAdded(address[] token, uint256[] reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 rewardAmount);
    event RewardExtended(
        address indexed rewardToken,
        uint256 rewardAmount,
        uint256 date,
        uint256 periodToExtend
    );

    /* ========== CONSTRUCTOR ========== */

    /** @dev Function called once on deployment time
    * @param _rewardsTokens The addresses of the tokens the rewards will be paid in
    * @param _rewardsAmounts The reward amounts for each reward token
    * @param _stakingToken The address of the token being staked
    * @param _rewardsDuration Rewards duration in seconds
     */
    constructor(
        address[] memory _rewardsTokens,
        uint256[] memory _rewardsAmounts,
        address _stakingToken,
        uint256 _rewardsDuration
    ) public {
        for (uint i = 0; i < _rewardsTokens.length; i++) {
            rewardsTokensMap[_rewardsTokens[i]] = RewardInfo(0, 0, 0, 0, _rewardsDuration);
        }
        rewardsTokensArr = _rewardsTokens;
        rewardsAmountsArr = _rewardsAmounts;
        stakingToken = IERC20Detailed(_stakingToken);

        rewardsDistributor = msg.sender;
    }

    /* ========== MODIFIERS ========== */

    /** @dev Modifier that re-calculates the rewards per user on user action.
     */
    modifier updateReward(address account) {
        for (uint i = 0; i < rewardsTokensArr.length; i++) {
            address token = rewardsTokensArr[i];
            RewardInfo storage ri = rewardsTokensMap[token];

            ri.latestRewardPerTokenSaved = rewardPerToken(token); // Calculate the reward until now
            ri.lastUpdateTime = lastTimeRewardApplicable(token); // Update the last update time to now (or end date) for future calculations

            if (account != address(0)) {
                ri.rewards[account] = earned(account, token);
                ri.userRewardPerTokenRecorded[account] = ri.latestRewardPerTokenSaved;
            }
        }
        _;
    }

    /* ========== FUNCTIONS ========== */

    /** @dev Return the length of Rewards tokens array.
     */
    function getRewardsTokensCount()
        external
        view
        returns (uint)
    {
        return rewardsTokensArr.length;
    }

    /** @dev Returns reward per token for a specific user and specific reward token.
     * @param rewardToken The reward token
     * @param rewardToken The address of user
     */
    function getUserRewardPerTokenRecorded(address rewardToken, address user)
        external
        view
        returns (uint256)
    {
        return rewardsTokensMap[rewardToken].userRewardPerTokenRecorded[user];
    }

    /** @dev Returns reward for a specific user and specific reward token.
     * @param rewardToken The reward token
     * @param rewardToken The address of user
     */
    function getUserReward(address rewardToken, address user)
        external
        view
        returns (uint256)
    {
        return rewardsTokensMap[rewardToken].rewards[user];
    }

    /** @dev Returns the total amount of stakes.
     */
    function totalStakesAmount() external view returns (uint256) {
        return _totalStakesAmount;
    }

    /** @dev Returns the balance of specific user.
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /** @dev Calculates the rewards for this distribution.
     * @param rewardToken The reward token for which calculations will be made for
     */
    function getRewardForDuration(address rewardToken) external view returns (uint256) {
        RewardInfo storage ri = rewardsTokensMap[rewardToken];
        return ri.rewardRate.mul(ri.rewardDuration);
    }

    /** @dev Checks if staking period has been started.
     */
    function hasPeriodStarted()
        external
        view
        returns (bool)
    {
        for (uint i = 0; i < rewardsTokensArr.length; i++) {
            if (rewardsTokensMap[rewardsTokensArr[i]].periodFinish != 0) {
                return true;
            }
        }

        return false;
    }

    /** @dev Providing LP tokens to stake, start calculating rewards for user.
     * @param amount The amount to be staked
     */
    function stake(uint256 amount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount != 0, "Cannot stake 0");
        _totalStakesAmount = _totalStakesAmount.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    /** @dev Withdrawing the stake and claiming the rewards for the user
     */
    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /** @dev Makes the needed calculations and starts the staking/rewarding.
     */
    function start()
        external
        onlyRewardsDistributor
        updateReward(address(0))
    {
        for (uint i = 0; i < rewardsTokensArr.length; i++) {
            address token = rewardsTokensArr[i];
            RewardInfo storage ri = rewardsTokensMap[token];

            ri.rewardRate = rewardsAmountsArr[i].div(ri.rewardDuration);
            // Ensure the provided reward amount is not more than the balance in the contract.
            // This keeps the reward rate in the right range, preventing overflows due to
            // very high values of rewardRate in the earned and rewardsPerToken functions;
            // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
            uint256 balance = IERC20Detailed(token).balanceOf(address(this));
            require(
                ri.rewardRate <= balance.div(ri.rewardDuration),
                "Provided reward too high"
            );

            ri.lastUpdateTime = block.timestamp;
            ri.periodFinish = block.timestamp.add(ri.rewardDuration);
        }

        emit RewardAdded(rewardsTokensArr, rewardsAmountsArr);
    }

    /** @dev Add's more rewards and updates the duration of the rewards distribution.
     * @param rewardToken The token in which the additional reward amount will be distributed. Must be already known token.
     * @param rewardAmount The additional reward amount
     */
    function addRewards(address rewardToken, uint256 rewardAmount)
        external
        updateReward(address(0))
        onlyRewardsDistributor
    {
        uint256 periodToExtend = getPeriodsToExtend(rewardToken, rewardAmount);
        IERC20Detailed(rewardToken).safeTransferFrom(msg.sender, address(this), rewardAmount);

        RewardInfo storage ri = rewardsTokensMap[rewardToken];
        ri.periodFinish = ri.periodFinish.add(periodToExtend);
        ri.rewardDuration = ri.rewardDuration.add(periodToExtend);

        emit RewardExtended(rewardToken, rewardAmount, block.timestamp, periodToExtend);
    }

    /** @dev Calculates the last time reward could be paid up until this moment for specific reward token.
     * @param rewardToken The reward token for which calculations will be made for
     */
    function lastTimeRewardApplicable(address rewardToken) public view returns (uint256) {
        return Math.min(block.timestamp, rewardsTokensMap[rewardToken].periodFinish);
    }

    /** @dev Calculates how many rewards tokens you should get per 1 staked token until last applicable time (in most cases it is now) for specific token
     * @param rewardToken The reward token for which calculations will be made for
     */
    function rewardPerToken(address rewardToken) public view returns (uint256) {
        RewardInfo storage ri = rewardsTokensMap[rewardToken];

        if (_totalStakesAmount == 0) {
            return ri.latestRewardPerTokenSaved;
        }

        uint256 timeSinceLastSave = lastTimeRewardApplicable(rewardToken).sub(
            ri.lastUpdateTime
        );

        uint256 rewardPerTokenSinceLastSave = timeSinceLastSave
            .mul(ri.rewardRate)
            .mul(10 ** uint256(IERC20Detailed(address(stakingToken)).decimals()))
            .div(_totalStakesAmount);

        return ri.latestRewardPerTokenSaved.add(rewardPerTokenSinceLastSave);
    }

    /** @dev Calculates how much rewards a user has earned.
     * @param account The user for whom calculations will be done
     * @param rewardToken The reward token for which calculations will be made for
     */
    function earned(address account, address rewardToken) public view returns (uint256) {
        RewardInfo storage ri = rewardsTokensMap[rewardToken];

        uint256 userRewardPerTokenSinceRecorded = rewardPerToken(rewardToken).sub(
            ri.userRewardPerTokenRecorded[account]
        );

        uint256 newReward = _balances[account]
            .mul(userRewardPerTokenSinceRecorded)
            .div(10 ** uint256(IERC20Detailed(address(stakingToken)).decimals()));

        return ri.rewards[account].add(newReward);
    }

    /** @dev Calculates the finish period extension based on the new reward amount added
     * @param rewardAmount The additional reward amount
     */
    function getPeriodsToExtend(address rewardToken, uint256 rewardAmount)
        public
        view
        returns (uint256 periodToExtend)
    {
        require(rewardAmount != 0, "Rewards should be greater than zero");

        RewardInfo storage ri = rewardsTokensMap[rewardToken];
        require(ri.rewardRate != 0, "Staking is not yet started");

        periodToExtend = rewardAmount.div(ri.rewardRate);
    }

    /** @dev Checks if staking period for every reward token has expired.
     * Returns false if atleast one reward token has not yet finished
     */
    function hasPeriodFinished()
        public
        view
        returns (bool)
    {
        for (uint i = 0; i < rewardsTokensArr.length; i++) {
            // on first token for which the period has not expired, returns false.
            if (block.timestamp < rewardsTokensMap[rewardsTokensArr[i]].periodFinish) {
                return false;
            }
        }

        return true;
    }

    /** @dev Withdrawing/removing the staked tokens back to the user's wallet
     * @param amount The amount to be withdrawn
     */
    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount != 0, "Cannot withdraw 0");
        _totalStakesAmount = _totalStakesAmount.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /** @dev Claiming earned rewards up to now
     */
    function getReward()
        public
        nonReentrant
        updateReward(msg.sender)
    {
        uint256 tokenArrLength = rewardsTokensArr.length;
        for (uint i = 0; i < tokenArrLength; i++) {
            address token = rewardsTokensArr[i];
            RewardInfo storage ri = rewardsTokensMap[token];

            uint256 reward = ri.rewards[msg.sender];
            if (reward != 0) {
                ri.rewards[msg.sender] = 0;
                IERC20Detailed(token).safeTransfer(msg.sender, reward);
                emit RewardPaid(msg.sender, token, reward);
            }
        }
    }
}
// SPDX-License-Identifier: MIT



contract StakingRewardsFactory is Ownable {
    using SafeERC20Detailed for IERC20Detailed;

    uint256 public stakingRewardsGenesis;

    /** @dev the staking tokens for which the rewards contract has been deployed
     */
    address[] public stakingTokens;

    /** @dev Mapping holding information about a particular Staking Rewards Contract Address by Staking Token
     */
    mapping(address => address) public stakingRewardsByStakingToken;

    /* ========== CONSTRUCTOR ========== */

    /** @dev Function called once on deployment time
     * @param _stakingRewardsGenesis Timestamp after which the staking can start
     */
    constructor(
        uint256 _stakingRewardsGenesis
    ) public {
        require(_stakingRewardsGenesis >= block.timestamp, 'StakingRewardsFactory::constructor: genesis too soon');

        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    /* ========== Permissioned FUNCTIONS ========== */

    /** @dev Deploy a staking reward contract for the staking token, and store the reward amount,the reward will be distributed to the staking reward contract no sooner than the genesis
     * @param _stakingToken The address of the token being staked
     * @param _rewardsTokens The addresses of the tokens the rewards will be paid in
     * @param _rewardsAmounts The reward amounts
     * @param _rewardsDuration Rewards duration in seconds
     */
    function deploy(
        address            _stakingToken,
        address[] calldata _rewardsTokens,
        uint256[] calldata _rewardsAmounts,
        uint256            _rewardsDuration
    ) external onlyOwner {
        require(stakingRewardsByStakingToken[_stakingToken] == address(0), 'StakingRewardsFactory::deploy: already deployed');
        require(_rewardsDuration != 0, 'StakingRewardsFactory::deploy:The Duration should be greater than zero');
        require(_rewardsTokens.length != 0, 'StakingRewardsFactory::deploy: RewardsTokens and RewardsAmounts arrays could not be empty');
        require(_rewardsTokens.length == _rewardsAmounts.length, 'StakingRewardsFactory::deploy: RewardsTokens and RewardsAmounts should have a matching sizes');

        for (uint256 i = 0; i < _rewardsTokens.length; i++) {
            require(_rewardsTokens[i] != address(0), 'StakingRewardsFactory::deploy: Reward token address could not be invalid');
            require(_rewardsAmounts[i] != 0, 'StakingRewardsFactory::deploy: Reward must be greater than zero');
        }

        stakingRewardsByStakingToken[_stakingToken] = address(new StakingRewards(_rewardsTokens, _rewardsAmounts, _stakingToken, _rewardsDuration));

        stakingTokens.push(_stakingToken);
    }

    /** @dev Function that will extend the rewards period, but not change the reward rate, for a given staking contract.
     * @param stakingToken The address of the token being staked
     * @param extendRewardToken The address of the token the rewards will be paid in
     * @param extendRewardAmount The additional reward amount
     */
    function extendRewardPeriod(
        address stakingToken,
        address extendRewardToken,
        uint256 extendRewardAmount
    )
        external
        onlyOwner
    {
        require(extendRewardAmount != 0, 'StakingRewardsFactory::extendRewardPeriod: Reward must be greater than zero');

        address sr = stakingRewardsByStakingToken[stakingToken]; // StakingRewards

        require(sr != address(0), 'StakingRewardsFactory::extendRewardPeriod: not deployed');
        require(hasStakingStarted(sr), 'StakingRewardsFactory::extendRewardPeriod: Staking has not started');

        (uint256 rate, , , ,) = StakingRewards(sr).rewardsTokensMap(extendRewardToken);

        require(rate != 0, 'StakingRewardsFactory::extendRewardPeriod: Token for extending reward is not known'); // its expected that valid token should have a valid rate

        IERC20Detailed(extendRewardToken).safeApprove(sr, extendRewardAmount);
        StakingRewards(sr).addRewards(extendRewardToken, extendRewardAmount);
    }

    /* ========== Permissionless FUNCTIONS ========== */

    /** @dev Calls startStakings for all staking tokens.
     */
    function startStakings() external {
        require(stakingTokens.length != 0, 'StakingRewardsFactory::startStakings: called before any deploys');

        for (uint256 i = 0; i < stakingTokens.length; i++) {
            startStaking(stakingTokens[i]);
        }
    }

    /** @dev Function to determine whether the staking and rewards distribution has stared for a given StakingRewards contract
     * @param stakingRewards The address of the staking rewards contract
     */
    function hasStakingStarted(address stakingRewards)
        public
        view
        returns (bool)
    {
        return StakingRewards(stakingRewards).hasPeriodStarted();
    }

    /** @dev Starts the staking and rewards distribution for a given staking token. This is a fallback in case the startStakings() costs too much gas to call for all contracts
     * @param stakingToken The address of the token being staked
     */
    function startStaking(address stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, 'StakingRewardsFactory::startStaking: not ready');

        address sr = stakingRewardsByStakingToken[stakingToken]; // StakingRewards

        StakingRewards srInstance = StakingRewards(sr);
        require(sr != address(0), 'StakingRewardsFactory::startStaking: not deployed');
        require(!hasStakingStarted(sr), 'StakingRewardsFactory::startStaking: Staking has started');

        uint256 rtsSize = srInstance.getRewardsTokensCount();
        for (uint256 i = 0; i < rtsSize; i++) {
            require(
                IERC20Detailed(srInstance.rewardsTokensArr(i))
                    .transfer(sr, srInstance.rewardsAmountsArr(i)),
                'StakingRewardsFactory::startStaking: transfer failed'
            );
        }

        srInstance.start();
    }
}