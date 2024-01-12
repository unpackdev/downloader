// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;

import "./UserConfiguration.sol";
import "./ReserveConfiguration.sol";
import "./NFTVaultConfiguration.sol";
import "./ReserveLogic.sol";
import "./NFTVaultLogic.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./INFTXEligibility.sol";
import "./DataTypes.sol";

contract LendingPoolStorage {
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultLogic for DataTypes.NFTVaultData;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  ILendingPoolAddressesProvider internal _addressesProvider;
  INFTXEligibility internal _nftEligibility;

  DataTypes.PoolReservesData internal _reserves;
  DataTypes.PoolNFTVaultsData internal _nftVaults;

  mapping(address => DataTypes.UserConfigurationMap) internal _usersConfig;

  bool internal _paused;

  uint256 internal _maxStableRateBorrowSizePercent;

  uint256 internal _flashLoanPremiumTotal;

  uint256 internal _maxNumberOfReserves;
  uint256 internal _maxNumberOfNFTVaults;
}
