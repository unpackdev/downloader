pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;


interface IFetchAaveDataWrapper {
    struct ReserveConfigData {
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        bool usageAsCollateralEnabled;
        bool borrowingEnabled;
        bool stableBorrowRateEnabled;
        bool isActive;
        address aTokenAddress;
    }

    struct ReserveData {
        uint256 availableLiquidity;
        uint256 totalBorrowsStable;
        uint256 totalBorrowsVariable;
        uint256 liquidityRate;
        uint256 variableBorrowRate;
        uint256 stableBorrowRate;
        uint256 averageStableBorrowRate;
        uint256 totalLiquidity;
        uint256 utilizationRate;
    }

    struct UserAccountData {
        uint256 totalLiquidityETH; // only v1
        uint256 totalCollateralETH;
        uint256 totalBorrowsETH;
        uint256 totalFeesETH; // only v1
        uint256 availableBorrowsETH;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
    }

    struct UserReserveData {
        uint256 currentATokenBalance;
        uint256 liquidityRate;
        uint256 poolShareInPrecision;
        bool usageAsCollateralEnabled;
        // v1 data
        uint256 currentBorrowBalance;
        uint256 principalBorrowBalance;
        uint256 borrowRateMode;
        uint256 borrowRate;
        uint256 originationFee;
        // v2 data
        uint256 currentStableDebt;
        uint256 currentVariableDebt;
        uint256 principalStableDebt;
        uint256 scaledVariableDebt;
        uint256 stableBorrowRate;
    }

    function getReserves(address pool, bool isV1) external view returns (address[] memory);
    function getReservesConfigurationData(address pool, bool isV1, address[] calldata _reserves)
        external
        view
        returns (
            ReserveConfigData[] memory configsData
        );

    function getReservesData(address pool, bool isV1, address[] calldata _reserves)
        external
        view
        returns (
            ReserveData[] memory reservesData
        );

    function getUserAccountsData(address pool, bool isV1, address[] calldata _users)
        external
        view
        returns (
            UserAccountData[] memory accountsData
        );

    function getUserReservesData(address pool, bool isV1, address[] calldata _reserves, address _user)
        external
        view
        returns (
            UserReserveData[] memory userReservesData
        );

    function getUsersReserveData(address pool, bool isV1, address _reserve, address[] calldata _users)
        external
        view
        returns (
            UserReserveData[] memory userReservesData
        );
}
