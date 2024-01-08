// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;

// Libraries
import "./Math.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

// Interfaces
import "./IERC20.sol";
import "./IStakingRewards.sol";

// Contracts
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./RewardsDistributionRecipient.sol";

contract StakingRewards is RewardsDistributionRecipient, ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  IERC20 public rewardsTokenDPX;
  IERC20 public rewardsTokenRDPX;
  IERC20 public stakingToken;
  uint256 public boost = 0;
  uint256 public periodFinish = 0;
  uint256 public boostedFinish = 0;
  uint256 public rewardRateDPX = 0;
  uint256 public rewardRateRDPX = 0;
  uint256 public rewardsDuration;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStoredDPX;
  uint256 public rewardPerTokenStoredRDPX;
  uint256 public boostedTimePeriod;
  uint256 public id;

  mapping(address => uint256) public userDPXRewardPerTokenPaid;
  mapping(address => uint256) public userRDPXRewardPerTokenPaid;
  mapping(address => uint256) public rewardsDPX;
  mapping(address => uint256) public rewardsRDPX;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _rewardsDistribution,
    address _rewardsTokenDPX,
    address _rewardsTokenRDPX,
    address _stakingToken,
    uint256 _rewardsDuration,
    uint256 _boostedTimePeriod,
    uint256 _boost,
    uint256 _id
  ) Ownable() {
    rewardsTokenDPX = IERC20(_rewardsTokenDPX);
    rewardsTokenRDPX = IERC20(_rewardsTokenRDPX);
    stakingToken = IERC20(_stakingToken);
    rewardsDistribution = _rewardsDistribution;
    rewardsDuration = _rewardsDuration;
    boostedTimePeriod = _boostedTimePeriod;
    boost = _boost;
    id = _id;
  }

  /* ========== VIEWS ========== */

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    uint256 timeApp = Math.min(block.timestamp, periodFinish);
    return timeApp;
  }

  function rewardPerToken() public view returns (uint256, uint256) {
    if (_totalSupply == 0) {
      uint256 perTokenRateDPX = rewardPerTokenStoredDPX;
      uint256 perTokenRateRDPX = rewardPerTokenStoredRDPX;
      return (perTokenRateDPX, perTokenRateRDPX);
    }
    if (block.timestamp < boostedFinish) {
      uint256 perTokenRateDPX =
        rewardPerTokenStoredDPX.add(
          lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRateDPX.mul(boost))
            .mul(1e18)
            .div(_totalSupply)
        );
      uint256 perTokenRateRDPX =
        rewardPerTokenStoredRDPX.add(
          lastTimeRewardApplicable()
            .sub(lastUpdateTime)
            .mul(rewardRateRDPX.mul(boost))
            .mul(1e18)
            .div(_totalSupply)
        );
      return (perTokenRateDPX, perTokenRateRDPX);
    } else {
      if (lastUpdateTime < boostedFinish) {
        uint256 perTokenRateDPX =
          rewardPerTokenStoredDPX
            .add(
            boostedFinish.sub(lastUpdateTime).mul(rewardRateDPX.mul(boost)).mul(1e18).div(
              _totalSupply
            )
          )
            .add(
            lastTimeRewardApplicable().sub(boostedFinish).mul(rewardRateDPX).mul(1e18).div(
              _totalSupply
            )
          );
        uint256 perTokenRateRDPX =
          rewardPerTokenStoredRDPX
            .add(
            boostedFinish.sub(lastUpdateTime).mul(rewardRateRDPX.mul(boost)).mul(1e18).div(
              _totalSupply
            )
          )
            .add(
            lastTimeRewardApplicable().sub(boostedFinish).mul(rewardRateRDPX).mul(1e18).div(
              _totalSupply
            )
          );
        return (perTokenRateDPX, perTokenRateRDPX);
      } else {
        uint256 perTokenRateDPX =
          rewardPerTokenStoredDPX.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRateDPX).mul(1e18).div(
              _totalSupply
            )
          );
        uint256 perTokenRateRDPX =
          rewardPerTokenStoredRDPX.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRateRDPX).mul(1e18).div(
              _totalSupply
            )
          );
        return (perTokenRateDPX, perTokenRateRDPX);
      }
    }
  }

  function earned(address account)
    public
    view
    returns (uint256 DPXtokensEarned, uint256 RDPXtokensEarned)
  {
    uint256 perTokenRateDPX;
    uint256 perTokenRateRDPX;
    (perTokenRateDPX, perTokenRateRDPX) = rewardPerToken();
    DPXtokensEarned = _balances[account]
      .mul(perTokenRateDPX.sub(userDPXRewardPerTokenPaid[account]))
      .div(1e18)
      .add(rewardsDPX[account]);
    RDPXtokensEarned = _balances[account]
      .mul(perTokenRateRDPX.sub(userRDPXRewardPerTokenPaid[account]))
      .div(1e18)
      .add(rewardsRDPX[account]);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */
  function stakeWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external payable nonReentrant updateReward(msg.sender) {
    require(amount > 0, 'Cannot stake 0');
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    // permit
    IUniswapV2ERC20(address(stakingToken)).permit(
      msg.sender,
      address(this),
      amount,
      deadline,
      v,
      r,
      s
    );
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function stake(uint256 amount) external payable nonReentrant updateReward(msg.sender) {
    require(amount > 0, 'Cannot stake 0');
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    stakingToken.safeTransferFrom(msg.sender, address(this), amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
    require(amount > 0, 'Cannot withdraw 0');
    require(amount <= _balances[msg.sender], 'Insufficent balance');
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    stakingToken.safeTransfer(msg.sender, amount);
    emit Withdrawn(msg.sender, amount);
  }

  function withdrawRewardTokens(uint256 amountDPX, uint256 amountRDPX)
    public
    onlyOwner
    returns (uint256, uint256)
  {
    address OwnerAddress = owner();
    if (OwnerAddress == msg.sender) {
      IERC20(rewardsTokenDPX).safeTransfer(OwnerAddress, amountDPX);
      IERC20(rewardsTokenRDPX).safeTransfer(OwnerAddress, amountRDPX);
    }
    return (amountDPX, amountRDPX);
  }

  function compound() public nonReentrant updateReward(msg.sender) {
    uint256 rewardDPX = rewardsDPX[msg.sender];
    require(rewardDPX > 0, 'stake address not found');
    require(rewardsTokenDPX == stakingToken, "Can't stake the reward token.");
    rewardsDPX[msg.sender] = 0;
    _totalSupply = _totalSupply.add(rewardDPX);
    _balances[msg.sender] = _balances[msg.sender].add(rewardDPX);
    emit RewardCompounded(msg.sender, rewardDPX);
  }

  function getReward(uint256 rewardsTokenID) public nonReentrant updateReward(msg.sender) {
    if (rewardsTokenID == 0) {
      uint256 rewardDPX = rewardsDPX[msg.sender];
      require(rewardDPX > 0, 'can not withdraw 0 DPX reward');
      rewardsDPX[msg.sender] = 0;
      rewardsTokenDPX.safeTransfer(msg.sender, rewardDPX);
      emit RewardPaid(msg.sender, rewardDPX);
    } else if (rewardsTokenID == 1) {
      uint256 rewardRDPX = rewardsRDPX[msg.sender];
      require(rewardRDPX > 0, 'can not withdraw 0 RDPX reward');
      rewardsRDPX[msg.sender] = 0;
      rewardsTokenRDPX.safeTransfer(msg.sender, rewardRDPX);
      emit RewardPaid(msg.sender, rewardRDPX);
    } else {
      uint256 rewardDPX = rewardsDPX[msg.sender];
      uint256 rewardRDPX = rewardsRDPX[msg.sender];
      if (rewardDPX > 0) {
        rewardsDPX[msg.sender] = 0;
        rewardsTokenDPX.safeTransfer(msg.sender, rewardDPX);
      }
      if (rewardRDPX > 0) {
        rewardsRDPX[msg.sender] = 0;
        rewardsTokenRDPX.safeTransfer(msg.sender, rewardRDPX);
      }
      emit RewardPaid(msg.sender, rewardDPX);
      emit RewardPaid(msg.sender, rewardRDPX);
    }
  }

  function exit() external {
    getReward(2);
    withdraw(_balances[msg.sender]);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function notifyRewardAmount(uint256 rewardDPX, uint256 rewardRDPX)
    external
    override
    onlyRewardsDistribution
    setReward(address(0))
  {
    if (periodFinish == 0) {
      rewardRateDPX = rewardDPX.div(rewardsDuration.add(boostedTimePeriod));
      rewardRateRDPX = rewardRDPX.div(rewardsDuration.add(boostedTimePeriod));
      lastUpdateTime = block.timestamp;
      periodFinish = block.timestamp.add(rewardsDuration);
      boostedFinish = block.timestamp.add(boostedTimePeriod);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftoverDPX = remaining.mul(rewardRateDPX);
      uint256 leftoverRDPX = remaining.mul(rewardRateRDPX);
      rewardRateDPX = rewardDPX.add(leftoverDPX).div(rewardsDuration);
      rewardRateRDPX = rewardRDPX.add(leftoverRDPX).div(rewardsDuration);
      lastUpdateTime = block.timestamp;
      periodFinish = block.timestamp.add(rewardsDuration);
    }
    emit RewardAdded(rewardDPX, rewardRDPX);
  }

  /* ========== MODIFIERS ========== */

  // Modifier Set Reward modifier
  modifier setReward(address account) {
    (rewardPerTokenStoredDPX, rewardPerTokenStoredRDPX) = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      (rewardsDPX[account], rewardsRDPX[account]) = earned(account);
      userDPXRewardPerTokenPaid[account] = rewardPerTokenStoredDPX;
      userRDPXRewardPerTokenPaid[account] = rewardPerTokenStoredRDPX;
    }
    _;
  }

  // Modifier *Update Reward modifier*
  modifier updateReward(address account) {
    (rewardPerTokenStoredDPX, rewardPerTokenStoredRDPX) = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      (rewardsDPX[account], rewardsRDPX[account]) = earned(account);
      userDPXRewardPerTokenPaid[account] = rewardPerTokenStoredDPX;
      userRDPXRewardPerTokenPaid[account] = rewardPerTokenStoredRDPX;
    }
    _;
  }

  /* ========== EVENTS ========== */

  event RewardUpdated(uint256 rewardDPX, uint256 rewardRDPX);
  event RewardAdded(uint256 rewardDPX, uint256 rewardRDPX);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardCompounded(address indexed user, uint256 rewardDPX);
}

interface IUniswapV2ERC20 {
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}
