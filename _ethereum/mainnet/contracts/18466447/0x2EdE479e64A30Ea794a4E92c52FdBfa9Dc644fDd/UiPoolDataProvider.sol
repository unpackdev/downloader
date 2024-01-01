// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.12;
pragma experimental ABIEncoderV2;

import "./IERC20Metadata.sol";
import "./ILendingPoolAddressesProvider.sol";
import "./IAaveIncentivesController.sol";
import "./IUiPoolDataProvider.sol";
import "./ILendingPool.sol";
import "./IPriceOracleGetter.sol";
import "./IAToken.sol";
import "./IVariableDebtToken.sol";
import "./IStableDebtToken.sol";
import "./WadRayMath.sol";
import "./ReserveConfiguration.sol";
import "./UserConfiguration.sol";
import "./DataTypes.sol";
import "./DefaultReserveInterestRateStrategy.sol";

contract UiPoolDataProvider is IUiPoolDataProvider {
	using WadRayMath for uint256;
	using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
	using UserConfiguration for DataTypes.UserConfigurationMap;

	address public constant MOCK_USD_ADDRESS = 0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96;
	IAaveIncentivesController public immutable incentivesController;
	IPriceOracleGetter public immutable oracle;

	constructor(IAaveIncentivesController _incentivesController, IPriceOracleGetter _oracle) {
		incentivesController = _incentivesController;
		oracle = _oracle;
	}

	function getInterestRateStrategySlopes(
		DefaultReserveInterestRateStrategy interestRateStrategy
	) internal view returns (uint256, uint256, uint256, uint256) {
		return (
			interestRateStrategy.variableRateSlope1(),
			interestRateStrategy.variableRateSlope2(),
			interestRateStrategy.stableRateSlope1(),
			interestRateStrategy.stableRateSlope2()
		);
	}

	function getReservesData(
		ILendingPoolAddressesProvider provider,
		address user
	)
		external
		view
		returns (AggregatedReserveData[] memory, UserReserveData[] memory, uint256, IncentivesControllerData memory)
	{
		ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
		address[] memory reserves = lendingPool.getReservesList();
		DataTypes.UserConfigurationMap memory userConfig = lendingPool.getUserConfiguration(user);

		AggregatedReserveData[] memory reservesData = new AggregatedReserveData[](reserves.length);
		UserReserveData[] memory userReservesData = new UserReserveData[](user != address(0) ? reserves.length : 0);

		for (uint256 i = 0; i < reserves.length; ) {
			AggregatedReserveData memory reserveData = reservesData[i];
			reserveData.underlyingAsset = reserves[i];

			// reserve current state
			DataTypes.ReserveData memory baseData = lendingPool.getReserveData(reserveData.underlyingAsset);
			reserveData.liquidityIndex = baseData.liquidityIndex;
			reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
			reserveData.liquidityRate = baseData.currentLiquidityRate;
			reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
			reserveData.stableBorrowRate = baseData.currentStableBorrowRate;
			reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
			reserveData.aTokenAddress = baseData.aTokenAddress;
			reserveData.stableDebtTokenAddress = baseData.stableDebtTokenAddress;
			reserveData.variableDebtTokenAddress = baseData.variableDebtTokenAddress;
			reserveData.interestRateStrategyAddress = baseData.interestRateStrategyAddress;
			reserveData.priceInEth = oracle.getAssetPrice(reserveData.underlyingAsset);

			reserveData.availableLiquidity = IERC20Metadata(reserveData.underlyingAsset).balanceOf(
				reserveData.aTokenAddress
			);
			(
				reserveData.totalPrincipalStableDebt,
				,
				reserveData.averageStableRate,
				reserveData.stableDebtLastUpdateTimestamp
			) = IStableDebtToken(reserveData.stableDebtTokenAddress).getSupplyData();
			reserveData.totalScaledVariableDebt = IVariableDebtToken(reserveData.variableDebtTokenAddress)
				.scaledTotalSupply();

			// reserve configuration

			// we're getting this info from the aToken, because some of assets can be not compliant with ETC20Detailed
			reserveData.symbol = IERC20Metadata(reserveData.aTokenAddress).symbol();
			reserveData.name = "";

			(
				reserveData.baseLTVasCollateral,
				reserveData.reserveLiquidationThreshold,
				reserveData.reserveLiquidationBonus,
				reserveData.decimals,
				reserveData.reserveFactor
			) = baseData.configuration.getParamsMemory();
			(
				reserveData.isActive,
				reserveData.isFrozen,
				reserveData.borrowingEnabled,
				reserveData.stableBorrowRateEnabled
			) = baseData.configuration.getFlagsMemory();
			reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;
			(
				reserveData.variableRateSlope1,
				reserveData.variableRateSlope2,
				reserveData.stableRateSlope1,
				reserveData.stableRateSlope2
			) = getInterestRateStrategySlopes(
				DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress)
			);

			// incentives
			if (address(0) != address(incentivesController)) {
				(
					reserveData.aTokenIncentivesIndex,
					reserveData.aEmissionPerSecond,
					reserveData.aIncentivesLastUpdateTimestamp
				) = incentivesController.getAssetData(reserveData.aTokenAddress);

				(
					reserveData.sTokenIncentivesIndex,
					reserveData.sEmissionPerSecond,
					reserveData.sIncentivesLastUpdateTimestamp
				) = incentivesController.getAssetData(reserveData.stableDebtTokenAddress);

				(
					reserveData.vTokenIncentivesIndex,
					reserveData.vEmissionPerSecond,
					reserveData.vIncentivesLastUpdateTimestamp
				) = incentivesController.getAssetData(reserveData.variableDebtTokenAddress);
			}

			if (user != address(0)) {
				// incentives
				if (address(0) != address(incentivesController)) {
					userReservesData[i].aTokenincentivesUserIndex = incentivesController.getUserAssetData(
						user,
						reserveData.aTokenAddress
					);
					userReservesData[i].vTokenincentivesUserIndex = incentivesController.getUserAssetData(
						user,
						reserveData.variableDebtTokenAddress
					);
					userReservesData[i].sTokenincentivesUserIndex = incentivesController.getUserAssetData(
						user,
						reserveData.stableDebtTokenAddress
					);
				}
				// user reserve data
				userReservesData[i].underlyingAsset = reserveData.underlyingAsset;
				userReservesData[i].scaledATokenBalance = IAToken(reserveData.aTokenAddress).scaledBalanceOf(user);
				userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(i);

				if (userConfig.isBorrowing(i)) {
					userReservesData[i].scaledVariableDebt = IVariableDebtToken(reserveData.variableDebtTokenAddress)
						.scaledBalanceOf(user);
					userReservesData[i].principalStableDebt = IStableDebtToken(reserveData.stableDebtTokenAddress)
						.principalBalanceOf(user);
					if (userReservesData[i].principalStableDebt != 0) {
						userReservesData[i].stableBorrowRate = IStableDebtToken(reserveData.stableDebtTokenAddress)
							.getUserStableRate(user);
						userReservesData[i].stableBorrowLastUpdateTimestamp = IStableDebtToken(
							reserveData.stableDebtTokenAddress
						).getUserLastUpdated(user);
					}
				}
			}
			unchecked {
				i++;
			}
		}

		IncentivesControllerData memory incentivesControllerData;

		if (address(0) != address(incentivesController)) {
			if (user != address(0)) {
				incentivesControllerData.userUnclaimedRewards = incentivesController.getUserUnclaimedRewards(user);
			}
			incentivesControllerData.emissionEndTimestamp = incentivesController.DISTRIBUTION_END();
		}

		return (reservesData, userReservesData, 10 ** 8, incentivesControllerData);
	}
}
