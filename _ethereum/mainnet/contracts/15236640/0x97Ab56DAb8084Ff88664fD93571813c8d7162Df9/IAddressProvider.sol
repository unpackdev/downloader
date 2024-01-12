// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity 0.8.10;

import "./IVaultsCore.sol";
import "./IPriceFeed.sol";
import "./IVaultsDataProvider.sol";
import "./IConfigProvider.sol";
import "./ILiquidationManager.sol";

interface IAddressProvider {
  function core() external view returns (IVaultsCore);

  function priceFeed() external view returns (IPriceFeed);

  function vaultsData() external view returns (IVaultsDataProvider);

  function stablex() external view returns (address);

  function config() external view returns (IConfigProvider);

  function liquidationManager() external view returns (ILiquidationManager);
}
