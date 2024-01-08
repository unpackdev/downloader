pragma solidity ^0.7.0;

interface ILendingPool {
    function deposit(
        address reserve,
        uint256 amount,
        uint16 referralCode
    ) external payable;

    function borrow(
        address reserve,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode
    ) external;

    function repay(
        address _reserve,
        uint256 amount,
        address payable onBehalfOf
    ) external payable;

    function rebalanceStableBorrowRate(address reserve, address user) external;

    function getReserveData(address reserve)
        external
        view
        returns (
            uint256 totalLiquidity,
            uint256 availableLiquidity,
            uint256 totalBorrowsStable,
            uint256 totalBorrowsVariable,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 utilizationRate
            // uint256 liquidityIndex,
            // uint256 variableBorrowIndex,
            // address aTokenAddress,
            // uint40 lastUpdateTimestamp
        );

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalLiquidityETH,
            uint256 totalCollateralETH,
            uint256 totalBorrowsETH,
            uint256 totalFeesETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserReserveData(address reserve, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentBorrowBalance,
            uint256 principalBorrowBalance
            // uint256 borrowRateMode,
            // uint256 borrowRate,
            // uint256 liquidityRate,
            // uint256 originationFee,
            // uint256 variableBorrowIndex,
            // uint256 lastUpdateTimestamp,
            // bool usageAsCollateralEnabled
        );

    function setUserUseReserveAsCollateral(
        address _reserve,
        bool _useAsCollateral
    ) external;
}
