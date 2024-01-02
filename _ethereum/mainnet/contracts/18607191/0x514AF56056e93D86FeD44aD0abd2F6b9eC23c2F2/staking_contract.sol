// SPDX-License-Identifier: Unlicense
pragma solidity =0.8.19;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract StakingManager is Ownable, Pausable {
    using SafeERC20 for IERC20;

    IERC20 public stakeToken;
    address public presaleContract;
    uint256 public tokensStakedByPresale;
    uint256 public actualTokensStaked;
    uint256 public tokensStaked;
    uint256 public rewardTokensPerBlock;
    uint256 public endBlock;
    bool public harvestLock;
    uint256 public claimTime;
    uint256 public claimStart;
    uint256 private _defaultplan = 1;
    uint256 private lastRewardedBlock;
    uint256 private accumulatedRewardsPerShare;
    uint256 private constant REWARDS_PRECISION = 1e12;
    uint256 private constant MULTIPLIER_PRECISION = 100;
    uint256 public lockedTime;
    uint256 public planId;
    uint256 public users;

    struct PoolStaker {
        uint256 amount;
        uint256 multiplierAmount;
        uint256 stakedTime;
        uint256 lockedTime;
        uint256 userPlan;
        uint256 lastUpdatedBlock;
        uint256 Harvestedrewards;
        uint256 rewardDebt;
    }

    struct Plan {
        uint256 noOfDays;
        uint256 multiplier;
    }

    mapping(uint256 => Plan) public plan;
    mapping(address => PoolStaker) public poolStakers;
    mapping(address => uint) public userLockedRewards;

    event Deposit(address indexed user, uint256 amount, uint256 prevPlan, uint256 newPlan);
    event Withdraw(address indexed user, uint256 amount);
    event HarvestRewards(address indexed user, uint256 amount);

 constructor(address _rewardTokenAddress, address _presale, uint256 _rewardTokensPerBlock, uint _endBlock, uint256 initialPlanNoOfDays, uint256 initialPlanMultiplier) Ownable(msg.sender) {
        stakeToken = IERC20(_rewardTokenAddress);
        presaleContract = _presale;
        rewardTokensPerBlock = _rewardTokensPerBlock;
        endBlock = _endBlock;
        harvestLock = true;
        planId++;
        claimTime = 99999999999;  
       
        planId = 1; 
        plan[planId] = Plan(initialPlanNoOfDays, initialPlanMultiplier);      
    }

   modifier onlyPresale() {
    require(msg.sender == presaleContract, "Caller is not the presale contract");
    _;
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

  function depositByPresale(address _user, uint256 _amount) external whenNotPaused onlyPresale {
    require(block.number < endBlock, "staking has been ended");
    // require(_amount > 0, "Deposit amount can't be zero");
    uint256 _planId = _defaultplan; //default lock for depositeByPresale
    PoolStaker storage staker = poolStakers[_user];
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
    _harvestRewards(_user);
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
    tokensStakedByPresale += _amount;

    // Deposit tokens
    emit Deposit(_user, _amount, prevPlan, _planId);
  }

  /**
   * @dev Withdraw all tokens from existing pool
   */
  function withdraw() external whenNotPaused {
    PoolStaker memory staker = poolStakers[msg.sender];
    uint256 amount = staker.amount;
    require(staker.lockedTime <= block.timestamp && claimTime <= block.timestamp, "you are not allowed to withdraw before locked Time");
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
    stakeToken = IERC20(_stakeToken);
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

  function  defaultplan(uint256 __defaultplan) external onlyOwner {
      _defaultplan =  __defaultplan;
  }

  function setPresale(address _presale) external onlyOwner {
    presaleContract = _presale;
  }

  function setClaimTime(uint256 _claimTime) external onlyOwner {
    claimTime = _claimTime;
  }

  function setPresaleContract(address _newPresaleContract) external onlyOwner {
    require(_newPresaleContract != address(0), "Presale contract address cannot be the zero address");
    presaleContract = _newPresaleContract;
}
function setRewardTokensPerBlock(uint256 _newRewardTokensPerBlock) external onlyOwner {
        require(_newRewardTokensPerBlock > 0, "Reward per block must be greater than 0");
        updatePoolRewards();
        rewardTokensPerBlock = _newRewardTokensPerBlock;
    }
    function withdrawTokens(address token, uint256 amount) external onlyOwner   {
        IERC20(token).transfer(owner(), amount);
    }

    function withdrawETHs() external onlyOwner  {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success, "Failed to withdraw");
    }
}