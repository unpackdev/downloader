// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;
//Interface to staking data for relayer job
interface INitroStaking {
  function RelayerJob (  ) external view returns ( address );
  function _stakes ( address ) external view returns ( uint256 stake, uint256 S_init );
  function eth_output_per_second (  ) external view returns ( uint256 );
  function minimumAutoPayoutBalance (  ) external view returns ( uint256 );
  function minimumRewardBalance (  ) external view returns ( uint256 );
  function previousRewardDistributionTimestamp (  ) external view returns ( uint256 );
  function remainingETHToAllocate (  ) external view returns ( uint256 );
  function maxSellRemoval (  ) external view returns ( uint256 );
  function maxBuyBonus (  ) external view returns ( uint256 );
  function stakeHolders (  ) external view returns ( address[] memory);
  function totalStakes (  ) external view returns ( uint256 );
  function totalUnclaimedRewards (  ) external view returns ( uint256 );
  function getEligibleAddressesForAutomaticPayout ( uint256 numToFind ) external view returns ( address[] memory eligible_addresses, uint256 total_reward);
  function getNextEligibleAddressForAutomaticPayout (  ) external view returns ( address );
  function isStakeholder ( address _address ) external view returns ( bool, uint256 );
  function stakeOf ( address _stakeholder ) external view returns ( uint256 );
  function calculateReward ( address _stakeholder ) external view returns ( uint256 );
  function approximateETHPerNISTOutput (  ) external view returns ( uint256 );
  function claimRewards ( address _stakeholder ) external;
  function processAutoRewardPayouts ( address[] calldata stakers, uint256 tokens_to_liquidate) external;
}