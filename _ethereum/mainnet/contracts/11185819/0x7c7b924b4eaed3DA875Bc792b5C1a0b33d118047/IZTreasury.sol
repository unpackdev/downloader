// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import "./IZTreasuryProtocolParameters.sol";

interface IZTreasury is IZTreasuryProtocolParameters {
  event EarningsDistributed(
    uint256 maintainerRewards, 
    uint256 governanceRewards, 
    uint256 totalEarningsDistributed
  );

  function lastEarningsDistribution() external returns (uint256);
  function totalEarningsDistributed() external returns (uint256);
  function distributeEarnings() external;
}