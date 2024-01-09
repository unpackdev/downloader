// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "./IERC20.sol";
import "./EthStaking.sol";
import "./Automate.sol";

contract EthAutomate is Automate {
  EthStaking public staking;

  // solhint-disable-next-line no-empty-blocks
  constructor(address _info) Automate(_info) {}

  event Run(uint256 amount);

  function init(address _staking) external initializer {
    staking = EthStaking(_staking);
  }

  function deposit() external onlyOwner {
    IERC20 token = IERC20(staking.stakingToken());
    uint256 balance = token.balanceOf(address(this));
    token.approve(address(staking), balance);
    staking.deposit(balance);
  }

  function refund() external onlyOwner {
    staking.withdraw(staking.balanceOf(address(this)));
    IERC20 token = IERC20(staking.stakingToken());
    token.transfer(owner(), token.balanceOf(address(this)));
  }

  function run(uint256 gasFee) external bill(gasFee, "MockEthAutomate") {
    uint256 balance = staking.balanceOf(address(this));
    staking.withdraw(balance);
    
    IERC20 token = IERC20(staking.stakingToken());
    token.approve(address(staking), balance);
    staking.deposit(balance);

    emit Run(balance);
  }
}
