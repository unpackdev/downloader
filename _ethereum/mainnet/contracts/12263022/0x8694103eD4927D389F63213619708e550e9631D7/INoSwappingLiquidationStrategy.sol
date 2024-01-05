// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

import "./IERC20Ext.sol";


interface INoSwappingLiquidationStrategy {
  event TreasuryPoolSet(address indexed treasuryPool);
  event RewardPoolSet(address indexed rewardPool);
  event Liquidated(address sender, IERC20Ext[] sources, uint256[] amounts);

  function updateTreasuryPool(address pool) external;
  function updateRewardPool(address payable pool) external;
  function liquidate(IERC20Ext[] calldata sources, uint256[] calldata amounts) external;
  function treasuryPool() external view returns (address);
  function rewardPool() external view returns (address);
}
