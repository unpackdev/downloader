// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;


interface IReserveInterestRateStrategy {
  function calculateInterestRates(
    address _reserve,
    uint256 _availableLiquidity,
    uint256 _totalBorrowsStable,
    uint256 _totalBorrowsVariable,
    uint256 _averageStableBorrowRate
  )
    external
    view
    returns
  (
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate
  );
}


interface ILendingPoolAddressesProvider {
  function getLendingPoolCore() external view returns (ILendingPoolCore);
  function getLendingPool() external view returns (ILendingPool);
}


interface ILendingPool {
  function deposit(address reserve, uint256 amount, uint16 referralCode) external payable;
}


interface IAToken {
  function redeem(uint256 amount) external;
}


interface ILendingPoolCore {
  function freezeReserve(address _reserve) external;
  function getReserves() external view returns (address[] memory);
  function getReserveIsFreezed(address _reserve) external view returns (bool);
  function getReserveATokenAddress(address) external view returns (address);
  function getReserveCurrentLiquidityRate(address token) external view returns (uint256);
  function getReserveAvailableLiquidity(address token) external view returns (uint256);
  function getReserveTotalBorrowsStable(address token) external view returns (uint256);
  function getReserveTotalBorrowsVariable(address token) external view returns (uint256);
  function getReserveCurrentAverageStableBorrowRate(address token) external view returns (uint256);
  function getReserveInterestRateStrategyAddress(address token) external view returns (IReserveInterestRateStrategy);
}