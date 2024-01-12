// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./StakingRewardsInterface.sol";

contract StakingRewards is
    Ownable,
    Pausable,
    ReentrancyGuard,
    StakingRewardsInterface
{
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice The staking token address
    IERC20 public stakingToken;

    /// @notice The list of rewards tokens
    address[] public rewardsTokens;

    /// @notice The reward tokens mapping
    mapping(address => bool) public rewardsTokensMap;

    /// @notice The period finish timestamp of every reward token
    mapping(address => uint256) public periodFinish;

    /// @notice The reward rate of every reward token
    mapping(address => uint256) public rewardRate;

    /// @notice The reward duration of every reward token
    mapping(address => uint256) public rewardsDuration;

    /// @notice The last updated timestamp of every reward token
    mapping(address => uint256) public lastUpdateTime;

    /// @notice The reward per token of every reward token
    mapping(address => uint256) public rewardPerTokenStored;

    /// @notice The reward per token paid to users of every reward token
    mapping(address => mapping(address => uint256)) public rewardPerTokenPaid;

    /// @notice The unclaimed rewards to users of every reward token
    mapping(address => mapping(address => uint256)) public rewards;

    /// @notice The helper contract that could stake, withdraw and claim rewards for users
    address public helperContract;

    /// @notice The total amount of the staking token staked in the contract
    uint256 private _totalSupply;

    /// @notice The user balance of the staking token staked in the contract
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakingToken, address _helperContract) {
        stakingToken = IERC20(_stakingToken);
        helperContract = _helperContract;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Return the total amount of the staking token staked in the contract.
     * @return The total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Return user balance of the staking token staked in the contract.
     * @return The user balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Return the last time reward is applicable.
     * @param _rewardsToken The reward token address
     * @return The last applicable timestamp
     */
    function lastTimeRewardApplicable(address _rewardsToken)
        public
        view
        returns (uint256)
    {
        return
            getBlockTimestamp() < periodFinish[_rewardsToken]
                ? getBlockTimestamp()
                : periodFinish[_rewardsToken];
    }

    /**
     * @notice Return the reward token amount per staking token.
     * @param _rewardsToken The reward token address
     * @return The reward token amount
     */
    function rewardPerToken(address _rewardsToken)
        public
        view
        returns (uint256)
    {
        // Return 0 if the rewards token is not supported.
        if (!rewardsTokensMap[_rewardsToken]) {
            return 0;
        }

        if (_totalSupply == 0) {
            return rewardPerTokenStored[_rewardsToken];
        }

        // rewardPerTokenStored + [(lastTimeRewardApplicable - lastUpdateTime) * rewardRate / _totalSupply]
        return
            rewardPerTokenStored[_rewardsToken] +
            (((lastTimeRewardApplicable(_rewardsToken) -
                lastUpdateTime[_rewardsToken]) *
                rewardRate[_rewardsToken] *
                1e18) / _totalSupply);
    }

    /**
     * @notice Return the reward token amount a user earned.
     * @param _rewardsToken The reward token address
     * @param account The user address
     * @return The reward token amount
     */
    function earned(address _rewardsToken, address account)
        public
        view
        returns (uint256)
    {
        // Return 0 if the rewards token is not supported.
        if (!rewardsTokensMap[_rewardsToken]) {
            return 0;
        }

        // rewards + (rewardPerToken - rewardPerTokenPaid) * _balances
        return
            (_balances[account] *
                (rewardPerToken(_rewardsToken) -
                    rewardPerTokenPaid[_rewardsToken][account])) /
            1e18 +
            rewards[_rewardsToken][account];
    }

    /**
     * @notice Return the reward rate.
     * @param _rewardsToken The reward token address
     * @return The reward rate
     */
    function getRewardRate(address _rewardsToken)
        external
        view
        returns (uint256)
    {
        return rewardRate[_rewardsToken];
    }

    /**
     * @notice Return the reward token for duration.
     * @param _rewardsToken The reward token address
     * @return The reward token amount
     */
    function getRewardForDuration(address _rewardsToken)
        external
        view
        returns (uint256)
    {
        return rewardRate[_rewardsToken] * rewardsDuration[_rewardsToken];
    }

    /**
     * @notice Return the amount of reward tokens.
     * @return The amount of reward tokens
     */
    function getRewardsTokenCount() external view returns (uint256) {
        return rewardsTokens.length;
    }

    /**
     * @notice Return all the reward tokens.
     * @return All the reward tokens
     */
    function getAllRewardsTokens() external view returns (address[] memory) {
        return rewardsTokens;
    }

    /**
     * @notice Return the staking token.
     * @return The staking token
     */
    function getStakingToken() external view returns (address) {
        return address(stakingToken);
    }

    /**
     * @notice Return the current block timestamp.
     * @return The current block timestamp
     */
    function getBlockTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Stake the staking token.
     * @param amount The amount of the staking token
     */
    function stake(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        _stakeFor(msg.sender, amount);
    }

    /**
     * @notice Stake the staking token for other user.
     * @param account The user address
     * @param amount The amount of the staking token
     */
    function stakeFor(address account, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(account)
    {
        require(msg.sender == helperContract, "unauthorized");
        require(account != address(0), "invalid account");
        _stakeFor(account, amount);
    }

    function _stakeFor(address account, uint256 amount) internal {
        require(amount > 0, "invalid amount");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(account, amount);
    }

    /**
     * @notice Withdraw the staked token.
     * @param amount The amount of the staking token
     */
    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        _withdrawFor(msg.sender, amount);
    }

    /**
     * @notice Withdraw the staked token for other user.
     * @dev This function can only be called by helper.
     * @param account The user address
     * @param amount The amount of the staking token
     */
    function withdrawFor(address account, uint256 amount)
        public
        nonReentrant
        updateReward(account)
    {
        require(msg.sender == helperContract, "unauthorized");
        require(account != address(0), "invalid account");
        _withdrawFor(account, amount);
    }

    function _withdrawFor(address account, uint256 amount) internal {
        require(amount > 0, "invalid amount");
        _totalSupply = _totalSupply - amount;
        _balances[account] = _balances[account] - amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(account, amount);
    }

    /**
     * @notice Claim rewards for the message sender.
     */
    function getReward() public nonReentrant updateReward(msg.sender) {
        _getRewardFor(msg.sender);
    }

    /**
     * @notice Claim rewards for an account.
     * @dev This function can only be called by helper.
     * @param account The user address
     */
    function getRewardFor(address account)
        public
        nonReentrant
        updateReward(account)
    {
        require(msg.sender == helperContract, "unauthorized");
        require(account != address(0), "invalid account");
        _getRewardFor(account);
    }

    function _getRewardFor(address account) internal {
        for (uint256 i = 0; i < rewardsTokens.length; i++) {
            uint256 reward = rewards[rewardsTokens[i]][account];
            uint256 remain = IERC20(rewardsTokens[i]).balanceOf(address(this));
            if (reward > 0 && reward <= remain) {
                rewards[rewardsTokens[i]][account] = 0;
                IERC20(rewardsTokens[i]).safeTransfer(account, reward);
                emit RewardPaid(account, rewardsTokens[i], reward);
            }
        }
    }

    /**
     * @notice Withdraw all the staked tokens and claim rewards.
     */
    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Set new reward amount.
     * @dev Make sure the admin deposits `reward` of reward tokens into the contract before calling this function.
     * @param rewardsToken The reward token address
     * @param reward The reward amount
     */
    function notifyRewardAmount(address rewardsToken, uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        require(rewardsTokensMap[rewardsToken], "reward token not supported");

        if (getBlockTimestamp() >= periodFinish[rewardsToken]) {
            rewardRate[rewardsToken] = reward / rewardsDuration[rewardsToken];
        } else {
            uint256 remaining = periodFinish[rewardsToken] -
                getBlockTimestamp();
            uint256 leftover = remaining * rewardRate[rewardsToken];
            rewardRate[rewardsToken] =
                (reward + leftover) /
                rewardsDuration[rewardsToken];
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(rewardsToken).balanceOf(address(this));
        require(
            rewardRate[rewardsToken] <= balance / rewardsDuration[rewardsToken],
            "reward rate too high"
        );

        lastUpdateTime[rewardsToken] = getBlockTimestamp();
        periodFinish[rewardsToken] =
            getBlockTimestamp() +
            rewardsDuration[rewardsToken];
        emit RewardAdded(rewardsToken, reward);
    }

    /**
     * @notice Seize the accidentally deposited tokens.
     * @dev Thes staking tokens cannot be seized.
     * @param tokenAddress The token address
     * @param tokenAmount The token amount
     */
    function recoverToken(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken),
            "cannot withdraw staking token"
        );
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Set the rewards duration.
     * @param rewardsToken The reward token address
     * @param duration The new duration
     */
    function setRewardsDuration(address rewardsToken, uint256 duration)
        external
        onlyOwner
    {
        require(rewardsTokensMap[rewardsToken], "reward token not supported");
        require(
            getBlockTimestamp() > periodFinish[rewardsToken],
            "previous rewards not complete"
        );
        _setRewardsDuration(rewardsToken, duration);
    }

    /**
     * @notice Support new rewards token.
     * @param rewardsToken The reward token address
     * @param duration The duration
     */
    function addRewardsToken(address rewardsToken, uint256 duration)
        external
        onlyOwner
    {
        require(
            address(stakingToken) != rewardsToken,
            "rewards token cannot be staking token"
        );
        require(
            !rewardsTokensMap[rewardsToken],
            "rewards token already supported"
        );

        rewardsTokens.push(rewardsToken);
        rewardsTokensMap[rewardsToken] = true;
        emit RewardsTokenAdded(rewardsToken);

        _setRewardsDuration(rewardsToken, duration);
    }

    /**
     * @notice Set the helper contract.
     * @param helper The helper contract address
     */
    function setHelperContract(address helper) external onlyOwner {
        helperContract = helper;
        emit HelperContractSet(helper);
    }

    /**
     * @notice Pause the staking.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the staking.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function _setRewardsDuration(address rewardsToken, uint256 duration)
        internal
    {
        rewardsDuration[rewardsToken] = duration;
        emit RewardsDurationUpdated(rewardsToken, duration);
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Update the reward information.
     * @param user The user address
     */
    modifier updateReward(address user) {
        for (uint256 i = 0; i < rewardsTokens.length; i++) {
            address token = rewardsTokens[i];
            rewardPerTokenStored[token] = rewardPerToken(token);
            lastUpdateTime[token] = lastTimeRewardApplicable(token);
            if (user != address(0)) {
                rewards[token][user] = earned(token, user);
                rewardPerTokenPaid[token][user] = rewardPerTokenStored[token];
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when new reward tokens are added
     */
    event RewardAdded(address rewardsToken, uint256 reward);

    /**
     * @notice Emitted when user staked
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @notice Emitted when user withdrew
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @notice Emitted when rewards are paied
     */
    event RewardPaid(
        address indexed user,
        address rewardsToken,
        uint256 reward
    );

    /**
     * @notice Emitted when a reward duration is updated
     */
    event RewardsDurationUpdated(address rewardsToken, uint256 newDuration);

    /**
     * @notice Emitted when a token is recovered by admin
     */
    event Recovered(address token, uint256 amount);

    /**
     * @notice Emitted when a reward token is added
     */
    event RewardsTokenAdded(address rewardsToken);

    /**
     * @notice Emitted when new helper contract is set
     */
    event HelperContractSet(address helper);
}
