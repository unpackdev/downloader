// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./IMToken.sol";
import "./IBurnLockMToken.sol";
import "./IDebtToken.sol";
import "./ILendPool.sol";
import "./ILendPoolAddressesProvider.sol";

import "./IBNFT.sol";
import "./IBNFTRegistry.sol";

import "./MetaFireUpgradeableProxy.sol";
import "./ReserveConfiguration.sol";
import "./NftConfiguration.sol";
import "./DataTypes.sol";
import "./ConfigTypes.sol";
import "./Errors.sol";

/**
 * @title ConfiguratorLogic library
 * @author MetaFire
 * @notice Implements the logic to configuration feature
 */
library ConfiguratorLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  /**
   * @dev Emitted when a reserve is initialized.
   * @param asset The address of the underlying asset of the reserve
   * @param mTokens The address of the associated mToken contract
   * @param debtToken The address of the associated debtToken contract
   * @param interestRateAddress The address of the interest rate strategy for the reserve
   **/
  event ReserveInitialized(
    address indexed asset,
    address[4] indexed mTokens,
    address debtToken,
    address interestRateAddress
  );

  /**
   * @dev Emitted when a nft is initialized.
   * @param asset The address of the underlying asset of the nft
   * @param bNft The address of the associated bNFT contract
   **/
  event NftInitialized(address indexed asset, address indexed bNft);

  /**
   * @dev Emitted when an mToken implementation is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxies The mToken proxy addresses
   * @param implementation The new mToken implementation
   **/
  event MTokenUpgraded(address indexed asset, address[4] indexed proxies, address indexed implementation);

  /**
   * @dev Emitted when the implementation of a debt token is upgraded
   * @param asset The address of the underlying asset of the reserve
   * @param proxy The debt token proxy address
   * @param implementation The new debtToken implementation
   **/
  event DebtTokenUpgraded(address indexed asset, address indexed proxy, address indexed implementation);

  function executeInitReserve(
    ILendPoolAddressesProvider addressProvider,
    ILendPool cachePool,
    ConfigTypes.InitReserveInput calldata input
  ) external {
    address[4] memory mTokenProxyAddresses;
    uint256 lockPeriod;


    for(uint256 i = 0; i < 4; ++i) {
      if(i == 0) {
        lockPeriod = 120 days;
      } else if(i == 1) {
        lockPeriod = 210 days;
      } else if(i == 2) {
        lockPeriod = 330 days;
      } else if(i == 3) {
        lockPeriod = 390 days;
      }
      address mTokenProxyAddress = _initTokenWithProxy(
        input.mTokenImpl,
        abi.encodeWithSelector(
          IBurnLockMToken.initialize.selector,
          addressProvider,
          input.treasury,
          input.underlyingAsset,
          input.underlyingAssetDecimals,
          input.mTokenName,
          input.mTokenSymbol,
          lockPeriod
        )
      );
      
      mTokenProxyAddresses[i] = mTokenProxyAddress;
    }


    address debtTokenProxyAddress = _initTokenWithProxy(
      input.debtTokenImpl,
      abi.encodeWithSelector(
        IDebtToken.initialize.selector,
        addressProvider,
        input.underlyingAsset,
        input.underlyingAssetDecimals,
        input.debtTokenName,
        input.debtTokenSymbol
      )
    );

    cachePool.initReserve(input.underlyingAsset, mTokenProxyAddresses, debtTokenProxyAddress, input.interestRateAddress);

    DataTypes.ReserveConfigurationMap memory currentConfig = cachePool.getReserveConfiguration(input.underlyingAsset);

    currentConfig.setDecimals(input.underlyingAssetDecimals);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    cachePool.setReserveConfiguration(input.underlyingAsset, currentConfig.data);

    emit ReserveInitialized(
      input.underlyingAsset,
      mTokenProxyAddresses,
      debtTokenProxyAddress,
      input.interestRateAddress
    );
  }

  function executeInitNft(
    ILendPool pool_,
    IBNFTRegistry registry_,
    ConfigTypes.InitNftInput calldata input
  ) external {
    // BNFT proxy and implementation are created in BNFTRegistry
    (address bNftProxy, ) = registry_.getBNFTAddresses(input.underlyingAsset);
    require(bNftProxy != address(0), Errors.LPC_INVALIED_BNFT_ADDRESS);

    pool_.initNft(input.underlyingAsset, bNftProxy);

    DataTypes.NftConfigurationMap memory currentConfig = pool_.getNftConfiguration(input.underlyingAsset);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    pool_.setNftConfiguration(input.underlyingAsset, currentConfig.data);

    emit NftInitialized(input.underlyingAsset, bNftProxy);
  }

  function executeUpdateMToken(ILendPool cachedPool, ConfigTypes.UpdateMTokenInput calldata input) external {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    for(uint256 i = 0; i < 4; ++i) {
      _upgradeTokenImplementation(reserveData.mTokenAddresses[i], input.implementation, input.encodedCallData);
    }

    emit MTokenUpgraded(input.asset, reserveData.mTokenAddresses, input.implementation);
  }

  function executeUpdateDebtToken(ILendPool cachedPool, ConfigTypes.UpdateDebtTokenInput calldata input) external {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    _upgradeTokenImplementation(reserveData.debtTokenAddress, input.implementation, input.encodedCallData);

    emit DebtTokenUpgraded(input.asset, reserveData.debtTokenAddress, input.implementation);
  }

  function getTokenImplementation(address proxyAddress) external view returns (address) {
    MetaFireUpgradeableProxy proxy = MetaFireUpgradeableProxy(payable(proxyAddress));
    return proxy.getImplementation();
  }

  function _initTokenWithProxy(address implementation, bytes memory initParams) internal returns (address) {
    MetaFireUpgradeableProxy proxy = new MetaFireUpgradeableProxy(implementation, address(this), initParams);

    return address(proxy);
  }

  function _upgradeTokenImplementation(
    address proxyAddress,
    address implementation,
    bytes memory encodedCallData
  ) internal {
    MetaFireUpgradeableProxy proxy = MetaFireUpgradeableProxy(payable(proxyAddress));

    if (encodedCallData.length > 0) {
      proxy.upgradeToAndCall(implementation, encodedCallData);
    } else {
      proxy.upgradeTo(implementation);
    }
  }
}
