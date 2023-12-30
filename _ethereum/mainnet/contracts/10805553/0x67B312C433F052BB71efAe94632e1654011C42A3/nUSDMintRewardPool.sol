pragma solidity 0.5.16;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

/*
 * @title  Pool
 * @notice Abstract pool to facilitate tracking of shares in a pool
 */
contract Pool {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _totalShares;
    mapping(address => uint256) private _shares;

    /**
     * @dev Pool constructor
     */
    constructor() internal {
    }

    /*** VIEW ***/

    /**
     * @dev Get the total number of shares in pool
     * @return uint256 total shares
     */
    function totalShares()
        public
        view
        returns (uint256)
    {
        return _totalShares;
    }

    /**
     * @dev Get the share of a given account
     * @param _account User for which to retrieve balance
     * @return uint256 shares
     */
    function sharesOf(address _account)
        public
        view
        returns (uint256)
    {
        return _shares[_account];
    }

    /*** INTERNAL ***/

    /**
     * @dev Add a given amount of shares to a given account
     * @param _account Account to increase shares for
     * @param _amount Units of shares
     */
    function _increaseShares(address _account, uint256 _amount)
        internal
    {
        _totalShares = _totalShares.add(_amount);
        _shares[_account] = _shares[_account].add(_amount);
    }

    /**
     * @dev Remove a given amount of shares from a given account
     * @param _account Account to decrease shares for
     * @param _amount Units of shares
     */
    function _decreaseShares(address _account, uint256 _amount)
        internal
    {
        _totalShares = _totalShares.sub(_amount);
        _shares[_account] = _shares[_account].sub(_amount);
    }
}

