// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./BalajiToken.sol";
import "./IBalajiStaking.sol";

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

contract BalajiStaking is Ownable, IBalajiStaking {
  string public networkVersion = "prod-1";
  uint256 public networkVersionId = 1;

  using SafeERC20 for IERC20;

  event Stake(address indexed user, uint256 amount);
  event Unstake(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 amountEth, uint256 amount);

  uint256 public accToken1e30;
  uint256 public totalStaked;

  BalajiToken public balajiToken;

  struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
  }

  mapping(address => UserInfo) public userInfos;

  constructor(BalajiToken _balajiToken) {
    balajiToken = _balajiToken;
  }

  function postProcessReward(uint256 _amount) external {
    require(msg.sender==address(balajiToken));

    if (_amount > 0 && totalStaked > 0) {
      accToken1e30 += (_amount * 1e30 / totalStaked);
    }
  }

  function removeReward(uint256 _amount) public onlyOwner {
    if (totalStaked > 0) {
      accToken1e30 -= (_amount * 1e30 / totalStaked);
    }
    IERC20(balajiToken).safeTransfer(address(msg.sender), _amount);
  }

  function pendingReward(address _user) external view returns (uint256) {
    UserInfo storage user = userInfos[_user];
    return (user.amount * accToken1e30 / 1e30) - user.rewardDebt;
  }

  function stake(uint256 _amount) public {
    require(_amount > 0);

    IERC20(balajiToken).safeTransferFrom(
      address(msg.sender),
      address(this),
      _amount);

    UserInfo storage user = userInfos[msg.sender];
    changeStakingAmount(user, user.amount + _amount);
    totalStaked += _amount;

    emit Stake(msg.sender, _amount);
  }

  function unstake(uint256 _amount) public {
    require(_amount > 0);
    UserInfo storage user = userInfos[msg.sender];
    require(user.amount >= _amount);

    changeStakingAmount(user, user.amount - _amount);
    totalStaked -= _amount;

    IERC20(balajiToken).safeTransfer(
      address(msg.sender),
      _amount);

    emit Unstake(msg.sender, _amount);
  }

  function claim() public {
    UserInfo storage user = userInfos[msg.sender];
    changeStakingAmount(user, user.amount);
  }

  function changeStakingAmount(UserInfo storage user, uint256 newAmount) internal {
    uint256 pending = (user.amount * accToken1e30 / 1e30) - user.rewardDebt;
    if (pending > 0) {
      IERC20(balajiToken).safeTransfer(address(msg.sender), pending);
    }

    user.amount = newAmount;
    user.rewardDebt = newAmount * accToken1e30 / 1e30;
  }
}
