// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./GeminiAI.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract GeminiAIStaking is Ownable {
  using SafeERC20 for IERC20;

  event Stake(address indexed user, uint256 amount);
  event Unstake(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 amountEth, uint256 amount);

  uint256 public totalStaked;
  uint256 public accToken;

  GeminiAI public geminiAI;

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  uint256 private precision = 1e24;
  mapping(address => UserInfo) public userInfos;

  constructor(GeminiAI _geminiAI) {
    geminiAI = _geminiAI;
  }

  function postProcessReward(uint256 _amount) external {
    require(msg.sender==address(geminiAI));

    if (_amount > 0 && totalStaked > 0) {
      accToken += (_amount * precision / totalStaked);
    }
  }

  function removeReward(uint256 _amount) public onlyOwner {
    if (totalStaked > 0) {
      accToken -= (_amount * precision / totalStaked);
    }
    IERC20(geminiAI).safeTransfer(address(msg.sender), _amount);
  }

  function pendingReward(address _user) external view returns (uint256) {
    UserInfo storage user = userInfos[_user];
    return (user.amount * accToken / precision) - user.rewardDebt;
  }

  function stake(uint256 _amount) public {
    require(_amount > 0);

    IERC20(geminiAI).safeTransferFrom(
      address(msg.sender),
      address(this),
      _amount);

    UserInfo storage user = userInfos[msg.sender];
    doUpdate(user, user.amount + _amount);
    totalStaked += _amount;

    emit Stake(msg.sender, _amount);
  }

  function claim() public {
    UserInfo storage user = userInfos[msg.sender];
    doUpdate(user, user.amount);
  }

  function unstake(uint256 _amount) public {
    require(_amount > 0);
    UserInfo storage user = userInfos[msg.sender];
    require(user.amount >= _amount);

    doUpdate(user, user.amount - _amount);
    totalStaked -= _amount;

    IERC20(geminiAI).safeTransfer(
      address(msg.sender),
      _amount);

    emit Unstake(msg.sender, _amount);
  }

  function doUpdate(UserInfo storage user, uint256 newAmount) internal {
    uint256 pending = (user.amount * accToken / precision) - user.rewardDebt;
    if (pending > 0) {
      IERC20(geminiAI).safeTransfer(address(msg.sender), pending);
    }

    user.amount = newAmount;
    user.rewardDebt = newAmount * accToken / precision;
  }
}
