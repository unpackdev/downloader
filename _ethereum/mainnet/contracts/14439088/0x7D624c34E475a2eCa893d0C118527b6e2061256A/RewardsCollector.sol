// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Address.sol";

contract RewardsCollector is ReentrancyGuard, Ownable {
  WethLike public weth;
  VirtueEthRewardsLike public virtueEthRewards;
  bool public paused = false;

  // callerRewardBps dictates the portion of the reward, in basis points, that the caller of
  // sendRewards is rewarded to for calling sendRewards()
  uint public callerRewardBps = 100;

  // maxCallerReward dictates the maximum amount of ETH (default 0.025) that can be paid for calling
  // sendRewards()
  uint public maxCallerReward = 25000000000000000;

  receive() external payable {}

  constructor(address _wethAddress) {
    weth = WethLike(_wethAddress);
  }

  function setVirtueEthRewardsAddress(address _virtueEthRewardsAddress) external onlyOwner {
    virtueEthRewards = VirtueEthRewardsLike(_virtueEthRewardsAddress);
  }

  function setPaused(bool _newValue) external onlyOwner {
    paused = _newValue;
  }

  function setCallerRewardBps(uint _newValue) external onlyOwner {
    callerRewardBps = _newValue;
  }

  function setMaxCallerReward(uint _newValue) external onlyOwner {
    maxCallerReward = _newValue;
  }

  function sendRewards() external {
    require(!paused, "sendRewards is currently paused");
    weth.withdraw(weth.balanceOf(address(this)));

    uint totalBalance = address(this).balance;
    uint callerReward = totalBalance * callerRewardBps / 10000;
    if (callerReward > maxCallerReward) {
      callerReward = maxCallerReward;
    }
    virtueEthRewards.addReward{ value: totalBalance - callerReward }();

    Address.sendValue(payable(msg.sender), callerReward);
  }
}

interface VirtueEthRewardsLike {
  function addReward() payable external;
}

interface WethLike {
  function withdraw(uint) external;
  function balanceOf(address) external returns(uint);
}
