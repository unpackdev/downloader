// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
pragma abicoder v2;


interface ICToken {
  function comptroller() external view returns (address);
  function underlying() external view returns (address);
  function name() external view returns (string memory);
  function totalSupply() external view returns (uint256);

  function supplyRatePerBlock() external view returns (uint256);
  function borrowRatePerBlock() external view returns (uint256);

  function getCash() external view returns (uint256);
  function totalBorrows() external view returns (uint256);
  function totalReserves() external view returns (uint256);
  function reserveFactorMantissa() external view returns (uint256);
  function exchangeRateCurrent() external returns (uint256);
  function exchangeRateStored() external view returns (uint256);
  function accrualBlockNumber() external view returns (uint256);
  function borrowBalanceStored(address account) external view returns (uint);
  function interestRateModel() external view returns (IInterestRateModel);

  function balanceOf(address account) external view returns (uint256);
  function balanceOfUnderlying(address owner) external returns (uint);

  function mint(uint256 mintAmount) external returns (uint256);
  function mint() external payable;
  function redeem(uint256 tokenAmount) external returns (uint256);
  function redeemUnderlying(uint256 underlyingAmount) external returns (uint256);
  function borrow(uint borrowAmount) external returns (uint);

  // Used to check if a cream market is for an SLP token
  function sushi() external view returns (address);
}


interface IInterestRateModel {
  function getBorrowRate(
    uint cash,
    uint borrows,
    uint reserves
  ) external view returns (uint);

  function getSupplyRate(
    uint256 cash,
    uint256 borrows,
    uint256 reserves,
    uint256 reserveFactorMantissa
  ) external view returns (uint);
}


interface IComptroller {
  function admin() external view returns (address);
  function _setMintPaused(address cToken, bool state) external returns (bool);

  function getAllMarkets() external view returns (ICToken[] memory);
  function mintGuardianPaused(address cToken) external view returns (bool);
  function compSpeeds(address cToken) external view returns (uint256);
  function oracle() external view returns (IPriceOracle);
  function compAccrued(address) external view returns (uint);
  function markets(address cToken) external view returns (
    bool isListed,
    uint collateralFactorMantissa,
    bool isComped
  );
  function claimComp(address[] memory holders, address[] memory cTokens, bool borrowers, bool suppliers) external;
  function refreshCompSpeeds() external;
}


interface IPriceOracle {
  function getUnderlyingPrice(address cToken) external view returns (uint);
}