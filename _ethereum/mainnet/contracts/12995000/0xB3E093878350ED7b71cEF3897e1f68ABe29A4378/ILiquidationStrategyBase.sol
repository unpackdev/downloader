// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;


import "./IERC20Ext.sol";
import "./ILiquidationPriceOracleBase.sol";

/**
* Use different logics to compute price oracle
* If token is not supported, it should return 0 as conversion rate
*/
interface ILiquidationStrategyBase {

  function updateTreasuryPool(address pool) external;
  function updateRewardPool(address payable pool) external;
  function updateWhitelistedLiquidators(
    address[] calldata liquidators,
    bool isAdd
  ) external;
  function updateWhitelistedOracles(
    address[] calldata oracles,
    bool isAdd
  ) external;

  function liquidate(
    ILiquidationPriceOracleBase oracle,
    IERC20Ext[] calldata sources,
    uint256[] calldata amounts,
    address payable recipient,
    IERC20Ext dest,
    bytes calldata oracleHint,
    bytes calldata txData
  ) external returns (uint256 destAmount);

  function isLiquidationEnabled() external view returns (bool);
  function getLiquidationSchedule()
    external view
    returns(
      uint128 startTime,
      uint64 repeatedPeriod,
      uint64 duration
    );

  function isWhitelistedLiquidator(address liquidator)
    external view returns (bool);
  function getWhitelistedLiquidatorsLength() external view returns (uint256);
  function getWhitelistedLiquidatorAt(uint256 index) external view returns (address);
  function getAllWhitelistedLiquidators()
    external view returns (address[] memory liquidators);

  function isWhitelistedOracle(address oracle)
    external view returns (bool);
  function getWhitelistedPriceOraclesLength() external view returns (uint256);
  function getWhitelistedPriceOracleAt(uint256 index) external view returns (address);
  function getAllWhitelistedPriceOracles()
    external view returns (address[] memory oracles);
  function treasuryPool() external view returns (address);
  function rewardPool() external view returns (address payable);
}