contract Context {
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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RewardDistributionRecipient is Ownable {
    address public rewardDistributor;

    constructor (address _rewardDistributor) internal {
        rewardDistributor = _rewardDistributor;
    }

    function notifyRewardAmount(uint256 _reward) external;

    modifier onlyRewardDistributor() {
        require(_msgSender() == rewardDistributor, "Caller is not reward distributor");
        _;
    }

    function setRewardDistributor(address _rewardDistributor)
        external
        onlyOwner
    {
        rewardDistributor = _rewardDistributor;
    }
}

/**
 * @title  RewardPool
 * @author Originally: Synthetix (forked from /Synthetixio/synthetix/contracts/StakingRewards.sol)
 *         Audit: https://github.com/sigp/public-audits/blob/master/synthetix/unipool/review.pdf
 * @notice Rewards share holders with RewardToken, on a pro-rata basis
 */
contract RewardPool is Pool, RewardDistributionRecipient {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public rewardToken;

    uint256 public DURATION;
    uint256 public periodFinish = 0;
    uint256 public rewardPerSecond = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerShareStored;
    mapping(address => uint256) public userRewardPerSharePaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);

    /**
     * @dev RewardPool constructor
     * @param _DURATION The duration of each reward period
     * @param _rewardToken The rewardToken
     */
    constructor (
        uint256 _DURATION,
        address _rewardToken
    )
        RewardDistributionRecipient(msg.sender)
        internal
    {
        DURATION = _DURATION;
        rewardToken = IERC20(_rewardToken);
    }

    /** @dev Updates the reward for a given address, before executing function */
    modifier updateReward(address _account) {
        // Setting of global vars
        uint256 newRewardPerShare = rewardPerShare();
        // If statement protects against loss in initialisation case
        if(newRewardPerShare > 0) {
            rewardPerShareStored = newRewardPerShare;
            lastUpdateTime = lastTimeRewardApplicable();
            // Setting of personal vars based on new globals
            if (_account != address(0)) {
                rewards[_account] = earned(_account);
                userRewardPerSharePaid[_account] = newRewardPerShare;
            }
        }
        _;
    }

    /*** PUBLIC FUNCTIONS ***/

    /**
     * @dev Claim outstanding rewards for sender
     * @return uint256 amount claimed
     */
    function claim()
        public
        updateReward(msg.sender)
    {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /*** VIEW ***/

    /**
     * @dev Get current block timestamp. For easy mocking in test
     */
    function getCurrentTimestamp()
        public
        view
        returns (uint256)
    {
        return block.timestamp;
    }

    /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable()
        public
        view
        returns (uint256)
    {
        return Math.min(getCurrentTimestamp(), periodFinish);
    }

    /**
     * @dev Calculate rewardsPerShare
     * @return uint256 rewardsPerShare
     */
    function rewardPerShare()
        public
        view
        returns (uint256)
    {
        if (totalShares() == 0) {
            return rewardPerShareStored;
        }
        return rewardPerShareStored.add(
          lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardPerSecond)
          .mul(1e18)
          .div(totalShares())
          );
    }

    /**
     * @dev Calculates the amount of rewards earned for a given account
     * @param _account User for which calculate earned rewards for
     * @return uint256 Earned rewards
     */
    function earned(address _account)
        public
        view
        returns (uint256)
    {
        return sharesOf(_account)
               .mul(rewardPerShare().sub(userRewardPerSharePaid[_account]))
               .div(1e18)
               .add(rewards[_account]);
    }

    /*** ADMIN ***/

    /**
     * @dev Notifies the contract that new rewards have been added.
     * Calculates an updated rewardPerSecond based on the rewards in period.
     * @param _reward Units of RewardToken that have been added to the pool
     */
    function notifyRewardAmount(uint256 _reward)
        external
        onlyRewardDistributor
        updateReward(address(0))
    {
        uint256 currentTime = getCurrentTimestamp();
        // If previous period over, reset rewardPerSecond
        if (currentTime >= periodFinish) {
            rewardPerSecond = _reward.div(DURATION);
        }
        // If additional reward to existing period, calc sum
        else {
            uint256 remaining = periodFinish.sub(currentTime);
            uint256 leftover = remaining.mul(rewardPerSecond);
            rewardPerSecond = _reward.add(leftover).div(DURATION);
        }

        lastUpdateTime = currentTime;
        periodFinish = currentTime.add(DURATION);

        emit RewardAdded(_reward);
    }

    /*** INTERNAL ***/

    /**
     * @dev Add a given amount of shares to a given account
     * @param _account Account to increase shares for
     * @param _amount Units of shares
     */
    function _mintShares(address _account, uint256 _amount)
        internal
        updateReward(_account)
    {
        require(_amount > 0, "REWARD_POOL: cannot mint 0 shares");
        _increaseShares(_account, _amount);
    }

    /**
     * @dev Remove a given amount of shares from a given account
     * @param _account Account to decrease shares for
     * @param _amount Units of shares
     */
    function _burnShares(address _account, uint256 _amount)
        internal
        updateReward(_account)
    {
        require(_amount > 0, "REWARD_POOL: cannot burn 0 shares");
        _decreaseShares(_account, _amount);
    }
}

/*
 * @title  ManagedRewardPool
 * @notice RewardPool with shares controlled by manager
 */
contract ManagedRewardPool is RewardPool {

    mapping(address => bool) public managers;

    event Promoted(address indexed manager);
    event Demoted(address indexed manager);

    constructor(
        uint256 _DURATION,
        address _rewardToken
    )
        RewardPool (
            _DURATION,
            _rewardToken
        )
        public
    {
    }

    modifier onlyManager() {
        require(isManager(msg.sender), "MANAGED_REWARD_POOL: caller is not a manager");
        _;
    }

    /*** PUBLIC ***/

    function mintShares(address _account, uint256 _amount)
        external
        onlyManager
    {
        _mintShares(_account, _amount);
    }

    function burnShares(address _account, uint256 _amount)
        external
        onlyManager
    {
        _burnShares(_account, _amount);
    }

    function isManager(address _account)
        public
        view
        returns (bool)
    {
        return managers[_account];
    }

    /*** ADMIN ***/

    function promote(address _address)
        external
        onlyOwner
    {
        managers[_address] = true;

        emit Promoted(_address);
    }

    function demote(address _address)
        external
        onlyOwner
    {
        managers[_address] = false;

        emit Demoted(_address);
    }
}

/**
 * @title nUSDMintRewardPool
 * @dev Reward pool to issue BRET for minting nUSD
 */
contract nUSDMintRewardPool is ManagedRewardPool {
    constructor (address _bretToken)
        ManagedRewardPool (
            604800, // 7 days
            _bretToken
        )
        public
    {
    }
}