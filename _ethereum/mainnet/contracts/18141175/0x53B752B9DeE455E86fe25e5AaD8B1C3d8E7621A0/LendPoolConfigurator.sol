// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./ILendPoolLoan.sol";
import "./IBNFT.sol";
import "./IBNFTRegistry.sol";
import "./ILendPoolConfigurator.sol";
import "./ILendPoolAddressesProvider.sol";
import "./ILendPool.sol";
import "./ReserveConfiguration.sol";
import "./NftConfiguration.sol";
import "./ConfiguratorLogic.sol";
import "./Errors.sol";
import "./PercentageMath.sol";
import "./DataTypes.sol";
import "./ConfigTypes.sol";

import "./IERC20Upgradeable.sol";
import "./Initializable.sol";

/**
 * @title LendPoolConfigurator contract
 * @author MetaFire
 * @dev Implements the configuration methods for the MetaFire protocol
 **/

contract LendPoolConfigurator is Initializable, ILendPoolConfigurator {
  using PercentageMath for uint256;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using NftConfiguration for DataTypes.NftConfigurationMap;

  ILendPoolAddressesProvider internal _addressesProvider;

  modifier onlyPoolAdmin() {
    require(_addressesProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  modifier onlyEmergencyAdmin() {
    require(_addressesProvider.getEmergencyAdmin() == msg.sender, Errors.LPC_CALLER_NOT_EMERGENCY_ADMIN);
    _;
  }

  function initialize(ILendPoolAddressesProvider provider) public initializer {
    _addressesProvider = provider;
  }

  /**
   * @dev Initializes reserves in batch
   **/
  function batchInitReserve(ConfigTypes.InitReserveInput[] calldata input) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < input.length; i++) {
      ConfiguratorLogic.executeInitReserve(_addressesProvider, cachedPool, input[i]);
    }
  }

  function batchInitNft(ConfigTypes.InitNftInput[] calldata input) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    IBNFTRegistry cachedRegistry = _getBNFTRegistry();

    for (uint256 i = 0; i < input.length; i++) {
      ConfiguratorLogic.executeInitNft(cachedPool, cachedRegistry, input[i]);
    }
  }

  /**
   * @dev Updates the mToken implementation for the reserve
   **/
  function updateMToken(ConfigTypes.UpdateMTokenInput[] calldata inputs) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();

    for (uint256 i = 0; i < inputs.length; i++) {
      ConfiguratorLogic.executeUpdateMToken(cachedPool, inputs[i]);
    }
  }

  /**
   * @dev Updates the debt token implementation for the asset
   **/
  function updateDebtToken(ConfigTypes.UpdateDebtTokenInput[] calldata inputs) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();

    for (uint256 i = 0; i < inputs.length; i++) {
      ConfiguratorLogic.executeUpdateDebtToken(cachedPool, inputs[i]);
    }
  }

  function setBorrowingFlagOnReserve(address[] calldata assets, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(assets[i]);

      if (flag) {
        currentConfig.setBorrowingEnabled(true);
      } else {
        currentConfig.setBorrowingEnabled(false);
      }

      cachedPool.setReserveConfiguration(assets[i], currentConfig.data);

      if (flag) {
        emit BorrowingEnabledOnReserve(assets[i]);
      } else {
        emit BorrowingDisabledOnReserve(assets[i]);
      }
    }
  }

  function setActiveFlagOnReserve(address[] calldata assets, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(assets[i]);

      if (!flag) {
        _checkReserveNoLiquidity(assets[i]);
      }
      currentConfig.setActive(flag);
      cachedPool.setReserveConfiguration(assets[i], currentConfig.data);

      if (flag) {
        emit ReserveActivated(assets[i]);
      } else {
        emit ReserveDeactivated(assets[i]);
      }
    }
  }

  function setFreezeFlagOnReserve(address[] calldata assets, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(assets[i]);

      currentConfig.setFrozen(flag);
      cachedPool.setReserveConfiguration(assets[i], currentConfig.data);

      if (flag) {
        emit ReserveFrozen(assets[i]);
      } else {
        emit ReserveUnfrozen(assets[i]);
      }
    }
  }

  /**
   * @dev Updates the reserve factor of a reserve
   * @param assets The address of the underlying asset of the reserve
   * @param reserveFactor The new reserve factor of the reserve
   **/
  function setReserveFactor(address[] calldata assets, uint256 reserveFactor) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(assets[i]);

      currentConfig.setReserveFactor(reserveFactor);

      cachedPool.setReserveConfiguration(assets[i], currentConfig.data);

      emit ReserveFactorChanged(assets[i], reserveFactor);
    }
  }

  /**
   * @dev Sets the interest rate strategy of a reserve
   * @param assets The addresses of the underlying asset of the reserve
   * @param rateAddress The new address of the interest strategy contract
   **/
  function setReserveInterestRateAddress(address[] calldata assets, address rateAddress) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      cachedPool.setReserveInterestRateAddress(assets[i], rateAddress);
      emit ReserveInterestRateChanged(assets[i], rateAddress);
    }
  }

  function batchConfigReserve(ConfigReserveInput[] calldata inputs) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < inputs.length; i++) {
      DataTypes.ReserveConfigurationMap memory currentConfig = cachedPool.getReserveConfiguration(inputs[i].asset);

      currentConfig.setReserveFactor(inputs[i].reserveFactor);

      cachedPool.setReserveConfiguration(inputs[i].asset, currentConfig.data);

      emit ReserveFactorChanged(inputs[i].asset, inputs[i].reserveFactor);
    }
  }

  function setActiveFlagOnNft(address[] calldata assets, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(assets[i]);

      if (!flag) {
        _checkNftNoLiquidity(assets[i]);
      }
      currentConfig.setActive(flag);
      cachedPool.setNftConfiguration(assets[i], currentConfig.data);

      if (flag) {
        emit NftActivated(assets[i]);
      } else {
        emit NftDeactivated(assets[i]);
      }
    }
  }

  function setFreezeFlagOnNft(address[] calldata assets, bool flag) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(assets[i]);

      currentConfig.setFrozen(flag);
      cachedPool.setNftConfiguration(assets[i], currentConfig.data);

      if (flag) {
        emit NftFrozen(assets[i]);
      } else {
        emit NftUnfrozen(assets[i]);
      }
    }
  }

  /**
   * @dev Configures the NFT collateralization parameters
   * all the values are expressed in percentages with two decimals of precision. A valid value is 10000, which means 100.00%
   * @param assets The address of the underlying asset of the reserve
   * @param ltv The loan to value of the asset when used as NFT
   * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param liquidationBonus The bonus liquidators receive to liquidate this asset. The values is always below 100%. A value of 5%
   * means the liquidator will receive a 5% bonus
   **/
  function configureNftAsCollateral(
    address[] calldata assets,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    uint256 liquidatingBuyBonus
  ) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(assets[i]);

      //validation of the parameters: the LTV can
      //only be lower or equal than the liquidation threshold
      //(otherwise a loan against the asset would cause instantaneous liquidation)
      require(ltv <= liquidationThreshold, Errors.LPC_INVALID_CONFIGURATION);

      if (liquidationThreshold != 0) {
        //liquidation bonus must be smaller than or equal 100.00%
        require(liquidationBonus <= PercentageMath.PERCENTAGE_FACTOR, Errors.LPC_INVALID_CONFIGURATION);
      } else {
        require(liquidationBonus == 0, Errors.LPC_INVALID_CONFIGURATION);
      }

      currentConfig.setLtv(ltv);
      currentConfig.setLiquidationThreshold(liquidationThreshold);
      currentConfig.setLiquidationBonus(liquidationBonus);
      currentConfig.setLiquidatingBuyBonus(liquidatingBuyBonus);

      cachedPool.setNftConfiguration(assets[i], currentConfig.data);

      emit NftConfigurationChanged(assets[i], ltv, liquidationThreshold, liquidationBonus, liquidatingBuyBonus);
    }
  }
  

  /**
   * @dev Configures the NFT auction parameters
   * @param assets The address of the underlying asset of the reserve
   * @param redeemDuration The threshold at which loans using this asset as collateral will be considered undercollateralized
   * @param auctionDuration The bonus liquidators receive to liquidate this asset.
   **/
  function configureNftAsAuction(
    address[] calldata assets,
    uint256 redeemDuration,
    uint256 auctionDuration,
    uint256 redeemFine
  ) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(assets[i]);

      //validation of the parameters: the redeem duration can
      //only be lower or equal than the auction duration
      require(redeemDuration <= auctionDuration, Errors.LPC_INVALID_CONFIGURATION);

      currentConfig.setRedeemDuration(redeemDuration);
      currentConfig.setAuctionDuration(auctionDuration);
      currentConfig.setRedeemFine(redeemFine);

      cachedPool.setNftConfiguration(assets[i], currentConfig.data);

      emit NftAuctionChanged(assets[i], redeemDuration, auctionDuration, redeemFine);
    }
  }

  function setNftRedeemThreshold(address[] calldata assets, uint256 redeemThreshold) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(assets[i]);

      currentConfig.setRedeemThreshold(redeemThreshold);

      cachedPool.setNftConfiguration(assets[i], currentConfig.data);

      emit NftRedeemThresholdChanged(assets[i], redeemThreshold);
    }
  }

  function setNftMinBidFine(address[] calldata assets, uint256 minBidFine) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(assets[i]);

      currentConfig.setMinBidFine(minBidFine);

      cachedPool.setNftConfiguration(assets[i], currentConfig.data);

      emit NftMinBidFineChanged(assets[i], minBidFine);
    }
  }

  function setNftMaxSupplyAndTokenId(
    address[] calldata assets,
    uint256 maxSupply,
    uint256 maxTokenId
  ) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < assets.length; i++) {
      cachedPool.setNftMaxSupplyAndTokenId(assets[i], maxSupply, maxTokenId);

      emit NftMaxSupplyAndTokenIdChanged(assets[i], maxSupply, maxTokenId);
    }
  }

  function batchConfigNft(ConfigNftInput[] calldata inputs) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    for (uint256 i = 0; i < inputs.length; i++) {
      DataTypes.NftConfigurationMap memory currentConfig = cachedPool.getNftConfiguration(inputs[i].asset);

      //validation of the parameters: the LTV can
      //only be lower or equal than the liquidation threshold
      //(otherwise a loan against the asset would cause instantaneous liquidation)
      require(inputs[i].baseLTV <= inputs[i].liquidationThreshold, Errors.LPC_INVALID_CONFIGURATION);

      if (inputs[i].liquidationThreshold != 0) {
        //liquidation bonus must be smaller than or equal 100.00%
        require(inputs[i].liquidationBonus <= PercentageMath.PERCENTAGE_FACTOR, Errors.LPC_INVALID_CONFIGURATION);
      } else {
        require(inputs[i].liquidationBonus == 0, Errors.LPC_INVALID_CONFIGURATION);
      }

      // collateral parameters
      currentConfig.setLtv(inputs[i].baseLTV);
      currentConfig.setLiquidationThreshold(inputs[i].liquidationThreshold);
      currentConfig.setLiquidationBonus(inputs[i].liquidationBonus);
      currentConfig.setLiquidatingBuyBonus(inputs[i].liquidatingBuyBonus);

      // auction parameters
      currentConfig.setRedeemDuration(inputs[i].redeemDuration);
      currentConfig.setAuctionDuration(inputs[i].auctionDuration);
      currentConfig.setRedeemFine(inputs[i].redeemFine);
      currentConfig.setRedeemThreshold(inputs[i].redeemThreshold);
      currentConfig.setMinBidFine(inputs[i].minBidFine);

      cachedPool.setNftConfiguration(inputs[i].asset, currentConfig.data);

      emit NftConfigurationChanged(
        inputs[i].asset,
        inputs[i].baseLTV,
        inputs[i].liquidationThreshold,
        inputs[i].liquidationBonus,
        inputs[i].liquidatingBuyBonus
      );
      emit NftAuctionChanged(
        inputs[i].asset,
        inputs[i].redeemDuration,
        inputs[i].auctionDuration,
        inputs[i].redeemFine
      );
      emit NftRedeemThresholdChanged(inputs[i].asset, inputs[i].redeemThreshold);
      emit NftMinBidFineChanged(inputs[i].asset, inputs[i].minBidFine);

      // max limit
      cachedPool.setNftMaxSupplyAndTokenId(inputs[i].asset, inputs[i].maxSupply, inputs[i].maxTokenId);
      emit NftMaxSupplyAndTokenIdChanged(inputs[i].asset, inputs[i].maxSupply, inputs[i].maxTokenId);
    }
  }

  function setMaxNumberOfReserves(uint256 newVal) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    //default value is 32
    uint256 curVal = cachedPool.getMaxNumberOfReserves();
    require(newVal > curVal, Errors.LPC_INVALID_CONFIGURATION);
    cachedPool.setMaxNumberOfReserves(newVal);
  }

  function setMaxNumberOfNfts(uint256 newVal) external onlyPoolAdmin {
    ILendPool cachedPool = _getLendPool();
    //default value is 256
    uint256 curVal = cachedPool.getMaxNumberOfNfts();
    require(newVal > curVal, Errors.LPC_INVALID_CONFIGURATION);
    cachedPool.setMaxNumberOfNfts(newVal);
  }

  /**
   * @dev pauses or unpauses all the actions of the protocol, including mToken transfers
   * @param val true if protocol needs to be paused, false otherwise
   **/
  function setPoolPause(bool val) external onlyEmergencyAdmin {
    ILendPool cachedPool = _getLendPool();
    cachedPool.setPause(val);
  }

  function setPoolPausedTime(uint256 startTime, uint256 durationTime) external onlyEmergencyAdmin {
    ILendPool cachedPool = _getLendPool();
    cachedPool.setPausedTime(startTime, durationTime);
  }

  function approveLoanRepaidInterceptor(address interceptor, bool approved) public onlyPoolAdmin {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();
    cachedPoolLoan.approveLoanRepaidInterceptor(interceptor, approved);
    emit LoanRepaidInterceptorApproval(interceptor, approved);
  }

  function purgeLoanRepaidInterceptor(
    address nftAddress,
    uint256[] calldata tokenIds,
    address interceptor
  ) public onlyPoolAdmin {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();
    cachedPoolLoan.purgeLoanRepaidInterceptor(nftAddress, tokenIds, interceptor);
  }

  function approveFlashLoanLocker(address locker, bool approved) public onlyPoolAdmin {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();
    cachedPoolLoan.approveFlashLoanLocker(locker, approved);
    emit FlashLoanLockerApproval(locker, approved);
  }

  function purgeFlashLoanLocking(
    address nftAddress,
    uint256[] calldata tokenIds,
    address locker
  ) public onlyPoolAdmin {
    ILendPoolLoan cachedPoolLoan = _getLendPoolLoan();
    cachedPoolLoan.purgeFlashLoanLocking(nftAddress, tokenIds, locker);
  }

  function getTokenImplementation(address proxyAddress) external view onlyPoolAdmin returns (address) {
    return ConfiguratorLogic.getTokenImplementation(proxyAddress);
  }

  function _checkReserveNoLiquidity(address asset) internal view {
    DataTypes.ReserveData memory reserveData = _getLendPool().getReserveData(asset);
    uint256 availableLiquidity;
    for(uint256 i = 0; i < reserveData.mTokenAddresses.length; i++) {
      availableLiquidity = availableLiquidity + IERC20Upgradeable(asset).balanceOf(reserveData.mTokenAddresses[i]);
      require(availableLiquidity == 0 && reserveData.currentLiquidityRates[i] == 0, Errors.LPC_RESERVE_LIQUIDITY_NOT_0);
    }
  }

  function _checkNftNoLiquidity(address asset) internal view {
    uint256 collateralAmount = _getLendPoolLoan().getNftCollateralAmount(asset);

    require(collateralAmount == 0, Errors.LPC_NFT_LIQUIDITY_NOT_0);
  }

  function _getLendPool() internal view returns (ILendPool) {
    return ILendPool(_addressesProvider.getLendPool());
  }

  function _getLendPoolLoan() internal view returns (ILendPoolLoan) {
    return ILendPoolLoan(_addressesProvider.getLendPoolLoan());
  }

  function _getBNFTRegistry() internal view returns (IBNFTRegistry) {
    return IBNFTRegistry(_addressesProvider.getBNFTRegistry());
  }
}
