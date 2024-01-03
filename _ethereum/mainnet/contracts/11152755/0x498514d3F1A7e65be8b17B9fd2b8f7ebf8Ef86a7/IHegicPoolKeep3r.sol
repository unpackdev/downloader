// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

interface IHegicPoolKeep3r {
  event HegicPoolSet(address hegicPool);
  event Keep3rSet(address keep3r);

  // Actions by keeper
  event RewardsClaimedByKeeper(uint256 rewards);

  // Actions forced by governor
  event ForcedClaimedRewards(uint256 rewards);

  // Manager
  event LotsBought(uint256 eth, uint256 wbtc);
  event PendingManagerSet(address pendingManager);
  event AcceptManager();

  // Setters
  function setHegicPool(address _hegicPool) external;
  function setKeep3r(address _keep3r) external;
  // Keep3r actions
  function claimRewards() external;
  // Governor keeper bypass
  function forceClaimRewards() external;
  // HegicPool Manager
  function buyLots(uint256 _eth, uint256 _wbtc) external;
  function setPendingManager(address _pendingManager) external;
  function acceptManager() external;
}