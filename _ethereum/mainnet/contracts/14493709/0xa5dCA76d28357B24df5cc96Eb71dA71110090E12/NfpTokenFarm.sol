// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

/// @title NFP Staking Farm
/// @author NFP Swap
/// @notice Contract for reward program using NFP token
contract NfpTokenFarm is ReentrancyGuard, Ownable {
    using SafeMath for uint;
    using SafeMath for uint256;
    IERC20 private _stakingToken;

    uint private _endTime;
    uint256 private _rewardRate;
    uint256 private _lastUpdateTime;
    uint256 private _rewardPerTokenStored;

    mapping(address => uint256) private _userRewardPerTokenPaid;
    mapping(address => uint256) private _rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint) private _lastStaked;

    struct StakeInfo {
        uint256 amountStaked;
        uint256 earnedAmount;
        uint256 rewardRate;
        uint256 totalStaked;
        uint lastStaked;
    }

    constructor() {}

    /// @notice Fetch the stake information for a given address
    function userStakeInfo(address account)
        public
        view
        returns (StakeInfo memory)
    {
        return
            StakeInfo(
                _balances[account],
                earned(account),
                _rewardRate,
                _totalSupply,
                _lastStaked[account]
            );
    }

    /// @notice Setup farm with token and reward rate
    function setUpFarm(address stakingTokenAddress, uint256 startingRewardRate)
        public
        onlyOwner
    {
        _stakingToken = IERC20(stakingTokenAddress);
        _rewardRate = startingRewardRate;
    }

    /// @notice Returns the reward rate to calculate rewards
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return 0;
        }

        uint latestTime = _endTime > 0 ? _endTime : block.timestamp;
        return
            _rewardPerTokenStored.add(
                latestTime.sub(_lastUpdateTime).mul(_rewardRate).mul(1e18).div(
                    _totalSupply
                )
            );
    }

    /// @notice Update reward for a given account
    function updateReward(address account) internal {
        _rewardPerTokenStored = rewardPerToken();
        _lastUpdateTime = block.timestamp;

        _rewards[account] = earned(account);
        _userRewardPerTokenPaid[account] = _rewardPerTokenStored;
    }

    /// @notice Allow an amount of NFP tokens to be staked
    function stake(uint256 amount) external nonReentrant {
        require(
            _endTime == 0 || block.timestamp < _endTime,
            "Staking contract has ended"
        );
        require(amount > 0, "Amount must be greater than 0");
        updateReward(msg.sender);
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _lastStaked[msg.sender] = block.timestamp;
        _stakingToken.transferFrom(msg.sender, address(this), amount);
    }

    /// @notice Allow an amount of NFP tokens to be unstaked
    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(amount <= _balances[msg.sender], "Amount exceeds balance");
        require(
            _lastStaked[msg.sender] <= block.timestamp.sub(10 days),
            "Staking lock period has not expired (10 days)"
        );
        updateReward(msg.sender);
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        uint256 reward = _rewards[msg.sender];
        if (reward > 0) {
            _rewards[msg.sender] = 0;
            amount = amount.add(reward);
        }
        _stakingToken.transfer(msg.sender, amount);
    }

    /// @notice Allow rewards to be claimed
    function claim() external nonReentrant {
        updateReward(msg.sender);
        uint256 reward = _rewards[msg.sender];
        _rewards[msg.sender] = 0;
        _stakingToken.transfer(msg.sender, reward);
    }

    /// @notice Show the accrued rewards for a given account
    function earned(address account) public view returns (uint256) {
        if (_balances[account] == 0) {
            return 0;
        }
        return
            _balances[account]
                .mul(rewardPerToken().sub(_userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(_rewards[account]);
    }
}
