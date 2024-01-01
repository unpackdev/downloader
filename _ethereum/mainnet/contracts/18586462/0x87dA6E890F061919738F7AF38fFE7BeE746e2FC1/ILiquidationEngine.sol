// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface ILiquidationEngine {
  function collateralTypes(bytes32 _cType)
    external
    view
    returns (address _collateralAuctionHouse, uint256 _liquidationPenalty, uint256 _liquidationQuantity);

  function currentOnAuctionSystemCoins() external view returns (uint256 _currentOnAuctionSystemCoins);
  function onAuctionSystemCoinLimit() external view returns (uint256 _onAuctionSystemCoinLimit);
  function liquidateSAFE(bytes32 _cType, address _safe) external returns (uint256 _auctionId);
}
