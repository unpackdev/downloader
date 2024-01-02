// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BRC20AI.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract BRC20AIStaking is Ownable {
  using SafeERC20 for IERC20;

  event Stake(address indexed user, uint256 amount);
  event Unstake(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 amountEth, uint256 amount);

  uint256 public accToken1e20;
  uint256 public totalStaked;

  BRC20AI public brc20ai;

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  mapping(address => UserInfo) public userInfos;

  constructor(BRC20AI _brc20ai) {
    brc20ai = _brc20ai;
  }

  function postProcessReward(uint256 _amount) external {
    require(msg.sender==address(brc20ai));

    if (_amount > 0 && totalStaked > 0) {
      accToken1e20 += (_amount * 1e20 / totalStaked);
    }
  }

  function removeReward(uint256 _amount) public onlyOwner {
    if (totalStaked > 0) {
      accToken1e20 -= (_amount * 1e20 / totalStaked);
    }
    IERC20(brc20ai).safeTransfer(address(msg.sender), _amount);
  }

  function pendingReward(address _user) external view returns (uint256) {
    UserInfo storage user = userInfos[_user];
    return (user.amount * accToken1e20 / 1e20) - user.rewardDebt;
  }

  function stake(uint256 _amount) public {
    require(_amount > 0);

    IERC20(brc20ai).safeTransferFrom(
      address(msg.sender),
      address(this),
      _amount);

    UserInfo storage user = userInfos[msg.sender];
    payAndUpdateUser(user, user.amount + _amount);
    totalStaked += _amount;

    emit Stake(msg.sender, _amount);
  }

  function claim() public {
    UserInfo storage user = userInfos[msg.sender];
    payAndUpdateUser(user, user.amount);
  }

  function unstake(uint256 _amount) public {
    require(_amount > 0);
    UserInfo storage user = userInfos[msg.sender];
    require(user.amount >= _amount);

    payAndUpdateUser(user, user.amount - _amount);
    totalStaked -= _amount;

    IERC20(brc20ai).safeTransfer(
      address(msg.sender),
      _amount);

    emit Unstake(msg.sender, _amount);
  }

  function payAndUpdateUser(UserInfo storage user, uint256 newAmount) internal {
    uint256 pending = (user.amount * accToken1e20 / 1e20) - user.rewardDebt;
    if (pending > 0) {
      IERC20(brc20ai).safeTransfer(address(msg.sender), pending);
    }

    user.amount = newAmount;
    user.rewardDebt = newAmount * accToken1e20 / 1e20;
  }
}
