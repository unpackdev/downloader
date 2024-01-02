// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract IceStake is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  IERC20 public stakedToken;
  IERC20 public rewardToken;

  uint256 public currentRound;
  mapping(uint256 => uint256) public roundPool;
  struct RoundDuration {
    uint32 startBlock;
    uint32 endBlock;
  }
  mapping(uint256 => RoundDuration) public roundDuration;
  mapping(uint256 => mapping(address => bool)) public roundClaimed;

  uint256 public minStakeAmount = 10000 * 10 ** 18;

  struct StakeInfo {
    uint128 amount;
    uint32 startedBlockNumber;
    uint32 blocks;
    bool staked;
    bool unstaked;
  }
  // user => stake index => StakeInfo
  mapping(address => mapping(uint256 => StakeInfo)) public userStakeInfo;
  // user latest stake index
  mapping(address => uint256) public userIndexCount;
  // all users stake index count
  uint256 public totalIndexCount;
  // all users stake index => StakeInfo
  mapping(uint256 => StakeInfo) public totalStakeDatabase;

  // events
  event Deposit(uint256 round, uint256 amount);
  event Staked(address user, uint256 amount, uint256 blocks, uint256 index);
  event Unstaked(address user, uint256 stakeAmount);
  event Claimed(address user, uint256 rewardAmount);
  event RoundIncremented(uint256 round, uint256 startBlock, uint256 endBlock);

  constructor(address _stakedToken, address _rewardToken) Ownable() {
    stakedToken = IERC20(_stakedToken);
    rewardToken = IERC20(_rewardToken);
  }

  function stake(uint128 amount, uint32 blocks) external {
    require(amount >= minStakeAmount, "Cannot stake less than min stake amount");

    stakedToken.safeTransferFrom(msg.sender, address(this), amount);

    StakeInfo memory info;
    info.amount = amount;
    info.startedBlockNumber = uint32(block.number);
    info.blocks = blocks;
    info.staked = true;
    info.unstaked = false;

    userIndexCount[msg.sender] += 1;
    userStakeInfo[msg.sender][userIndexCount[msg.sender]] = info;
    totalIndexCount += 1;
    totalStakeDatabase[totalIndexCount] = info;

    emit Staked(msg.sender, amount, blocks, userIndexCount[msg.sender]);
  }

  function unstake(uint256 index) external nonReentrant {
    StakeInfo memory info = userStakeInfo[msg.sender][index];
    require(info.staked, "Not staked");
    require(!info.unstaked, "Already unstaked");
    require(info.startedBlockNumber + info.blocks <= block.number, "Cannot unstake before end of stake round");

    stakedToken.safeTransfer(msg.sender, info.amount);
    userStakeInfo[msg.sender][index].unstaked = true;
    emit Unstaked(msg.sender, info.amount);
  }

  function unstakeAll() external nonReentrant {
    uint256 amount;
    for (uint256 i = 1; i <= userIndexCount[msg.sender]; i++) {
      StakeInfo memory info = userStakeInfo[msg.sender][i];
      if (info.staked && !info.unstaked && info.startedBlockNumber + info.blocks <= block.number) {
        if (info.amount > 0) {
          amount += info.amount;
          userStakeInfo[msg.sender][i].unstaked = true;
        }
      }
    }

    if (amount > 0) {
      stakedToken.safeTransfer(msg.sender, amount);
      emit Unstaked(msg.sender, amount);
    }
  }

  function intersection(
    uint256 start1,
    uint256 end1,
    uint256 start2,
    uint256 end2
  ) internal pure returns (uint256, uint256) {
    require(start1 <= end1, "Invalid interval [start1, end1]");
    require(start2 <= end2, "Invalid interval [start2, end2]");

    if (end1 < start2 || end2 < start1) {
      return (0, 0);
    }
    return (start1 < start2 ? start2 : start1, end1 < end2 ? end1 : end2);
  }

  function calculateReward(uint256 round, address user) public view returns (uint256) {
    uint256 _roundPool = roundPool[round];
    RoundDuration memory duration = roundDuration[round];

    uint256 userShare;
    for (uint256 i = 1; i <= userIndexCount[user]; i++) {
      StakeInfo memory info = userStakeInfo[user][i];
      (uint256 start, uint256 end) = intersection(
        info.startedBlockNumber,
        info.startedBlockNumber + info.blocks,
        duration.startBlock,
        duration.endBlock
      );

      if (start > 0 && end > 0) {
        userShare += info.amount * (end - start);
      }
    }

    uint256 totalShare;
    for (uint256 i = 1; i <= totalIndexCount; i++) {
      StakeInfo memory info = totalStakeDatabase[i];
      (uint256 start, uint256 end) = intersection(
        info.startedBlockNumber,
        info.startedBlockNumber + info.blocks,
        duration.startBlock,
        duration.endBlock
      );

      if (start > 0 && end > 0) {
        totalShare += info.amount * (end - start);
      }
    }

    if (totalShare == 0) {
      return 0;
    }

    return (userShare * _roundPool) / totalShare;
  }

  function claim(uint256 round) external nonReentrant {
    require(roundClaimed[round][msg.sender] == false, "Claimed current round");

    uint256 rewardAmount = calculateReward(round, msg.sender);
    rewardToken.safeTransfer(msg.sender, rewardAmount);
    roundClaimed[round][msg.sender] = true;
    emit Claimed(msg.sender, rewardAmount);
  }

  function claimAll() external nonReentrant {
    for (uint256 i = 1; i <= currentRound; i++) {
      if (roundClaimed[i][msg.sender] == false) {
        uint256 rewardAmount = calculateReward(i, msg.sender);
        if (rewardAmount != 0) {
          rewardToken.safeTransfer(msg.sender, rewardAmount);
          roundClaimed[i][msg.sender] = true;
          emit Claimed(msg.sender, rewardAmount);
        }
      }
    }
  }

  function setMinStakeAmount(uint256 amount) external onlyOwner {
    minStakeAmount = amount;
  }

  function setRewardToken(address _rewardToken) external onlyOwner {
    rewardToken = IERC20(_rewardToken);
  }

  function setStakedToken(address _stakedToken) external onlyOwner {
    stakedToken = IERC20(_stakedToken);
  }

  function incrementRound(uint32 startBlockNumber, uint32 blocks) external onlyOwner returns (uint256) {
    currentRound += 1;
    roundDuration[currentRound] = RoundDuration(startBlockNumber, startBlockNumber + blocks);
    emit RoundIncremented(currentRound, startBlockNumber, startBlockNumber + blocks);
    return currentRound;
  }

  function deposit(address from, uint256 round, uint256 amount) external onlyOwner {
    rewardToken.safeTransferFrom(from, address(this), amount);
    roundPool[round] += amount;
    emit Deposit(round, amount);
  }

  // in case deposit reward tokens directly to contract vie erc20 transfer method
  function allocateToRoundPool(uint256 round, uint256 amount) external onlyOwner {
    roundPool[round] += amount;
    emit Deposit(round, amount);
  }

  function whithdrawErc20(address _token) external onlyOwner {
    IERC20(_token).safeTransfer(msg.sender, IERC20(_token).balanceOf(address(this)));
  }

  function whithdrawEth() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }
}
