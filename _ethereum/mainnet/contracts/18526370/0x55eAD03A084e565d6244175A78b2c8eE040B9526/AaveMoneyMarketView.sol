//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./Math.sol";

import "./IAaveOracle.sol";
import "./IPool.sol";
import "./IPoolAddressesProvider.sol";
import "./IPoolDataProvider.sol";

import "./IMoneyMarketView.sol";
import "./IUnderlyingPositionFactory.sol";
import "./Arrays.sol";

contract AaveMoneyMarketView is IMoneyMarketView {

    error OracleBaseCurrencyNotUSD();

    using Math for *;

    MoneyMarketId public immutable override moneyMarketId;
    IPool public immutable pool;
    IPoolDataProvider public immutable dataProvider;
    IAaveOracle public immutable oracle;

    IUnderlyingPositionFactory public immutable positionFactory;

    constructor(
        MoneyMarketId _moneyMarketId,
        IPool _pool,
        IPoolDataProvider _dataProvider,
        IAaveOracle _oracle,
        IUnderlyingPositionFactory _positionFactory
    ) {
        moneyMarketId = _moneyMarketId;
        pool = _pool;
        dataProvider = _dataProvider;
        oracle = _oracle;
        positionFactory = _positionFactory;
    }

    // ====== IMoneyMarketView =======

    function balances(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset)
        public
        view
        virtual
        override
        returns (Balances memory balances_)
    {
        address account = _account(positionId);
        (balances_.collateral,,,,,,,,) = dataProvider.getUserReserveData(address(collateralAsset), account);
        (,, balances_.debt,,,,,,) = dataProvider.getUserReserveData(address(debtAsset), account);
    }

    function prices(PositionId, IERC20 collateralAsset, IERC20 debtAsset) public view virtual override returns (Prices memory prices_) {
        uint256[] memory pricesArr = oracle.getAssetsPrices(toArray(address(collateralAsset), address(debtAsset)));

        prices_.collateral = pricesArr[0];
        prices_.debt = pricesArr[1];
        prices_.unit = _oracleUnit();
    }

    function _oracleUnit() internal view virtual returns (uint256) {
        return oracle.BASE_CURRENCY_UNIT();
    }

    function thresholds(PositionId positionId, IERC20 collateralAsset, IERC20 debtAsset)
        public
        view
        virtual
        override
        returns (uint256 ltv, uint256 liquidationThreshold)
    {
        uint256 eModeCategory =
            positionId.getNumber() > 0 ? pool.getUserEMode(_account(positionId)) : _eModeCategory(collateralAsset, debtAsset);

        if (eModeCategory > 0) {
            AaveDataTypes.EModeCategory memory eModeCategoryData = pool.getEModeCategoryData(uint8(eModeCategory));
            ltv = eModeCategoryData.ltv;
            liquidationThreshold = eModeCategoryData.liquidationThreshold;
        } else {
            (, ltv, liquidationThreshold,,,,,,,) = dataProvider.getReserveConfigurationData(address(collateralAsset));
        }

        ltv *= 1e14;
        liquidationThreshold *= 1e14;
    }

    function liquidity(PositionId, IERC20 collateralAsset, IERC20 debtAsset)
        public
        view
        virtual
        returns (uint256 borrowing, uint256 lending)
    {
        borrowing = _borrowingLiquidity(debtAsset);
        lending = _lendingLiquidity(collateralAsset);

        uint256 debtCeiling = dataProvider.getDebtCeiling(address(collateralAsset));
        if (debtCeiling > 0) {
            if (oracle.BASE_CURRENCY() != address(0)) revert OracleBaseCurrencyNotUSD();
            uint256 debtAssetPrice = oracle.getAssetPrice(address(debtAsset));

            uint256 available = (debtCeiling - pool.getReserveData(address(collateralAsset)).isolationModeTotalDebt)
                * (oracle.BASE_CURRENCY_UNIT() / (10 ** dataProvider.getDebtCeilingDecimals()));

            borrowing = Math.min(borrowing, available * 10 ** debtAsset.decimals() / debtAssetPrice);
        }
    }

    function rates(PositionId, IERC20 collateralAsset, IERC20 debtAsset) public view virtual returns (uint256 borrowing, uint256 lending) {
        borrowing = pool.getReserveData(address(debtAsset)).currentVariableBorrowRate / 1e9;
        lending = pool.getReserveData(address(collateralAsset)).currentLiquidityRate / 1e9;
    }

    // ===== Internal Helper Functions =====

    function _borrowingLiquidity(IERC20 asset) internal view virtual returns (uint256 borrowingLiquidity_) {
        (uint256 borrowCap,) = dataProvider.getReserveCaps(address(asset));
        borrowCap = borrowCap * 10 ** asset.decimals();
        uint256 totalDebt = dataProvider.getTotalDebt(address(asset));

        uint256 maxBorrowable = borrowCap > totalDebt ? borrowCap - totalDebt : 0;
        (address aTokenAddress,,) = dataProvider.getReserveTokensAddresses(address(asset));
        uint256 available = asset.balanceOf(aTokenAddress);

        borrowingLiquidity_ = borrowCap == 0 ? available : Math.min(maxBorrowable, available);
    }

    function _lendingLiquidity(IERC20 asset) internal view virtual returns (uint256 lendingLiquidity_) {
        (uint256 decimals,,,,, bool usageAsCollateralEnabled,,,,) = dataProvider.getReserveConfigurationData(address(asset));
        if (!usageAsCollateralEnabled) return 0;

        (, uint256 supplyCap) = dataProvider.getReserveCaps(address(asset));
        if (supplyCap == 0) return type(uint256).max; // Infinite supply cap

        supplyCap = supplyCap * 10 ** decimals;
        uint256 currentSupply = dataProvider.getATokenTotalSupply(address(asset));

        lendingLiquidity_ = supplyCap > currentSupply ? supplyCap - currentSupply : 0;
    }

    function _eModeCategory(IERC20 collateralAsset, IERC20 debtAsset) internal view returns (uint256 eModeCategory) {
        uint256 collateralEModeCategory = dataProvider.getReserveEModeCategory(address(collateralAsset));
        if (collateralEModeCategory > 0 && collateralEModeCategory == dataProvider.getReserveEModeCategory(address(debtAsset))) {
            eModeCategory = collateralEModeCategory;
        }
    }

    function _account(PositionId positionId) internal view returns (address) {
        return address(positionFactory.moneyMarket(positionId));
    }

}
