// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./OwnableUpgradeable.sol";
import "./IERC20Upgradeable.sol";

contract TamaStaking is Initializable, OwnableUpgradeable {
  uint256 public totalStaked;
  uint256 public stakedBalance;
  uint256 public rewardBalance;
  uint256 public totalReward;
  uint256 public startingBlock;
  uint256 public endingBlock;
  uint256 public period;
  uint256 public accShare;
  uint256 public lastRewardBlock;
  uint256 public lockDuration;
  bool public isPaused;
  uint256 public constant BLOCKS_PER_HOUR = 300;
  uint256 public constant REWARDS_PRECISION = 1e6;

  IERC20Upgradeable public tokenInterface;

  struct Deposits {
    uint256 amount;
    uint256 initialStake;
    uint256 latestClaim;
    uint256 userAccShare;
    uint256 currentPeriod;
  }

  struct periodDetails {
    uint256 period;
    uint256 accShare;
    uint256 rewPerBlock;
    uint256 startingBlock;
    uint256 endingBlock;
    uint256 rewards;
  }

  mapping(address => Deposits) private deposits;
  mapping(address => bool) public isPaid;
  mapping(address => bool) public hasStaked;
  mapping(uint256 => periodDetails) public endAccShare;

  event NewPeriodSet(uint256 indexed _period, uint256 indexed _startBlock, uint256 indexed _endBlock, uint256 _lockDuration, uint256 _rewardAmount);
  event PeriodExtended(uint256 indexed period, uint256 indexed endBlock, uint256 rewards);

  event Staked(address indexed _staker, uint256 _stakedAmount);

  event RewardsHarvested(address indexed _staker, uint256 _amount, uint256 _reward);

  event Withdrawn(address indexed _staker, uint256 _withdrawnAmount);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function initialize(address _tokenAddress) external initializer {
    require(_tokenAddress != address(0), 'Zero token address');

    __Ownable_init_unchained();

    tokenInterface = IERC20Upgradeable(_tokenAddress);
    isPaused = true;
  }

  function resetAndSetStartEndBlock(uint256 _rewardAmount, uint256 _startBlock, uint256 _endBlock, uint256 _lockDurationInHr) external onlyOwner returns (bool) {
    require(_startBlock > block.number, 'Start should be more than current block');
    require(_endBlock > _startBlock, 'End block should be greater than start');
    require(_rewardAmount > 0, 'Reward must be positive');
    reset();
    addReward(_rewardAmount);
    setStartEnd(_startBlock, _endBlock);
    lockDuration = _lockDurationInHr;
    emit NewPeriodSet(period, _startBlock, _endBlock, _lockDurationInHr, _rewardAmount);
    return true;
  }

  function reset() private {
    require(block.number > endingBlock, 'Wait till end of this period');
    updateShare();
    endAccShare[period] = periodDetails(period, accShare, rewPerBlock(), startingBlock, endingBlock, rewardBalance);
    totalReward = 0;
    stakedBalance = 0;
    isPaused = true;
  }

  function updateShare() private {
    if (stakedBalance == 0) {
      lastRewardBlock = block.number;
      return;
    }

    uint256 noOfBlocks;

    if (block.number >= endingBlock) {
      noOfBlocks = endingBlock - (lastRewardBlock);
    } else {
      noOfBlocks = block.number - (lastRewardBlock);
    }

    uint256 rewards = noOfBlocks * (rewPerBlock());

    accShare = accShare + (((rewards * (REWARDS_PRECISION)) / (stakedBalance)));
    if (block.number >= endingBlock) {
      lastRewardBlock = endingBlock;
    } else {
      lastRewardBlock = block.number;
    }
  }

  function addReward(uint256 _rewardAmount) private _hasAllowance(msg.sender, _rewardAmount) returns (bool) {
    totalReward = totalReward + (_rewardAmount);
    rewardBalance = rewardBalance + (_rewardAmount);
    if (!_payMe(msg.sender, _rewardAmount)) {
      return false;
    }
    return true;
  }

  function setStartEnd(uint256 _start, uint256 _end) private {
    require(totalReward > 0, 'Add rewards for this period');
    startingBlock = _start;
    endingBlock = _end;
    period++;
    isPaused = false;
    lastRewardBlock = _start;
  }

  function rewPerBlock() public view returns (uint256) {
    if (totalReward == 0 || rewardBalance == 0) return 0;
    uint256 rewardPerBlock = totalReward / ((endingBlock - (startingBlock)));
    return (rewardPerBlock);
  }

  function userDeposits(address from) external view returns (Deposits memory) {
    require(hasStaked[from], 'No stakes found for user');
    return deposits[from];
  }

  function stake(uint256 amount) external _hasAllowance(msg.sender, amount) returns (bool) {
    require(!isPaused, 'Contract is paused');
    require(block.number >= startingBlock && block.number < endingBlock, 'Invalid stake period');
    require(amount > 0, "Can't stake 0 amount");
    return (_stake(msg.sender, amount));
  }

  function _stake(address from, uint256 amount) private returns (bool) {
    updateShare();

    if (!hasStaked[from]) {
      deposits[from] = Deposits(amount, block.number, block.number, accShare, period);
      hasStaked[from] = true;
    } else {
      if (deposits[from].currentPeriod != period) {
        bool renew_ = _renew(from);
        require(renew_, 'Error renewing');
      } else {
        bool claim = _claimRewards(from);
        require(claim, 'Error paying rewards');
      }

      uint256 userAmount = deposits[from].amount;

      deposits[from] = Deposits(userAmount + (amount), block.number, block.number, accShare, period);
    }
    stakedBalance = stakedBalance + (amount);
    totalStaked = totalStaked + (amount);
    if (!_payMe(from, amount)) {
      return false;
    }
    emit Staked(from, amount);
    return true;
  }

  function fetchUserShare(address from) internal view returns (uint256) {
    require(hasStaked[from], 'No stakes found for user');
    if (stakedBalance == 0) {
      return 0;
    }
    require(deposits[from].currentPeriod == period, 'Please renew in the active valid period');
    return 1;
  }

  function calculate(address from) public view returns (uint256) {
    if (fetchUserShare(from) == 0) return 0;
    return (_calculate(from));
  }

  function _calculate(address from) private view returns (uint256) {
    uint256 userAccShare = deposits[from].userAccShare;
    uint256 currentAccShare = accShare;

    if (stakedBalance == 0) {
      return 0;
    }

    uint256 noOfBlocks;

    if (block.number >= endingBlock) {
      noOfBlocks = endingBlock - (lastRewardBlock);
    } else {
      noOfBlocks = block.number - (lastRewardBlock);
    }

    uint256 rewards = noOfBlocks * (rewPerBlock());

    uint256 newAccShare = currentAccShare + ((rewards * REWARDS_PRECISION) / (stakedBalance));
    uint256 amount = deposits[from].amount;
    uint256 rewDebt = (amount * userAccShare) / (1e6);
    uint256 rew = ((amount * newAccShare) / REWARDS_PRECISION) - (rewDebt);
    return (rew);
  }

  function claimRewards() public returns (bool) {
    require(fetchUserShare(msg.sender) == 1, 'No stakes found for user');
    return (_claimRewards(msg.sender));
  }

  function _claimRewards(address from) private returns (bool) {
    uint256 userAccShare = deposits[from].userAccShare;
    updateShare();
    uint256 amount = deposits[from].amount;
    uint256 rewDebt = (amount * (userAccShare)) / (REWARDS_PRECISION);
    uint256 rew = ((amount * accShare) / REWARDS_PRECISION) - (rewDebt);
    require(rew > 0, 'No rewards generated');
    deposits[from].userAccShare = accShare;
    deposits[from].latestClaim = block.number;
    rewardBalance = rewardBalance - (rew);
    bool payRewards = _payDirect(from, rew);
    require(payRewards, 'Rewards transfer failed');
    emit RewardsHarvested(from, amount, rew);
    return true;
  }

  function renew() public returns (bool) {
    require(!isPaused, 'Contract paused');
    require(hasStaked[msg.sender], 'No stakes found for user');
    require(deposits[msg.sender].currentPeriod != period, 'Already renewed');
    require(block.number > startingBlock && block.number < endingBlock, 'Wrong time to renew');
    return (_renew(msg.sender));
  }

  function _renew(address from) private returns (bool) {
    updateShare();
    if (calcualteOldRewards(from) > 0) {
      bool claimed = claimOldRewards();
      require(claimed, 'Error paying old rewards');
    }
    deposits[from].currentPeriod = period;
    deposits[from].initialStake = block.number;
    deposits[from].latestClaim = block.number;
    deposits[from].userAccShare = accShare;
    stakedBalance = stakedBalance + (deposits[from].amount);
    return true;
  }

  function calcualteOldRewards(address from) public view returns (uint256) {
    require(!isPaused, 'Contract paused');
    require(hasStaked[from], 'No stakes found for user');

    if (deposits[from].currentPeriod == period) {
      return 0;
    }

    uint256 userPeriod = deposits[from].currentPeriod;

    uint256 accShare1 = endAccShare[userPeriod].accShare;
    uint256 userAccShare = deposits[from].userAccShare;

    if (deposits[from].latestClaim >= endAccShare[userPeriod].endingBlock) return 0;
    uint256 amount = deposits[from].amount;
    uint256 rewDebt = (amount * (userAccShare)) / (REWARDS_PRECISION);
    uint256 rew = ((amount * accShare1) / REWARDS_PRECISION) - (rewDebt);

    return (rew);
  }

  function claimOldRewards() public returns (bool) {
    require(!isPaused, 'Contract paused');
    require(hasStaked[msg.sender], 'No stakes found for user');
    require(deposits[msg.sender].currentPeriod != period, 'Already renewed');

    uint256 userPeriod = deposits[msg.sender].currentPeriod;

    uint256 accShare1 = endAccShare[userPeriod].accShare;
    uint256 userAccShare = deposits[msg.sender].userAccShare;

    require(deposits[msg.sender].latestClaim < endAccShare[userPeriod].endingBlock, 'Already claimed previous period rewards');
    uint256 amount = deposits[msg.sender].amount;
    uint256 rewDebt = (amount * userAccShare) / (1e6);
    uint256 rew = ((amount * accShare1) / REWARDS_PRECISION) - (rewDebt);

    require(rew <= rewardBalance, 'Not enough rewards');
    deposits[msg.sender].latestClaim = endAccShare[userPeriod].endingBlock;
    rewardBalance = rewardBalance - (rew);
    bool paidOldRewards = _payDirect(msg.sender, rew);
    require(paidOldRewards, 'Error paying');
    emit RewardsHarvested(msg.sender, amount, rew);
    return true;
  }

  function withdraw() external returns (bool) {
    require(block.number > deposits[msg.sender].initialStake + (lockDuration * (BLOCKS_PER_HOUR)), "Can't withdraw before lock duration");
    if (deposits[msg.sender].currentPeriod == period) {
      if (calculate(msg.sender) > 0) {
        bool rewardsPaid = claimRewards();
        require(rewardsPaid, 'Error paying rewards');
      }
    }

    if (calcualteOldRewards(msg.sender) > 0) {
      bool oldRewardsPaid = claimOldRewards();
      require(oldRewardsPaid, 'Error paying old rewards');
    }
    return (_withdraw(msg.sender));
  }

  function _withdraw(address from) private returns (bool) {
    updateShare();
    if (!isPaused && deposits[from].currentPeriod == period) {
      stakedBalance = stakedBalance - (deposits[from].amount);
    }
    bool paid = _payDirect(from, (deposits[from].amount));
    require(paid, 'Error during withdraw');
    isPaid[from] = true;
    hasStaked[from] = false;
    delete deposits[from];

    return true;
  }

  function extendPeriod(uint256 rewardsToBeAdded) external onlyOwner returns (bool) {
    require(block.number > startingBlock && block.number < endingBlock, 'Invalid period');
    require(rewardsToBeAdded > 0, 'Zero rewards');
    bool addedRewards = _payMe(msg.sender, rewardsToBeAdded);
    require(addedRewards, 'Error adding rewards');
    endingBlock = endingBlock + (rewardsToBeAdded / (rewPerBlock()));
    totalReward = totalReward + (rewardsToBeAdded);
    rewardBalance = rewardBalance + (rewardsToBeAdded);
    emit PeriodExtended(period, endingBlock, rewardsToBeAdded);
    return true;
  }

  function currentBlock() external view returns (uint256) {
    return (block.number);
  }

  function _payMe(address payer, uint256 amount) private returns (bool) {
    return _payTo(payer, address(this), amount);
  }

  function _payTo(address allower, address receiver, uint256 amount) private returns (bool) {
    // Request to transfer amount from the contract to receiver.
    // contract does not own the funds, so the allower must have added allowance to the contract
    // Allower is the original owner.
    tokenInterface.transferFrom(allower, receiver, amount);
    return true;
  }

  function _payDirect(address to, uint256 amount) private returns (bool) {
    tokenInterface.transfer(to, amount);
    return true;
  }

  modifier _hasAllowance(address allower, uint256 amount) {
    // Make sure the allower has provided the right allowance.
    uint256 ourAllowance = tokenInterface.allowance(allower, address(this));
    require(amount <= ourAllowance, 'Make sure to add enough allowance');
    _;
  }

  function changeTokenInterface(address _tokenAddress) external onlyOwner{
        tokenInterface = IERC20Upgradeable(_tokenAddress);

  }
}
