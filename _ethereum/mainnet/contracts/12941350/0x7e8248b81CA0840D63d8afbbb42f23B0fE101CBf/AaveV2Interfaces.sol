// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;


interface ILendingPoolAddressesProvider {
  function getLendingPool() external view returns (ILendingPool);

  function getPriceOracle() external view returns (IPriceOracle);
}


interface IVariableDebtToken {
  function scaledTotalSupply() external view returns (uint256);
}


interface IReserveInterestRateStrategy {
  function calculateInterestRates(
    address reserve,
    uint256 availableLiquidity,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 averageStableBorrowRate,
    uint256 reserveFactor
  ) external
    view
    returns (
      uint256 liquidityRate,
      uint256 stableBorrowRate,
      uint256 variableBorrowRate
    );
}


interface IStableDebtToken {
  function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);
}


interface ILendingPool {
  struct ReserveConfigurationMap {
    uint256 data;
  }

  struct ReserveData {
    ReserveConfigurationMap configuration;
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 currentLiquidityRate;
    uint128 currentVariableBorrowRate;
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    address aTokenAddress;
    IStableDebtToken stableDebtToken;
    IVariableDebtToken variableDebtToken;
    IReserveInterestRateStrategy interestRateStrategy;
    uint8 id;
  }

  function getReserveNormalizedIncome(address asset) external view returns (uint128);

  function getReserveData(address asset) external view returns (ReserveData memory);

  function getReservesList() external view returns (address[] memory);

  function getConfiguration(address asset) external view returns (ReserveConfigurationMap memory);

  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external;
}


interface IAaveDistributionManager {
  function getAssetData(address asset) external view returns (uint256 index, uint256 emissionPerSecond, uint256 lastUpdateTimestamp);

  function getUserUnclaimedRewards(address account) external view returns (uint256);

  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);
}


interface IPriceOracle {
  function getAssetPrice(address asset) external view returns (uint256);
}


interface IStakedAave {
  function COOLDOWN_SECONDS() external view returns (uint256);

  function stake(address to, uint256 amount) external;

  function redeem(address to, uint256 amount) external;

  function cooldown() external;

  function claimRewards(address to, uint256 amount) external;

  function stakerRewardsToClaim(address account) external view returns (uint256);

  function stakersCooldowns(address account) external view returns (uint256);

  function getTotalRewardsBalance(address staker) external view returns (uint256);

  function getNextCooldownTimestamp(
    uint256 fromCooldownTimestamp,
    uint256 amountToReceive,
    address toAddress,
    uint256 toBalance
  ) external returns (uint256);
}