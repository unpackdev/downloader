// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Math.sol";
import "./ERC20Burnable.sol";

contract CryptoArenaFarm is ReentrancyGuard, ERC20Burnable {
  using SafeERC20 for IERC20;
  using Math for uint256;

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
    uint256 claimed;
  }

  mapping (address => UserInfo) public userInfo;

  uint256 public immutable startBlock;
  uint256 public immutable endBlock;
  uint256 public immutable catPerBlock;

  uint256 public accCatPerToken;
  uint256 public totalStaked;
  uint256 public lastRewardBlock;

  // constants
  uint256 public constant NORMALIZATION_FACTOR = 10**18;
  IERC20 public immutable rewardToken;
  IERC20 public immutable stakingToken;

  event Staked(address indexed user, uint256 amount);
  event UnStaked(address indexed user, uint256 amount);
  event Payout(address indexed user, uint256 amount);
  event EmergencyUnstake(address indexed user, uint256 amount);

  constructor(
    uint256 _startBlock,
    uint256 _catPerBlock,
    uint256 blockDuration,
    IERC20 stakingTokenAddress,
    IERC20 rewardTokenAddress,
    string memory synthTokenName,
    string memory synthTokenSymbol
  ) ERC20(synthTokenName, synthTokenSymbol) {
    startBlock = _startBlock;
    catPerBlock = _catPerBlock;
    endBlock = _startBlock + blockDuration;
    lastRewardBlock = block.number > _startBlock ? block.number : _startBlock;

    stakingToken = stakingTokenAddress;
    rewardToken = rewardTokenAddress;
  }

  function calcReward() private view returns (uint256) {
    uint256 pendingBlocks = block.number.min(endBlock) - lastRewardBlock;

    return pendingBlocks * catPerBlock;
  }

  function calcAccCatPerToken() private view returns (uint256) {
    return accCatPerToken + ((calcReward() * NORMALIZATION_FACTOR) / totalStaked);
  }

  function updatePool() private {
    if (block.number <= lastRewardBlock) {
      return;
    }

    if (totalStaked == 0) {
      lastRewardBlock = block.number.min(endBlock);
      return;
    }

    accCatPerToken = calcAccCatPerToken();
    lastRewardBlock = block.number.min(endBlock);
  }

  function pendingRewards(address account) external view returns (uint256) {
    UserInfo memory user = userInfo[account];
    uint256 catPerShare;

    // calculate the latest value of accCatPerShare if needed
    if (totalStaked > 0) {
      catPerShare = calcAccCatPerToken();
    } else {
      catPerShare = accCatPerToken;
    }

    return ((user.amount * catPerShare) / NORMALIZATION_FACTOR) - user.rewardDebt;
  }

  function releaseRewards() private {
    UserInfo storage user = userInfo[msg.sender];
    uint256 rewards = ((user.amount * accCatPerToken) / NORMALIZATION_FACTOR) - user.rewardDebt;

    if(rewards > 0) {
      rewardToken.safeTransfer(msg.sender, rewards);

      user.claimed += rewards;
      emit Payout(msg.sender, rewards);
    }
  }

  function stake(uint256 amount) external nonReentrant {
    require(block.number >= startBlock, "farming has not started");
    
    if(amount > 0) {
      require(block.number <= endBlock, "farming has ended");
    }

    UserInfo storage user = userInfo[msg.sender];

    updatePool();
    releaseRewards();

    uint256 netAmount;

    if (amount > 0) {
      // Some tokens my incure a transfer fee so the total amount sent can be lower than
      // the amount initially sent
      uint256 balanceBefore = stakingToken.balanceOf(address(this));
      stakingToken.safeTransferFrom(
        address(msg.sender),
        address(this),
        amount
      );
      uint256 balanceAfter = stakingToken.balanceOf(address(this));
      netAmount = balanceAfter - balanceBefore;

      _mint(msg.sender, netAmount);

      user.amount = user.amount + netAmount;
      totalStaked += netAmount;
    }

    user.rewardDebt = (user.amount * accCatPerToken) / NORMALIZATION_FACTOR;

    emit Staked(msg.sender, netAmount);
  }

  function unstake(uint256 amount) external nonReentrant {
    require(block.number > endBlock, "farming period has not finished");
    UserInfo storage user = userInfo[msg.sender];
    require(user.amount >= amount, "insufficient balance");

    updatePool();
    releaseRewards();

    if(amount > 0) {
      user.amount = user.amount - amount;
      totalStaked -= amount;

      stakingToken.safeTransfer(
        address(msg.sender),
        amount
      );

      burn(amount);
    }

    user.rewardDebt = (user.amount * accCatPerToken) / NORMALIZATION_FACTOR;

    emit UnStaked(msg.sender, amount);
  }

  function emergencyUnstake() public nonReentrant {
    require(block.number > endBlock, "farming period has not finished");

    UserInfo storage user = userInfo[msg.sender];
    uint256 unstakeAmount = user.amount;

    user.amount = 0;
    user.rewardDebt = 0;
    totalStaked -= unstakeAmount;

    stakingToken.safeTransfer(address(msg.sender), unstakeAmount);
    burn(unstakeAmount);

    emit EmergencyUnstake(msg.sender, unstakeAmount);
  }
}
