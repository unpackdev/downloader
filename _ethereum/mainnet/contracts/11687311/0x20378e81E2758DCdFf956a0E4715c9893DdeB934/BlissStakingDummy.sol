// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Preset.sol";



contract BlissStakingDummy is ERC20Preset {
  uint256 public epochCalculationStartBlock = now;

  constructor(uint256 _initialSupply) public ERC20Preset("BlissStakingDummy", "BlissStakingDummy", 18) {
    _mint(msg.sender, _initialSupply);
  }

  function startNewEpoch() external view {

  }

  function addPendingRewards() external view {

  }
}
