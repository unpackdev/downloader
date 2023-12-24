// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IAuthorizable.sol";
import "./IPausable.sol";

interface IStakingV1 is IAuthorizable, IPausable {
  /** events */
  event DepositedEth(address indexed account, uint256 amount);
  event DepositedTokens(address indexed account, uint256 amount);
  event WithdrewTokens(address indexed account, uint256 amount);
  event ClaimedRewards(address indexed account, uint256 amount);

  // function stakingType() external view returns (uint8);
  function rewardsAreToken() external pure returns (bool);
  function autoClaimEnabled() external view returns (bool);
  function setAutoClaimEnabled(bool value) external;
  function accuracy() external view returns (uint256);
  function setAccuracy(uint256 value) external;
  function setAutoClaimOnDeposit(bool value) external;
  function setAutoClaimOnClaim(bool value) external;
  function getAutoClaimOptOut(address account) external view returns (bool);
  function setAutoClaimOptOut(bool value) external;
  function removeLockDuration() external;
  function getPlaceInQueue(address account) external view returns (uint256);
  function autoClaimGasLimit() external view returns (uint256);
  function setAutoClaimGasLimit(uint256 value) external;
  function token() external view returns (address);
  function getStakingData() external view returns (
    uint8 stakingType,
    address stakedToken,
    uint8 decimals,
    uint256 totalStaked,
    uint256 totalRewards,
    uint256 totalClaimed
  );
  function getStakingDataForAccount(address account) external view returns (
    uint256 amount,
    uint64 lastClaimedAt,
    uint256 pendingRewards,
    uint256 totalClaimed
  );
  function pending(address account) external view returns (uint256);
  function claimFor(address account, bool revertOnFailure, bool doAutoClaim) external;
  function claim() external;
  function deposit(uint256 amount) external;
  function getUnlockTime(address account) external view returns (uint64);
  function withdraw(uint256 amount) external;
  function emergencyWithdraw() external;
  function processAutoClaim() external;
}
