//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./PausableUpgradeable.sol";

contract stakingManager is OwnableUpgradeable, PausableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable; // Wrappers around ERC20 operations that throw on failure

  IERC20Upgradeable public stakeToken; // Token to be staked and rewarded
  uint256 public actualTokensStaked; // NCR
  uint256 public tokensStaked; // Total tokens staked

  uint256 private lastRewardedBlock; // Last block number the user had their rewards calculated
  uint256 private accumulatedRewardsPerShare; // Accumulated rewards per share times REWARDS_PRECISION
  uint256 public rewardTokensPerBlock; // Number of reward tokens minted per block
  uint256 private constant REWARDS_PRECISION = 1e12; // A big number to perform mul and div operations

  uint256 public lockedTime; //To lock the tokens in contract for definite time.
  bool public harvestLock; //To lock the harvest/claim.
  uint public endBlock; //At this block,the rewards generation will be stopped.
  uint256 public claimStart; //Users can claim after this time in epoch.
  uint256 public planId;
  uint256 public constant MULTIPLIER_PRECISION = 100;
  uint256 public users;

  // Staking user for a pool
  struct PoolStaker {
    uint256 amount; // The tokens quantity the user has staked.
    uint256 multiplierAmount;
    uint256 stakedTime; //the time at tokens staked
    uint256 lockedTime;
    uint256 userPlan;
    uint256 lastUpdatedBlock;
    uint256 Harvestedrewards; // The reward tokens quantity the user  harvested
    uint256 rewardDebt; // The amount relative to accumulatedRewardsPerShare the user can't get as reward
  }

  struct Plan {
    uint256 noOfDays;
    uint256 multiplier;
  }

  mapping(uint256 => Plan) public plan;

  //  staker address => PoolStaker
  mapping(address => PoolStaker) public poolStakers;

  mapping(address => uint) public userLockedRewards;
  bool public lockTimeFlag;
  bool public stakeFlag;

  // Events
  event Deposit(address indexed user, uint256 amount, uint256 prevPlan, uint256 newPlan);
  event Withdraw(address indexed user, uint256 amount);
  event HarvestRewards(address indexed user, uint256 amount);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function __stakingManager_init(address _rewardTokenAddress, uint256 _rewardTokensPerBlock, uint _endBlock) public initializer {
    __Ownable_init_unchained();
    __Pausable_init_unchained();

    rewardTokensPerBlock = _rewardTokensPerBlock;
    stakeToken = IERC20Upgradeable(_rewardTokenAddress);
    endBlock = _endBlock;
    harvestLock = true;
    planId++;
  }

  function addPlans(uint256[] calldata _noOfDays, uint256[] calldata _multiplier) external onlyOwner {
    uint256 len = _noOfDays.length;
    require(len == _multiplier.length, "Length mismatch");
    for (uint256 i = 0; i < len; ) {
      require(_multiplier[i] > 0, "Zero multiplier");
      plan[planId] = Plan(_noOfDays[i], _multiplier[i]);
      unchecked {
        ++planId;
        ++i;
      }
    }
  }

  function deposit(uint256 _amount, uint256 _planId) external whenNotPaused {
    require(!stakeFlag, "staking has been ended");
    require(block.number < endBlock, "staking has been ended");
    require(_planId > 0 && _planId < planId, "Invalid plan id"); // Have to check
    // require(_amount > 0, "Deposit amount can't be zero");

    PoolStaker storage staker = poolStakers[msg.sender];
    //User is staking more tokens and already has staked
    if (staker.lockedTime > block.timestamp) {
      // User staking for the first time with plan ID
      // User is staking more tokens when lock is still there
      require(staker.userPlan <= _planId, "User can't select lower plan with active lock");
    } else if (staker.amount == 0) {
      require(_amount > 0, "Can't stake 0 tokens");
      users++;
    }
    // User is staking more tokens when lock is reached;
    harvestRewards();
    staker.amount += _amount;
    if (tokensStaked > 0) {
      tokensStaked -= staker.multiplierAmount;
    }
    uint256 prevPlan = staker.userPlan;
    staker.multiplierAmount = (staker.amount * plan[_planId].multiplier) / MULTIPLIER_PRECISION;
    staker.rewardDebt = (staker.multiplierAmount * accumulatedRewardsPerShare) / REWARDS_PRECISION;
    staker.stakedTime = block.timestamp;
    staker.lockedTime = block.timestamp + (plan[_planId].noOfDays * 86400);
    staker.lastUpdatedBlock = block.number;
    staker.userPlan = _planId;

    // Update pool
    tokensStaked += staker.multiplierAmount;
    actualTokensStaked += _amount;

    // Deposit tokens
    emit Deposit(msg.sender, _amount, prevPlan, _planId);
    if (_amount > 0) {
      stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
    }
  }

  /**
   * @dev Withdraw all tokens from existing pool
   */
  function withdraw() external whenNotPaused {
    PoolStaker memory staker = poolStakers[msg.sender];
    uint256 amount = staker.amount;
    if (lockTimeFlag) {
      require(staker.lockedTime <= block.timestamp, "you are not allowed to withdraw before locked Time");
    }
    require(amount > 0, "Withdraw amount can't be zero");

    // Pay rewards
    harvestRewards();

    //delete staker
    delete poolStakers[msg.sender];

    // Update pool
    tokensStaked -= staker.multiplierAmount;
    users--;
    // Withdraw tokens
    emit Withdraw(msg.sender, amount);
    stakeToken.safeTransfer(msg.sender, amount);
  }

  /**
   * @dev Harvest user rewards
   */
  function harvestRewards() public whenNotPaused {
    _harvestRewards(msg.sender);
  }

  /**
   * @dev Harvest user rewards
   */
  function _harvestRewards(address _user) private {
    updatePoolRewards();
    PoolStaker storage staker = poolStakers[_user];
    uint256 rewardsToHarvest = ((staker.multiplierAmount * accumulatedRewardsPerShare) / REWARDS_PRECISION) - staker.rewardDebt;
    if (rewardsToHarvest == 0) {
      return;
    }

    staker.Harvestedrewards += rewardsToHarvest;
    staker.rewardDebt = (staker.multiplierAmount * accumulatedRewardsPerShare) / REWARDS_PRECISION;
    if (!harvestLock) {
      if (userLockedRewards[_user] > 0) {
        rewardsToHarvest += userLockedRewards[_user];
        userLockedRewards[_user] = 0;
      }
      emit HarvestRewards(_user, rewardsToHarvest);
      stakeToken.safeTransfer(_user, rewardsToHarvest);
    } else {
      userLockedRewards[_user] += rewardsToHarvest;
    }
  }

  /**
   * @dev Update pool's accumulatedRewardsPerShare and lastRewardedBlock
   */
  function updatePoolRewards() private {
    if (tokensStaked == 0) {
      lastRewardedBlock = block.number;
      return;
    }
    uint256 blocksSinceLastReward = block.number > endBlock ? endBlock - lastRewardedBlock : block.number - lastRewardedBlock;
    uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
    accumulatedRewardsPerShare = accumulatedRewardsPerShare + ((rewards * REWARDS_PRECISION) / tokensStaked);
    lastRewardedBlock = block.number > endBlock ? endBlock : block.number;
  }

  /**
   *@dev To get the number of rewards that user can get
   */
  function getRewards(address _user) public view returns (uint) {
    if (tokensStaked == 0) {
      return 0;
    }
    uint256 blocksSinceLastReward = block.number > endBlock ? endBlock - lastRewardedBlock : block.number - lastRewardedBlock;
    uint256 rewards = blocksSinceLastReward * rewardTokensPerBlock;
    uint256 accCalc = accumulatedRewardsPerShare + ((rewards * REWARDS_PRECISION) / tokensStaked);
    PoolStaker memory staker = poolStakers[_user];
    return ((staker.multiplierAmount * accCalc) / REWARDS_PRECISION) - staker.rewardDebt + userLockedRewards[_user];
  }

  /**
   * @dev To pause the staking
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev To unpause the staking
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  function setHarvestLock(bool _harvestlock) external onlyOwner {
    harvestLock = _harvestlock;
  }

  function setStakeToken(address _stakeToken) external onlyOwner {
    stakeToken = IERC20Upgradeable(_stakeToken);
  }

  function setLockedTime(uint _time) external onlyOwner {
    lockedTime = _time;
  }

  function setEndBlock(uint _endBlock) external onlyOwner {
    endBlock = _endBlock;
  }

  function setClaimStart(uint _claimStart) external onlyOwner {
    claimStart = _claimStart;
  }

  function setLockTimeFlag(bool _lockTimeFlag) external onlyOwner {
    lockTimeFlag = _lockTimeFlag;
  }
  function seStakeFlag(bool _stakeFlag) external onlyOwner {
    stakeFlag = _stakeFlag;
  }
}
