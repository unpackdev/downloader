pragma solidity 0.7.6;

import "./Math.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Initializable.sol";


// Inheritance
import "./IStakingRewards.sol";
import "./RewardsDistributionRecipient.sol";
import "./StakingRewardsState.sol";

contract StakingRewardsWithLongTermBonus is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, Initializable, StakingRewardsState {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */
    // StakingRewardsState

    /* ========== CONSTRUCTOR ========== */

    function initialize(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public payable initializer {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
    }

    /* ========== VIEWS ========== */

    function totalSupply() override external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) override external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() override public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() override public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) override public view returns (uint256) {
        uint256 generalReward = _balances[account]
                                   .mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18)
                                   .add(rewards[account]);
        /* WAS
        if(currentPeriod==0)
           return generalReward;
        uint16 period = currentPeriod-1;

        if(_balances[account]>0)
          while( period > userLastLongTermBonusPaid[account]) {
            uint256 actualLongTermStake = userLongTermStakeInPeriod[period][account];
            if(actualLongTermStake==0) {
              actualLongTermStake = findLastBalanceInPeriod(account, period)
                                     .mul(periodEnds[period].sub(periodStarts[period]));
            }
            generalReward = generalReward.add(
                              actualLongTermStake
                               .mul(longTermPoolReward[period])
                               .div(longTermPoolSupply[period])
                            );
            period = period - 1;
          }
          */
        return generalReward;
    }

    function earned1(address account) public view returns (uint256) {
        uint256 generalReward = _balances[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18)
        .add(rewards[account]);

        if (currentPeriod == 0)
            return generalReward;
        uint16 period = currentPeriod - 1;

        while (period > userLastLongTermBonusPaid[account]) {
            uint256 actualLongTermStake = userLongTermStakeInPeriod[period][account];
            if (actualLongTermStake == 0) {
                actualLongTermStake = findLastBalanceInPeriod(account, period)
                .mul(periodEnds[period].sub(periodStarts[period]));
            }
            generalReward = generalReward.add(
                actualLongTermStake
                .mul(longTermPoolReward[period])
                .div(longTermPoolSupply[period])
            );
            period = period - 1;
        }

        return generalReward;
    }

    function getRewardForDuration() override external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(uint256 amount, uint deadline, uint8 v, bytes32 r, bytes32 s) override external
     nonReentrant
     updateReward(msg.sender)
     // WAS
     // updateLongTermStake(currentPeriod, msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);

        /* WAS
        require(amount > 0, "Cannot stake 0");
        address user = msg.sender;
        _totalSupply = _totalSupply.add(amount);
        if(_balances[user] == 0) {
          if(currentPeriod>0)
            userLastLongTermBonusPaid[user] = currentPeriod-1;
        }
        _balances[user] =  _balances[user].add(amount);

        // permit
        IUniswapV2ERC20(address(stakingToken)).permit(msg.sender, address(this), amount, deadline, v, r, s);

        stakingToken.safeTransferFrom(user, address(this), amount);
        userLastBalanceInPeriod[currentPeriod][user] = _balances[user];
        uint256 longTermStake = (Math.max(periodEnds[currentPeriod],block.timestamp).sub(block.timestamp)).mul(amount);
        userLongTermStakeInPeriod[currentPeriod][user] = userLongTermStakeInPeriod[currentPeriod][user]
             .add(longTermStake);
        longTermPoolSupply[currentPeriod] = longTermPoolSupply[currentPeriod].add(longTermStake);
        longTermPoolTokenSupply[currentPeriod] = longTermPoolTokenSupply[currentPeriod].add(amount);
        emit Staked(user, amount);
        */
    }

    function stake(uint256 amount) virtual override external
     nonReentrant
     updateReward(msg.sender)
     // WAS
     // updateLongTermStake(currentPeriod, msg.sender)
    {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);


        /*  WAS
        require(amount > 0, "Cannot stake 0");
        address user = msg.sender;
        _totalSupply = _totalSupply.add(amount);
        if(_balances[user] == 0) {
          if(currentPeriod>0)
            userLastLongTermBonusPaid[user] = currentPeriod-1;
        }
        _balances[user] =  _balances[user].add(amount);
        stakingToken.safeTransferFrom(user, address(this), amount);
        userLastBalanceInPeriod[currentPeriod][user] = _balances[user];
        uint256 longTermStake = (Math.max(periodEnds[currentPeriod],block.timestamp).sub(block.timestamp)).mul(amount);
        userLongTermStakeInPeriod[currentPeriod][user] = userLongTermStakeInPeriod[currentPeriod][user]
             .add(longTermStake);
        longTermPoolSupply[currentPeriod] = longTermPoolSupply[currentPeriod].add(longTermStake);
        longTermPoolTokenSupply[currentPeriod] = longTermPoolTokenSupply[currentPeriod].add(amount);
        emit Staked(user, amount);
        */
    }

    function withdraw(uint256 amount) virtual override public
     nonReentrant
     updateReward(msg.sender)
     // WAS
     // updateLongTermStake(currentPeriod, msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);

        /*
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        address user = msg.sender;
        _balances[user] = _balances[user].sub(amount);
        userLastBalanceInPeriod[currentPeriod][user] = _balances[user];
        stakingToken.safeTransfer(user, amount);
        uint256 longTermStake = Math.min(
                                 (periodEnds[currentPeriod]-periodStarts[currentPeriod]).mul(amount),
                                 userLongTermStakeInPeriod[currentPeriod][user]
                                );
        userLongTermStakeInPeriod[currentPeriod][user] = userLongTermStakeInPeriod[currentPeriod][user]
             .sub(longTermStake);
        longTermPoolSupply[currentPeriod] = longTermPoolSupply[currentPeriod].sub(longTermStake);
        longTermPoolTokenSupply[currentPeriod] = longTermPoolTokenSupply[currentPeriod].sub(amount);
        emit Withdrawn(user, amount);
        */
    }

    function getReward() override public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() override external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward, uint256 _rewardsDuration, uint256 longTermBonus) override external
     onlyRewardsDistribution
     updateReward(address(0)) {
        require((_rewardsDuration> 1 days) && (_rewardsDuration < 365 days), "Incorrect rewards duration");
        rewardsDuration = _rewardsDuration;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);

        /* WAS
        require((_rewardsDuration> 1 days) && (_rewardsDuration < 365 days), "Incorrect rewards duration");
        rewardsDuration = _rewardsDuration;
        uint256 leftover;
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration) &&
                leftover.add(reward).add(longTermBonus) <= balance, "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);

        currentPeriod += 1;
        periodEnds[currentPeriod-1] = periodEnds[currentPeriod-1]>block.timestamp?
                                        block.timestamp :
                                        periodEnds[currentPeriod-1];
        periodStarts[currentPeriod] = block.timestamp;
        periodEnds[currentPeriod] = block.timestamp.add(rewardsDuration);

        longTermPoolSupply[currentPeriod] = longTermPoolTokenSupply[currentPeriod-1].mul(rewardsDuration);
        longTermPoolTokenSupply[currentPeriod] =  longTermPoolTokenSupply[currentPeriod-1];

        longTermPoolReward[currentPeriod] = longTermBonus;

        emit RewardAdded(reward);
        */
    }

    function emergencyAssetWithdrawal(address asset) external onlyRewardsDistribution {
      IERC20 token = IERC20(asset);
      token.safeTransfer(rewardsDistribution, token.balanceOf(address(this)));
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
            /* WAS
            if(currentPeriod>0)
              userLastLongTermBonusPaid[account] = currentPeriod-1;
              */
        }
        _;
    }

    /* WAS
    modifier updateLongTermStake(uint16 period, address account) {
        if(_balances[account]>0 && userLastBalanceInPeriod[period][account] == 0) {
          updateLastBalanceInPeriod(account, period);
          updateUserLongTermStake(account, period);
        }
        _;
    }

    function updateLastBalanceInPeriod(address account, uint16 period) internal returns (uint256 longTermStake) {
      if(period==0 || userLastBalanceInPeriod[period][account]>0)
        return userLastBalanceInPeriod[period][account];
      userLastBalanceInPeriod[period][account] = updateLastBalanceInPeriod(account, period-1);
      return userLastBalanceInPeriod[period][account];
    }

    function updateUserLongTermStake(address account, uint16 period) internal {
      if(period == 0 ||
         userLongTermStakeInPeriod[currentPeriod][account]>0 || //Last stake already updated
         userLastBalanceInPeriod[period][account]==0) // no balance no stake
        return;
      if(period<=currentPeriod) {
        userLongTermStakeInPeriod[currentPeriod][account] =
          userLastBalanceInPeriod[period][account].mul(periodEnds[period]-periodStarts[period]);
        }
      updateUserLongTermStake(account, period-1);
    }

*/

    function findLastBalanceInPeriod(address account, uint16 period) view public returns (uint256 longTermStake) {
      if(period==0 || userLastBalanceInPeriod[period][account]>0)
        return userLastBalanceInPeriod[period][account];
      return findLastBalanceInPeriod(account, period-1);
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

