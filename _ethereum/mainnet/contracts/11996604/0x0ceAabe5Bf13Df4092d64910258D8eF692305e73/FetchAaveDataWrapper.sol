pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

import "./ILendingPoolV1.sol";
import "./ILendingPoolV2.sol";
import "./IFetchAaveDataWrapper.sol";
import "./ILendingPoolCore.sol";
import "./Withdrawable.sol";
import "./IERC20Ext.sol";


/// Fetch data for multiple users or reserves from AAVE
/// Checkout list deployed AAVE's contracts here
/// https://docs.aave.com/developers/deployed-contracts/deployed-contract-instances
contract FetchAaveDataWrapper is Withdrawable, IFetchAaveDataWrapper {
    uint256 internal constant PRECISION = 10**18;
    uint256 internal constant RATE_PRECISION = 10**27;

    constructor(address _admin) public Withdrawable(_admin) {}

    function getReserves(address pool, bool isV1)
        external
        view
        override
        returns (address[] memory reserves)
    {
        if (isV1) {
            return ILendingPoolV1(pool).getReserves();
        }
        return ILendingPoolV2(pool).getReservesList();
    }

    function getReservesConfigurationData(
        address pool,
        bool isV1,
        address[] calldata _reserves
    ) external view override returns (ReserveConfigData[] memory configsData) {
        configsData = new ReserveConfigData[](_reserves.length);
        for (uint256 i = 0; i < _reserves.length; i++) {
            if (isV1) {
                (
                    configsData[i].ltv,
                    configsData[i].liquidationThreshold,
                    configsData[i].liquidationBonus, // rate strategy address
                    ,
                    configsData[i].usageAsCollateralEnabled,
                    configsData[i].borrowingEnabled,
                    configsData[i].stableBorrowRateEnabled,
                    configsData[i].isActive
                ) = ILendingPoolV1(pool).getReserveConfigurationData(_reserves[i]);
                configsData[i].aTokenAddress = ILendingPoolCore(ILendingPoolV1(pool).core())
                    .getReserveATokenAddress(_reserves[i]);
            } else {
                IProtocolDataProvider provider = IProtocolDataProvider(pool);
                (
                    ,
                    // decimals
                    configsData[i].ltv,
                    configsData[i].liquidationThreshold,
                    configsData[i].liquidationBonus, // reserve factor
                    ,
                    configsData[i].usageAsCollateralEnabled,
                    configsData[i].borrowingEnabled,
                    configsData[i].stableBorrowRateEnabled,
                    configsData[i].isActive,

                ) = provider.getReserveConfigurationData(_reserves[i]);
                (configsData[i].aTokenAddress, , ) = provider.getReserveTokensAddresses(
                    _reserves[i]
                );
            }
        }
    }

    function getReservesData(
        address pool,
        bool isV1,
        address[] calldata _reserves
    ) external view override returns (ReserveData[] memory reservesData) {
        reservesData = new ReserveData[](_reserves.length);
        if (isV1) {
            ILendingPoolCore core = ILendingPoolCore(ILendingPoolV1(pool).core());
            for (uint256 i = 0; i < _reserves.length; i++) {
                reservesData[i].totalLiquidity = core.getReserveTotalLiquidity(_reserves[i]);
                reservesData[i].availableLiquidity = core.getReserveAvailableLiquidity(
                    _reserves[i]
                );
                reservesData[i].utilizationRate = core.getReserveUtilizationRate(_reserves[i]);
                reservesData[i].liquidityRate = core.getReserveCurrentLiquidityRate(_reserves[i]);

                reservesData[i].totalBorrowsStable = core.getReserveTotalBorrowsStable(
                    _reserves[i]
                );
                reservesData[i].totalBorrowsVariable = core.getReserveTotalBorrowsVariable(
                    _reserves[i]
                );

                reservesData[i].variableBorrowRate = core.getReserveCurrentVariableBorrowRate(
                    _reserves[i]
                );
                reservesData[i].stableBorrowRate = core.getReserveCurrentStableBorrowRate(
                    _reserves[i]
                );
                reservesData[i].averageStableBorrowRate = core
                    .getReserveCurrentAverageStableBorrowRate(_reserves[i]);
            }
        } else {
            IProtocolDataProvider provider = IProtocolDataProvider(pool);
            for (uint256 i = 0; i < _reserves.length; i++) {
                (
                    reservesData[i].availableLiquidity,
                    reservesData[i].totalBorrowsStable,
                    reservesData[i].totalBorrowsVariable,
                    reservesData[i].liquidityRate,
                    reservesData[i].variableBorrowRate,
                    reservesData[i].stableBorrowRate,
                    reservesData[i].averageStableBorrowRate,
                    ,
                    ,

                ) = provider.getReserveData(_reserves[i]);
                (address aTokenAddress, , ) = provider.getReserveTokensAddresses(_reserves[i]);
                reservesData[i].availableLiquidity = IERC20Ext(_reserves[i]).balanceOf(
                    aTokenAddress
                );

                reservesData[i].totalLiquidity =
                    reservesData[i].availableLiquidity +
                    reservesData[i].totalBorrowsStable +
                    reservesData[i].totalBorrowsVariable;
                if (reservesData[i].totalLiquidity > 0) {
                    reservesData[i].utilizationRate =
                        RATE_PRECISION -
                        (reservesData[i].availableLiquidity * RATE_PRECISION) /
                        reservesData[i].totalLiquidity;
                }
            }
        }
    }

    function getUserAccountsData(
        address pool,
        bool isV1,
        address[] calldata _users
    ) external view override returns (UserAccountData[] memory accountsData) {
        accountsData = new UserAccountData[](_users.length);

        for (uint256 i = 0; i < _users.length; i++) {
            accountsData[i] = getSingleUserAccountData(pool, isV1, _users[i]);
        }
    }

    function getUserReservesData(
        address pool,
        bool isV1,
        address[] calldata _reserves,
        address _user
    ) external view override returns (UserReserveData[] memory userReservesData) {
        userReservesData = new UserReserveData[](_reserves.length);
        for (uint256 i = 0; i < _reserves.length; i++) {
            if (isV1) {
                userReservesData[i] = getSingleUserReserveDataV1(
                    ILendingPoolV1(pool),
                    _reserves[i],
                    _user
                );
            } else {
                userReservesData[i] = getSingleUserReserveDataV2(
                    IProtocolDataProvider(pool),
                    _reserves[i],
                    _user
                );
            }
        }
    }

    function getUsersReserveData(
        address pool,
        bool isV1,
        address _reserve,
        address[] calldata _users
    ) external view override returns (UserReserveData[] memory userReservesData) {
        userReservesData = new UserReserveData[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            if (isV1) {
                userReservesData[i] = getSingleUserReserveDataV1(
                    ILendingPoolV1(pool),
                    _reserve,
                    _users[i]
                );
            } else {
                userReservesData[i] = getSingleUserReserveDataV2(
                    IProtocolDataProvider(pool),
                    _reserve,
                    _users[i]
                );
            }
        }
    }

    function getSingleUserReserveDataV1(
        ILendingPoolV1 pool,
        address _reserve,
        address _user
    ) public view returns (UserReserveData memory data) {
        (
            data.currentATokenBalance,
            data.currentBorrowBalance,
            data.principalBorrowBalance,
            data.borrowRateMode,
            data.borrowRate,
            data.liquidityRate,
            data.originationFee,
            ,
            ,
            data.usageAsCollateralEnabled
        ) = pool.getUserReserveData(_reserve, _user);
        IERC20Ext aToken =
            IERC20Ext(ILendingPoolCore(pool.core()).getReserveATokenAddress(_reserve));
        uint256 totalSupply = aToken.totalSupply();
        if (totalSupply > 0) {
            data.poolShareInPrecision = aToken.balanceOf(_user) * RATE_PRECISION / totalSupply;
        }
    }

    function getSingleUserReserveDataV2(
        IProtocolDataProvider provider,
        address _reserve,
        address _user
    ) public view returns (UserReserveData memory data) {
        {
            (
                data.currentATokenBalance,
                data.currentStableDebt,
                data.currentVariableDebt,
                data.principalStableDebt,
                data.scaledVariableDebt,
                data.stableBorrowRate,
                data.liquidityRate,
                ,
                data.usageAsCollateralEnabled
            ) = provider.getUserReserveData(_reserve, _user);
        }
        {
            (address aTokenAddress, , ) = provider.getReserveTokensAddresses(_reserve);
            uint256 totalSupply = IERC20Ext(aTokenAddress).totalSupply();
            if (totalSupply > 0) {
                data.poolShareInPrecision =
                    IERC20Ext(aTokenAddress).balanceOf(_user) * RATE_PRECISION /
                    totalSupply;
            }
        }
    }

    function getSingleUserAccountData(
        address pool,
        bool isV1,
        address _user
    ) public view returns (UserAccountData memory data) {
        if (isV1) {
            (
                data.totalLiquidityETH,
                data.totalCollateralETH,
                data.totalBorrowsETH,
                data.totalFeesETH,
                data.availableBorrowsETH,
                data.currentLiquidationThreshold,
                data.ltv,
                data.healthFactor
            ) = ILendingPoolV1(pool).getUserAccountData(_user);
            return data;
        }
        (
            data.totalCollateralETH,
            data.totalBorrowsETH,
            data.availableBorrowsETH,
            data.currentLiquidationThreshold,
            data.ltv,
            data.healthFactor
        ) = ILendingPoolV2(pool).getUserAccountData(_user);
    }
}
