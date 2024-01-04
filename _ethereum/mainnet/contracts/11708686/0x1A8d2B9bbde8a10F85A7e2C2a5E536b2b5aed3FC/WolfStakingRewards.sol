pragma solidity ^0.5.16;

/**                                  _  __
                                    | |/ _|
__      _____ _ __ _____      _____ | | |_
\ \ /\ / / _ \ '__/ _ \ \ /\ / / _ \| |  _|
 \ V  V /  __/ | |  __/\ V  V / (_) | | |  
  \_/\_/ \___|_|  \___| \_/\_/ \___/|_|_|  
 
 
+-------------------+-----------+-------------+--------------------+
| Staking Moon Name | Moon Date | WWC Reward  | WWC Reward per day |
+===================+===========+=============+====================+
| Wolf Moon         | 28-Jan    | 1386538.462 |        277307.6923 |
| Snow Moon         | 27-Feb    | 2773076.923 |        79230.76923 |
| Worm Moon         | 28-Mar    | 4159615.385 |        64993.99038 |
| Pink Moon         | 26-Apr    | 5546153.846 |        59636.06286 |
| Flower Moon       | 26-May    | 6932692.308 |        56363.35209 |
| Strawberry Moon   | 24-Jun    | 8319230.769 |        54731.78138 |
| Buck Moon         | 23-Jul    | 9705769.231 |        53623.03442 |
| Sturgeon Moon     | 22-Aug    | 11092307.69 |        52570.17864 |
| Corn Moon         | 20-Sep    | 12478846.15 |        51995.19231 |
| Harvest Moon      | 20-Oct    | 13865384.62 |        51353.27635 |
| Beaver Moon       | 19-Nov    | 15251923.08 |        50839.74359 |
| Cold Moon         | 18-Dec    | 16638461.54 |        50572.83142 |
+-------------------+-----------+-------------+--------------------+


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
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

// Inheritancea
interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable(uint256 pool) external view returns (uint256);

    function rewardPerToken(uint256 pool) external view returns (uint256);

    function earned(address account, uint256 pool) external view returns (uint256);

    function getRewardForDuration(uint256 pool) external view returns (uint256);

    function totalSupplyPerPool(uint256 pool) external view returns (uint256);

    function balanceOfPerPool(address account, uint256 pool) external view returns (uint256);

    // Mutative

    function stake(uint256 amount, uint256 pool) external;

    function withdraw(uint256 amount, uint256 pool) external;

    function getReward(uint256 pool) external;

    function exit(uint256 pool) external;
}

contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward, uint256 pool) internal;
    
    function updateNotifyRewardAmount(uint256[] calldata reward) external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}

contract WolfStakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256[] public rewardsDuration = [1611861360,1614413820,1616957280,1619407860,1622027640,1624560000,1627007820,1629633720,1632182100,1634741820,1637312280,1639802160];
    address public owner;
    
    uint public genesisEventEnd = 1639802160;

    mapping(address => mapping(uint256 => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(uint256 => uint256)) public rewards;
    mapping(uint256 => uint256) public rewardRate;
    mapping(uint256 => uint256) public periodFinish;
    mapping(uint256 => uint256) public lastUpdateTime;
    mapping(uint256 => uint256) public rewardPerTokenStored;
    mapping(uint256 => uint256) public _totalSupplyPerPool;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(uint256 => uint256)) private _balancesPerPool;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        owner = msg.sender;
    }

    /* ========== VIEWS ========== */
    
    function totalSupplyPerPool(uint256 pool) external view returns (uint256) {
        return _totalSupplyPerPool[pool];
    }

    function balanceOfPerPool(address account, uint256 pool) external view returns (uint256) {
        return _balancesPerPool[account][pool];
    }

    function lastTimeRewardApplicable(uint256 pool) public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish[pool]);
    }

    function rewardPerToken(uint256 pool) public view returns (uint256) {
        if (_totalSupplyPerPool[pool] == 0) {
            return rewardPerTokenStored[pool];
        }
        return
            rewardPerTokenStored[pool].add(
                lastTimeRewardApplicable(pool).sub(lastUpdateTime[pool]).mul(rewardRate[pool]).mul(1e18).div(_totalSupplyPerPool[pool])
            );
    }

    function earned(address account, uint256 pool) public view returns (uint256) {
            return _balancesPerPool[account][pool].mul(rewardPerToken(pool).sub(userRewardPerTokenPaid[account][pool])).div(1e18).add(rewards[account][pool]);
    }

    function getRewardForDuration(uint256 pool) external view returns (uint256) {
        return rewardRate[pool].mul(rewardsDuration[pool]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount, uint pool) external nonReentrant updateReward(msg.sender, pool) {
        require(amount > 0, "Cannot stake 0");
        _totalSupplyPerPool[pool] = _totalSupplyPerPool[pool].add(amount);
        _balancesPerPool[msg.sender][pool] = _balancesPerPool[msg.sender][pool].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount, pool);
    }

    function withdraw(uint256 amount, uint pool) public nonReentrant updateReward(msg.sender, pool) {
        require(amount > 0, "Cannot withdraw 0");
        require(now > rewardsDuration[pool], "Pool duration is not over yet!");
        _totalSupplyPerPool[pool] = _totalSupplyPerPool[pool].sub(amount);
        _balancesPerPool[msg.sender][pool] = _balancesPerPool[msg.sender][pool].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, pool);
    }

    function getReward(uint pool) public nonReentrant updateReward(msg.sender, pool) {
        uint256 reward = rewards[msg.sender][pool];
        if (reward > 0) {
            rewards[msg.sender][pool] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward, pool);
        }
    }

    function exit(uint256 pool) external {
        require(now > rewardsDuration[pool], "Pool duration is not over yet!");
        withdraw(_balancesPerPool[msg.sender][pool], pool);
        getReward(pool);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    
    function updateNotifyRewardAmount(uint256[] calldata reward) external onlyRewardsDistribution onlyOwner {
        require(reward.length > 0, "Reward amount should be for all pool");
        for (uint256 pool = 0; pool < reward.length; pool++) {
            notifyRewardAmount(reward[pool], pool);
        }
    }

    function notifyRewardAmount(uint256 reward, uint256 pool) internal onlyRewardsDistribution updateReward(address(0), pool) {
        if (block.timestamp >= periodFinish[pool]) {
            rewardRate[pool] = reward.div(rewardsDuration[pool]);
        } else {
            uint256 remaining = periodFinish[pool].sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate[pool]);
            rewardRate[pool] = reward.add(leftover).div(rewardsDuration[pool]);
        }
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate[pool] <= balance.div(rewardsDuration[pool]), "Provided reward too high");
        lastUpdateTime[pool] = block.timestamp;
        periodFinish[pool] = block.timestamp.add(rewardsDuration[pool]);
        emit RewardAdded(reward, pool);
    }
    
    function withdrawRemainingBalance(uint256 amount, uint pool) external onlyOwner updateReward(address(0), pool){
        require(amount > 0, "Cannot withdraw 0");
        require(now > genesisEventEnd, "Genesis Event is Not Over!");
        rewardsToken.safeTransfer(owner, amount);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account, uint256 pool) {
        rewardPerTokenStored[pool] = rewardPerToken(pool);
        lastUpdateTime[pool] = lastTimeRewardApplicable(pool);
        if (account != address(0)) {
            rewards[account][pool] = earned(account, pool);
            userRewardPerTokenPaid[account][pool] = rewardPerTokenStored[pool];
        }
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == owner, "Caller is not an admin contract");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint256 pool);
    event Staked(address indexed user, uint256 amount, uint256 pool);
    event Withdrawn(address indexed user, uint256 amount, uint256 pool);
    event RewardPaid(address indexed user, uint256 reward, uint256 pool);
}