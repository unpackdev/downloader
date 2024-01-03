// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IStakingPool {

  function depositTo(
    uint amount,
    uint trancheId,
    uint requestTokenId,
    address destination
  ) external returns (uint tokenId);

  function withdraw(
    uint tokenId,
    bool withdrawStake,
    bool withdrawRewards,
    uint[] memory trancheIds
  ) external returns (uint withdrawnStake, uint withdrawnRewards);

  function getActiveStake() external view returns (uint);

  function getRewardPerSecond() external view returns (uint);

  function getFirstActiveTrancheId() external view returns (uint);

  function getDeposit(uint tokenId, uint trancheId) external view returns (
    uint lastAccNxmPerRewardShare,
    uint pendingRewards,
    uint stakeShares,
    uint rewardsShares
  );

  function getTranche(uint trancheId) external view returns (
    uint stakeShares,
    uint rewardsShares
  );

  function getExpiredTranche(uint trancheId) external view returns (
    uint accNxmPerRewardShareAtExpiry,
    uint stakeAmountAtExpiry,
    uint stakeShareSupplyAtExpiry
  );

  function getActiveAllocations(
    uint productId
  ) external view returns (uint[] memory trancheAllocations);

}
