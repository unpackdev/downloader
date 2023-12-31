// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./console.sol";

/**
 * @title USDeSilo
 * @notice The Silo allows to store USDe during the stake cooldown process.
 */
contract USDeSilo {
  using SafeERC20 for IERC20;

  address immutable STAKING_VAULT;
  IERC20 immutable USDE;

  constructor(address stakingVault, address usde) {
    STAKING_VAULT = stakingVault;
    USDE = IERC20(usde);
  }

  modifier onlyStakingVault() {
    require(msg.sender == STAKING_VAULT);
    _;
  }

  function withdraw(address to, uint256 amount) external onlyStakingVault {
    USDE.transfer(to, amount);
  }
}