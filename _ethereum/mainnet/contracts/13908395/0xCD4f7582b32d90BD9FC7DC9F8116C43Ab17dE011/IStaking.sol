// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;

interface IStaking {
  function balanceOf(address account) external view returns (uint256);

  function stake(uint256 amount, uint256 lengthOfTime) external;

  function stakeFor(
    address account,
    uint256 amount,
    uint256 lengthOfTime
  ) external;

  function withdraw(uint256 amount) external;

  function getVoiceCredits(address _address) external view returns (uint256);

  function getWithdrawableBalance(address _address) external view returns (uint256);

  function notifyRewardAmount(uint256 reward) external;
}
