// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

interface IERC20Ownable {
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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;
}

contract StakingRewards is Ownable, ReentrancyGuard {
    /* ========== STATE VARIABLES ========== */
    IERC20Ownable public token;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _token) {
        token = IERC20Ownable(_token);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (rewardRate * (lastTimeRewardApplicable() - lastUpdateTime) * 1e18) / _totalSupply;
    }

    function earned(address account) public view returns (uint256) {
        return ((_balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(block.timestamp <= periodFinish, 'Staking period over');
        require(amount > 0, 'Cannot stake 0');
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        token.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, 'Cannot withdraw 0');
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) returns (uint256) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            token.transfer(msg.sender, reward);
        }
        return reward;
    }

    function exit() external {
        uint256 stakedAmount = _balances[msg.sender];
        // send deposited staking token back
        withdraw(stakedAmount);
        // send accrued rewards token
        uint256 rewardAmount = getReward();
        emit Exited(msg.sender, stakedAmount, rewardAmount);
    }

    function withdrawStuckTokens(address _token, address _to) external onlyOwner {
        require(_token != address(0), '_token address cannot be 0');
        uint256 _contractBalance = IERC20Ownable(_token).balanceOf(address(this));
        IERC20Ownable(_token).transfer(_to, _contractBalance);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardDetails(uint256 reward, uint256 _rewardsDuration) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / _rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / _rewardsDuration;
        }
        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = token.balanceOf(address(this));
        require(rewardRate <= balance / _rewardsDuration, 'Provided reward too high');
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + _rewardsDuration;
        rewardsDuration = _rewardsDuration;
        emit RewardDetailsAdded(reward, _rewardsDuration);
    }

    function transferTokenOwnership(address newOwner) external onlyOwner {
        token.transferOwnership(newOwner);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardDetailsAdded(uint256 reward, uint256 rewardsDuration);
    event Staked(address indexed user, uint256 amount);
    event Exited(address indexed user, uint256 stakedAmount, uint256 rewardAmount);
}
