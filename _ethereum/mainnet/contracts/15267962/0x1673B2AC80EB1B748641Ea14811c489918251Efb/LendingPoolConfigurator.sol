// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.11;
pragma abicoder v2;

import "./VersionedInitializable.sol";
import "./InitializableImmutableAdminUpgradeabilityProxy.sol";
import "./ReserveConfiguration.sol";
import "./NFTVaultConfiguration.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./ILendingPool.sol";
import "./IERC20Metadata.sol";
import "./IERC721.sol";
import "./Errors.sol";
import "./PercentageMath.sol";
import "./DataTypes.sol";
import "./IInitializableDebtToken.sol";
import "./IInitializableVToken.sol";
import "./IInitializableNToken.sol";
import "./INFTXEligibility.sol";
import "./IAaveIncentivesController.sol";
import "./ILendingPoolConfigurator.sol";

/**
 * @title LendingPoolConfigurator contract
 * @author Aave
 * @dev Implements the configuration methods for the Aave protocol
 **/

contract LendingPoolConfigurator is VersionedInitializable, ILendingPoolConfigurator {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NFTVaultConfiguration for DataTypes.NFTVaultConfigurationMap;

  ILendingPoolAddressesProvider internal addressesProvider;
  ILendingPool internal pool;

  modifier onlyPoolAdmin {
    require(addressesProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  modifier onlyEmergencyAdmin {
    require(
      addressesProvider.getEmergencyAdmin() == msg.sender,
      Errors.LPC_CALLER_NOT_EMERGENCY_ADMIN
    );
    _;
  }

  uint256 internal constant CONFIGURATOR_REVISION = 0x2;

  function getRevision() internal pure override returns (uint256) {
    return CONFIGURATOR_REVISION;
  }

  function initialize(ILendingPoolAddressesProvider provider) public initializer {
    addressesProvider = provider;
    pool = ILendingPool(addressesProvider.getLendingPool());
  }

  /**
   * @dev Initializes reserves in batch
   **/
  function batchInitReserve(InitReserveInput[] calldata input) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;
    for (uint256 i = 0; i < input.length; i++) {
      _initReserve(cachedPool, input[i]);
    }
  }

  function _initReserve(ILendingPool pool, InitReserveInput calldata input) internal {
    address vTokenProxyAddress =
      _initContractWithProxy(
        input.vTokenImpl,
        abi.encodeWithSelector(
          IInitializableVToken.initialize.selector,
          pool,
          input.treasury,
          input.underlyingAsset,
          IAaveIncentivesController(input.incentivesController),
          input.underlyingAssetDecimals,
          input.vTokenName,
          input.vTokenSymbol,
          input.params
        )
      );

    address stableDebtTokenProxyAddress = address(0);
    /*  _initContractWithProxy(
        input.stableDebtTokenImpl,
        abi.encodeWithSelector(
          IInitializableDebtToken.initialize.selector,
          pool,
          input.underlyingAsset,
          IAaveIncentivesController(input.incentivesController),
          input.underlyingAssetDecimals,
          input.stableDebtTokenName,
          input.stableDebtTokenSymbol,
          input.params
        )
      );*/

    address variableDebtTokenProxyAddress =
      _initContractWithProxy(
        input.variableDebtTokenImpl,
        abi.encodeWithSelector(
          IInitializableDebtToken.initialize.selector,
          pool,
          input.underlyingAsset,
          IAaveIncentivesController(input.incentivesController),
          input.underlyingAssetDecimals,
          input.variableDebtTokenName,
          input.variableDebtTokenSymbol,
          input.params
        )
      );

    pool.initReserve(
      input.underlyingAsset,
      vTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );

    DataTypes.ReserveConfigurationMap memory currentConfig =
      pool.getConfiguration(input.underlyingAsset);

    currentConfig.setDecimals(input.underlyingAssetDecimals);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    pool.setConfiguration(input.underlyingAsset, currentConfig.data);

    emit ReserveInitialized(
      input.underlyingAsset,
      vTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );
  }

   /**
   * @dev Initializes vaults in batch
   **/
  function batchInitNFTVault(InitNFTVaultInput[] calldata input) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;
    for (uint256 i = 0; i < input.length; i++) {
      _initNFTVault(cachedPool, input[i]);
    }
  }

  function _initNFTVault(ILendingPool pool, InitNFTVaultInput calldata input) internal {
    address nTokenProxyAddress =
      _initContractWithProxy(
        input.nTokenImpl,
        abi.encodeWithSelector(
          IInitializableNToken.initialize.selector,
          pool,
          input.underlyingAsset,
          input.nTokenName,
          input.nTokenSymbol,
          input.baseURI,
          input.params
        )
      );

    address eligibilityProxyAddress = 
      _initContractWithProxy(
        input.nftEligibility,
        abi.encodeWithSelector(
          INFTXEligibility.__NFTXEligibility_init_bytes.selector,
          input.eligibilityParams
        )
      );

    pool.initNFTVault(
      input.underlyingAsset,
      nTokenProxyAddress,
      eligibilityProxyAddress
    );

    DataTypes.NFTVaultConfigurationMap memory currentConfig =
      pool.getNFTVaultConfiguration(input.underlyingAsset);

    currentConfig.setActive(true);
    currentConfig.setFrozen(false);

    pool.setNFTVaultConfiguration(input.underlyingAsset, currentConfig.data);

    emit NFTVaultInitialized(
      input.underlyingAsset,
      nTokenProxyAddress,
      eligibilityProxyAddress
    );
  }

  /**
   * @dev Updates the vToken implementation for the reserve
   **/
  function updateVToken(UpdateVTokenInput calldata input) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;

    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, ) = cachedPool.getConfiguration(input.asset).getParamsMemory();

    bytes memory encodedCall = abi.encodeWithSelector(
        IInitializableVToken.initialize.selector,
        cachedPool,
        input.treasury,
        input.asset,
        input.incentivesController,
        decimals,
        input.name,
        input.symbol,
        input.params
      );

    _upgradeImplementation(
      reserveData.vTokenAddress,
      input.implementation,
      encodedCall
    );

    emit VTokenUpgraded(input.asset, reserveData.vTokenAddress, input.implementation);
  }

  /**
   * @dev Updates the stable debt token implementation for the reserve
   **/
  function updateStableDebtToken(UpdateDebtTokenInput calldata input) external onlyPoolAdmin {
    /*ILendingPool cachedPool = pool;

    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);
     
    (, , , uint256 decimals, ) = cachedPool.getConfiguration(input.asset).getParamsMemory();

    bytes memory encodedCall = abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        cachedPool,
        input.asset,
        input.incentivesController,
        decimals,
        input.name,
        input.symbol,
        input.params
      );

    _upgradeImplementation(
      reserveData.stableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit StableDebtTokenUpgraded(
      input.asset,
      reserveData.stableDebtTokenAddress,
      input.implementation
    );*/
  }

  /**
   * @dev Updates the variable debt token implementation for the asset
   **/
  function updateVariableDebtToken(UpdateDebtTokenInput calldata input)
    external
    onlyPoolAdmin
  {
    ILendingPool cachedPool = pool;

    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, ) = cachedPool.getConfiguration(input.asset).getParamsMemory();

    bytes memory encodedCall = abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        cachedPool,
        input.asset,
        input.incentivesController,
        decimals,
        input.name,
        input.symbol,
        input.params
      );

    _upgradeImplementation(
      reserveData.variableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit VariableDebtTokenUpgraded(
      input.asset,
      reserveData.variableDebtTokenAddress,
      input.implementation
    );
  }

  /**
   * @dev Updates the nToken implementation for the vault
   **/
  function updateNToken(UpdateNTokenInput calldata input) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;

    DataTypes.NFTVaultData memory vaultData = cachedPool.getNFTVaultData(input.asset);

    bytes memory encodedCall = abi.encodeWithSelector(
        IInitializableNToken.initialize.selector,
        cachedPool,
        input.asset,
        input.name,
        input.symbol,
        input.baseURI,
        input.params
      );

    _upgradeImplementation(
      vaultData.nTokenAddress,
      input.implementation,
      encodedCall
    );

    emit NTokenUpgraded(input.asset, vaultData.nTokenAddress, input.implementation);
  }

  function updateNFTEligibility(address asset, address implementation, bytes calldata params) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;

    DataTypes.NFTVaultData memory vaultData = cachedPool.getNFTVaultData(asset);

    bytes memory encodedCall = abi.encodeWithSelector(
        INFTXEligibility.__NFTXEligibility_init_bytes.selector,
        params
      );

    _upgradeImplementation(
      vaultData.nftEligibility,
      implementation,
      encodedCall
    );

    emit NFTEligibilityUpgraded(asset, vaultData.nftEligibility, implementation);
  }

  function setNFTEligibility(address asset, address implementation, bytes calldata params) external onlyPoolAdmin {
    ILendingPool cachedPool = pool;

    bytes memory encodedCall = abi.encodeWithSelector(
        INFTXEligibility.__NFTXEligibility_init_bytes.selector,
        params
      );

    address eligibilityProxyAddress = 
      _initContractWithProxy(
        implementation,
        abi.encodeWithSelector(
          INFTXEligibility.__NFTXEligibility_init_bytes.selector,
          params
        )
      );

    cachedPool.setNFTVaultEligibility(asset, eligibilityProxyAddress);
    emit NFTEligibilityUpgraded(asset, eligibilityProxyAddress, implementation);
  }

  /**
   * @dev Enables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
   **/
  function enableBorrowingOnReserve(address asset, bool stableBorrowRateEnabled)
    external
    onlyPoolAdmin
  {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setBorrowingEnabled(true);
    currentConfig.setStableRateBorrowingEnabled(stableBorrowRateEnabled);

    pool.setConfiguration(asset, currentConfig.data);

    emit BorrowingEnabledOnReserve(asset, stableBorrowRateEnabled);
  }

  /**
   * @dev Disables borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableBorrowingOnReserve(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setBorrowingEnabled(false);

    pool.setConfiguration(asset, currentConfig.data);
    emit BorrowingDisabledOnReserve(asset);
  }

  /**
   * @dev Configures the nft vault collateralization parameters
   * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means 100.00%
   * @param nft The address of the underlying NFT of the vault
   * @param ltv The loan to value of the NFT when used as collateral
   * @param liquidationThreshold The threshold at which loans using this NFT as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this NFT. The values is always above 100%. A value of 105%
   * means the liquidator will receive a 5% bonus
   **/
  function configureNFTVaultAsCollateral(
    address nft,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus
  ) external onlyPoolAdmin {
    DataTypes.NFTVaultConfigurationMap memory currentConfig = pool.getNFTVaultConfiguration(nft);

    //validation of the parameters: the LTV can
    //only be lower or equal than the liquidation threshold
    //(otherwise a loan against the asset would cause instantaneous liquidation)
    require(ltv <= liquidationThreshold, Errors.LPC_INVALID_CONFIGURATION);

    if (liquidationThreshold != 0) {
      //liquidation bonus must be bigger than 100.00%, otherwise the liquidator would receive less
      //collateral than needed to cover the debt
      require(
        liquidationBonus > PercentageMath.PERCENTAGE_FACTOR,
        Errors.LPC_INVALID_CONFIGURATION
      );

      //if threshold * bonus is less than PERCENTAGE_FACTOR, it's guaranteed that at the moment
      //a loan is taken there is enough collateral available to cover the liquidation bonus
      require(
        liquidationThreshold.percentMul(liquidationBonus) <= PercentageMath.PERCENTAGE_FACTOR,
        Errors.LPC_INVALID_CONFIGURATION
      );
    } else {
      require(liquidationBonus == 0, Errors.LPC_INVALID_CONFIGURATION);
      //if the liquidation threshold is being set to 0,
      // the reserve is being disabled as collateral. To do so,
      //we need to ensure no liquidity is deposited
      _checkNFTVaultNoLiquidity(nft);
    }

    currentConfig.setLtv(ltv);
    currentConfig.setLiquidationThreshold(liquidationThreshold);
    currentConfig.setLiquidationBonus(liquidationBonus);

    pool.setNFTVaultConfiguration(nft, currentConfig.data);

    emit CollateralConfigurationChanged(nft, ltv, liquidationThreshold, liquidationBonus);
  }

  /**
   * @dev Enable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function enableReserveStableRate(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setStableRateBorrowingEnabled(true);

    pool.setConfiguration(asset, currentConfig.data);

    emit StableRateEnabledOnReserve(asset);
  }

  /**
   * @dev Disable stable rate borrowing on a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function disableReserveStableRate(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setStableRateBorrowingEnabled(false);

    pool.setConfiguration(asset, currentConfig.data);

    emit StableRateDisabledOnReserve(asset);
  }

  /**
   * @dev Activates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function activateReserve(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setActive(true);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveActivated(asset);
  }

  /**
   * @dev Deactivates a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function deactivateReserve(address asset) external onlyPoolAdmin {
    _checkNoLiquidity(asset);

    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setActive(false);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveDeactivated(asset);
  }

  /**
   * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow
   *  but allows repayments, liquidations, and withdrawals
   * @param asset The address of the underlying asset of the reserve
   **/
  function freezeReserve(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setFrozen(true);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveFrozen(asset);
  }

  /**
   * @dev Unfreezes a reserve
   * @param asset The address of the underlying asset of the reserve
   **/
  function unfreezeReserve(address asset) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setFrozen(false);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveUnfrozen(asset);
  }

  /**
   * @dev Updates the reserve factor of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address asset, uint256 reserveFactor) external onlyPoolAdmin {
    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

    currentConfig.setReserveFactor(reserveFactor);

    pool.setConfiguration(asset, currentConfig.data);

    emit ReserveFactorChanged(asset, reserveFactor);
  }

  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external
    onlyPoolAdmin
  {
    pool.setReserveInterestRateStrategyAddress(asset, rateStrategyAddress);
    emit ReserveInterestRateStrategyChanged(asset, rateStrategyAddress);
  }

  /**
   * @dev Activates a vault
   * @param asset The address of the underlying NFT of the vault
   **/
  function activateNFTVault(address asset) external onlyPoolAdmin {
    DataTypes.NFTVaultConfigurationMap memory currentConfig = pool.getNFTVaultConfiguration(asset);

    currentConfig.setActive(true);

    pool.setNFTVaultConfiguration(asset, currentConfig.data);

    emit NFTVaultActivated(asset);
  }

  /**
   * @dev Deactivates a vault
   * @param asset The address of the underlying NFT of the vault
   **/
  function deactivateNFTVault(address asset) external onlyPoolAdmin {
    _checkNFTVaultNoLiquidity(asset);

    DataTypes.NFTVaultConfigurationMap memory currentConfig = pool.getNFTVaultConfiguration(asset);

    currentConfig.setActive(false);

    pool.setNFTVaultConfiguration(asset, currentConfig.data);

    emit NFTVaultDeactivated(asset);
  }

  /**
   * @dev Freezes a vault. A frozen vault doesn't allow any new deposit,
   *  but allows liquidations and withdrawals
   * @param asset The address of the underlying NFT of the reserve
   **/
  function freezeNFTVault(address asset) external onlyPoolAdmin {
    DataTypes.NFTVaultConfigurationMap memory currentConfig = pool.getNFTVaultConfiguration(asset);

    currentConfig.setFrozen(true);

    pool.setNFTVaultConfiguration(asset, currentConfig.data);

    emit NFTVaultFrozen(asset);
  }

  function updateNFTVaultActionExpiration(address asset, uint40 expiration) external onlyPoolAdmin {
    pool.setNFTVaultActionExpiration(asset, expiration);
    emit NFTVaultActionExpirationUpdated(asset, expiration);
  }

  /**
   * @dev pauses or unpauses all the actions of the protocol, including vToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool val) external onlyEmergencyAdmin {
    pool.setPause(val);
  }

  function _initContractWithProxy(address implementation, bytes memory initParams)
    internal
    returns (address)
  {
    InitializableImmutableAdminUpgradeabilityProxy proxy =
      new InitializableImmutableAdminUpgradeabilityProxy(address(this));

    proxy.initialize(implementation, initParams);

    return address(proxy);
  }

  function _upgradeImplementation(
    address proxyAddress,
    address implementation,
    bytes memory initParams
  ) internal {
    InitializableImmutableAdminUpgradeabilityProxy proxy =
      InitializableImmutableAdminUpgradeabilityProxy(payable(proxyAddress));

    proxy.upgradeToAndCall(implementation, initParams);
  }

  function _checkNoLiquidity(address asset) internal view {
    DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);

    uint256 availableLiquidity = IERC20Metadata(asset).balanceOf(reserveData.vTokenAddress);

    require(
      availableLiquidity == 0 && reserveData.currentLiquidityRate == 0,
      Errors.LPC_RESERVE_LIQUIDITY_NOT_0
    );
  }

  function _checkNFTVaultNoLiquidity(address asset) internal view {
    DataTypes.NFTVaultData memory vaultData = pool.getNFTVaultData(asset);

    uint256 availableLiquidity = IERC721(asset).balanceOf(vaultData.nTokenAddress);

    require(
      availableLiquidity == 0,
      Errors.LPC_RESERVE_LIQUIDITY_NOT_0
    );
  }
}
