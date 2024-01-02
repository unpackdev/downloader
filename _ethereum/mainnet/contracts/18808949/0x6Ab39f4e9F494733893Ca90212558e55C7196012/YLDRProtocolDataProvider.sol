// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import "./IERC20Metadata.sol";
import "./ReserveConfiguration.sol";
import "./UserConfiguration.sol";
import "./DataTypes.sol";
import "./WadRayMath.sol";
import "./IPoolAddressesProvider.sol";
import "./IVariableDebtToken.sol";
import "./IPool.sol";
import "./IPoolDataProvider.sol";

/**
 * @title YLDRProtocolDataProvider
 *
 * @notice Peripheral contract to collect and pre-process information from the Pool.
 */
contract YLDRProtocolDataProvider is IPoolDataProvider {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using WadRayMath for uint256;

    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @inheritdoc IPoolDataProvider
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /**
     * @notice Constructor
     * @param addressesProvider The address of the PoolAddressesProvider contract
     */
    constructor(IPoolAddressesProvider addressesProvider) {
        ADDRESSES_PROVIDER = addressesProvider;
    }

    /// @inheritdoc IPoolDataProvider
    function getAllReservesTokens() external view override returns (TokenData[] memory) {
        IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
        address[] memory reserves = pool.getReservesList();
        TokenData[] memory reservesTokens = new TokenData[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            if (reserves[i] == MKR) {
                reservesTokens[i] = TokenData({symbol: "MKR", tokenAddress: reserves[i]});
                continue;
            }
            if (reserves[i] == ETH) {
                reservesTokens[i] = TokenData({symbol: "ETH", tokenAddress: reserves[i]});
                continue;
            }
            reservesTokens[i] = TokenData({symbol: IERC20Metadata(reserves[i]).symbol(), tokenAddress: reserves[i]});
        }
        return reservesTokens;
    }

    /// @inheritdoc IPoolDataProvider
    function getAllYTokens() external view override returns (TokenData[] memory) {
        IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
        address[] memory reserves = pool.getReservesList();
        TokenData[] memory yTokens = new TokenData[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory reserveData = pool.getReserveData(reserves[i]);
            yTokens[i] = TokenData({
                symbol: IERC20Metadata(reserveData.yTokenAddress).symbol(),
                tokenAddress: reserveData.yTokenAddress
            });
        }
        return yTokens;
    }

    /// @inheritdoc IPoolDataProvider
    function getReserveConfigurationData(address asset)
        external
        view
        override
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool isActive,
            bool isFrozen
        )
    {
        DataTypes.ReserveConfigurationMap memory configuration =
            IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset);

        (ltv, liquidationThreshold, liquidationBonus, decimals, reserveFactor) = configuration.getParams();

        (isActive, isFrozen, borrowingEnabled,) = configuration.getFlags();

        usageAsCollateralEnabled = liquidationThreshold != 0;
    }

    /// @inheritdoc IPoolDataProvider
    function getReserveCaps(address asset) external view override returns (uint256 borrowCap, uint256 supplyCap) {
        (borrowCap, supplyCap) = IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getCaps();
    }

    /// @inheritdoc IPoolDataProvider
    function getPaused(address asset) external view override returns (bool isPaused) {
        (,,, isPaused) = IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getFlags();
    }

    /// @inheritdoc IPoolDataProvider
    function getLiquidationProtocolFee(address asset) external view override returns (uint256) {
        return IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getLiquidationProtocolFee();
    }

    /// @inheritdoc IPoolDataProvider
    function getReserveData(address asset)
        external
        view
        override
        returns (
            uint256 accruedToTreasuryScaled,
            uint256 totalYToken,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        )
    {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);

        return (
            reserve.accruedToTreasury,
            IERC20Metadata(reserve.yTokenAddress).totalSupply(),
            IERC20Metadata(reserve.variableDebtTokenAddress).totalSupply(),
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.lastUpdateTimestamp
        );
    }

    /// @inheritdoc IPoolDataProvider
    function getYTokenTotalSupply(address asset) external view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);
        return IERC20Metadata(reserve.yTokenAddress).totalSupply();
    }

    /// @inheritdoc IPoolDataProvider
    function getTotalDebt(address asset) external view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);
        return IERC20Metadata(reserve.variableDebtTokenAddress).totalSupply();
    }

    /// @inheritdoc IPoolDataProvider
    function getUserReserveData(address asset, address user)
        external
        view
        override
        returns (
            uint256 currentYTokenBalance,
            uint256 currentVariableDebt,
            uint256 scaledVariableDebt,
            uint256 liquidityRate,
            bool usageAsCollateralEnabled
        )
    {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);

        DataTypes.UserConfigurationMap memory userConfig =
            IPool(ADDRESSES_PROVIDER.getPool()).getUserConfiguration(user);

        currentYTokenBalance = IERC20Metadata(reserve.yTokenAddress).balanceOf(user);
        currentVariableDebt = IERC20Metadata(reserve.variableDebtTokenAddress).balanceOf(user);
        scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
        liquidityRate = reserve.currentLiquidityRate;
        usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);
    }

    /// @inheritdoc IPoolDataProvider
    function getReserveTokensAddresses(address asset)
        external
        view
        override
        returns (address yTokenAddress, address variableDebtTokenAddress)
    {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);

        return (reserve.yTokenAddress, reserve.variableDebtTokenAddress);
    }

    /// @inheritdoc IPoolDataProvider
    function getInterestRateStrategyAddress(address asset) external view override returns (address irStrategyAddress) {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);

        return (reserve.interestRateStrategyAddress);
    }

    /// @inheritdoc IPoolDataProvider
    function getFlashLoanEnabled(address asset) external view override returns (bool) {
        DataTypes.ReserveConfigurationMap memory configuration =
            IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset);

        return configuration.getFlashLoanEnabled();
    }
}
