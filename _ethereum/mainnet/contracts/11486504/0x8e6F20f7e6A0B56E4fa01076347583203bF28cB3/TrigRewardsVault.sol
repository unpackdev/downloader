// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;

import "./ERC20Farm.sol";

contract TrigRewardsVault is ERC20Farm {
  constructor(address _rewardToken) public ERC20Farm(_rewardToken) {}
}
