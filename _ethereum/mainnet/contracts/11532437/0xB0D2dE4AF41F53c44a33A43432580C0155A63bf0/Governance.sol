pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./IRAMv1Router.sol";

contract Governance {
  using SafeMath for uint256;

  IERC20 public YGYToken;
  IRAMv1Router public RAMRouter;

  uint256 public weightedNumber; // Number 1-8 weighted by total user numbers
  uint256 public votingShares; // Includes voting shares generated fromimelocked YGY

  uint256 public lastRAMRouterUpdateTime; // Last time the regenerator tax on the router was updated
  bool public updateStagingMode;
  uint256 public updateStagingReadyTime;
  address public owner;

  struct User {
    uint256 number; // Number from 1-8 indicating the desired LGE regenerator tax %
    uint256 timelockedYGY;
    // The timelocks are stack data structure implemented via hashmaps,
    // there's a stack at each level (1-4)
    mapping(uint256 => mapping(uint256 => TimeLock)) timelocks; // mapping(level => timelock ID => timelock object)
    mapping(uint256 => uint256) timelockTop; // mapping (level => top of stack at this level)
    mapping(uint256 => uint256) timelockCount; // mapping (level => current number timelocks at this level)
  }

  struct TimeLock {
    uint256 multipliedAmount;
    uint256 level;
    uint256 unlockTime;
  }

  mapping(address => User) public users;

  constructor(address _YGYToken, address _RAMRouter) public {
    YGYToken = IERC20(_YGYToken);
    RAMRouter = IRAMv1Router(_RAMRouter);
    weightedNumber = 1; // start at 1%
    owner = msg.sender;
  }

  function updateRouter(address _RAMRouter) external {
    require(msg.sender == owner, "!Owner");
    RAMRouter = IRAMv1Router(_RAMRouter);
  }

  function hasTimeLockAtLevel(address user, uint256 level)
    external
    view
    returns (
      bool _hasTimelock,
      uint256 _level,
      uint256 _unlockTime
    )
  {
    User storage userMem = users[user];
    uint256 timeLocks = userMem.timelockCount[level];
    if (timeLocks > 0) {
      uint256 top = userMem.timelockTop[level];
      uint256 unlockTime = userMem.timelocks[level][top].unlockTime;
      return (true, level, unlockTime);
    } else {
      return (false, level, 0);
    }
  }

  function setUserNumber(uint256 _number) public {
    require(_number >= 1 && _number <= 8, "Number must be in range 1-8");
    User storage user = users[msg.sender];
    user.number = _number;

    calcWeightedNumber(msg.sender);
  }

  function enterRegeneratorUpdateStagingMode() public {
    // 1 day mandatory wait time after last router regenerator tax update
    require(block.timestamp >= lastRAMRouterUpdateTime.add(1 days), "Must wait 1 day since last update");
    updateStagingMode = true;
    updateStagingReadyTime = block.timestamp.add(10 minutes);
  }

  function updateRAMRouterRegeneratorTax() public {
    require(updateStagingMode, "Must be in update staging mode");
    require(block.timestamp >= updateStagingReadyTime, "Must wait 10 minutes since update staged");
    updateStagingMode = false;
    lastRAMRouterUpdateTime = block.timestamp;

    // Update the RAM router's regenerator tax
    RAMRouter.setRegeneratorTax(weightedNumber);
  }

  // users can lock YGY for time durations to get multipliers on their YGY
  function timelockYGY(
    uint256 _amount,
    uint256 _level,
    uint256 _number
  ) public {
    require(_number >= 1 && _number <= 8, "Number must be in range 1-8");
    require(YGYToken.transferFrom(msg.sender, address(this), _amount), "Have tokens been approved?");

    User storage user = users[msg.sender];

    // Calculate effective voting power and create new timelock
    uint256 effectiveAmount = _amount.mul(getMultiplierForLevel(_level)).div(100);
    TimeLock memory timelock =
      TimeLock({ multipliedAmount: effectiveAmount, level: _level, unlockTime: block.timestamp.add(getDurationForLevel(_level)) });

    if (user.timelockTop[_level] == 0) {
      user.timelockTop[_level] = user.timelockTop[_level].add(1);
    }

    uint256 newTimelockCount = user.timelockCount[_level].add(1);
    user.timelocks[_level][newTimelockCount] = timelock;
    user.timelockCount[_level] = newTimelockCount;

    // Add the new voting power to user and the total voting power
    user.timelockedYGY = user.timelockedYGY.add(effectiveAmount);
    votingShares = votingShares.add(effectiveAmount);

    // Update number and calc new weighted number
    user.number = _number;
    calcWeightedNumber(msg.sender);
  }

  // User unlocks their oldest timelock, receiving all the YGY tokens directly to their address
  function unlockOldestTimelock(uint256 _level) public {
    User storage user = users[msg.sender];
    uint256 levelTimelockTop = user.timelockTop[_level];
    TimeLock storage timelock = user.timelocks[_level][levelTimelockTop];
    require(block.timestamp >= timelock.unlockTime, "Tokens are still timelocked");

    // Update user's timelocked balances and the total YGY balance
    user.timelockedYGY = user.timelockedYGY.sub(timelock.multipliedAmount);
    votingShares = votingShares.sub(timelock.multipliedAmount);

    // Send underlying amount of tokens to user
    uint256 underlyingAmount = timelock.multipliedAmount.div(getMultiplierForLevel(timelock.level).div(100));
    YGYToken.transfer(msg.sender, underlyingAmount);

    // Delete the timelock and update user's timelock stack
    delete user.timelocks[_level][levelTimelockTop];
    user.timelockTop[_level] = levelTimelockTop.add(1);
    user.timelockCount[_level] = user.timelockCount[_level].sub(1);

    calcWeightedNumber(msg.sender);
  }

  function calcWeightedNumber(address addr) internal {
    User storage user = users[addr];

    // Calculate the sum of all weights
    uint256 otherTotalYGY = votingShares.sub(user.timelockedYGY);

    // Calculate the sum of all weighing factors
    uint256 userWeighingFactor = user.timelockedYGY.mul(user.number);
    uint256 otherWeighingFactor = otherTotalYGY.mul(weightedNumber);
    uint256 sumOfWeighingFactors = userWeighingFactor.add(otherWeighingFactor);

    // Weighted average = (sum weighing factors / sum of weight)
    if (votingShares > 0 && user.timelockedYGY > 0) {
      weightedNumber = sumOfWeighingFactors.div(votingShares);
    }
  }

  function getDurationForLevel(uint256 _level) public pure returns (uint256) {
    if (_level == 1) {
      return 2 weeks;
    } else if (_level == 2) {
      return 4 weeks;
    } else if (_level == 3) {
      return 12 weeks;
    } else if (_level == 4) {
      return 24 weeks;
    }
    return 2 weeks;
  }

  function getMultiplierForLevel(uint256 _level) public pure returns (uint256) {
    if (_level == 1) {
      return 150; // 1.5x
    } else if (_level == 2) {
      return 300; // 3x
    } else if (_level == 3) {
      return 1000; // 10x
    } else if (_level == 4) {
      return 2500; // 25x
    } else {
      return 150;
    }
  }
}
