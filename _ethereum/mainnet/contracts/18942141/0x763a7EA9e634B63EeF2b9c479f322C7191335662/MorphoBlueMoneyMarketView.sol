//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

import "./Math.sol";
import "./UD60x18.sol";

import "./IMorpho.sol";
import "./SharesMathLib.sol";

import "./BaseMoneyMarketView.sol";
import "./MorphoBlueReverseLookup.sol";

contract MorphoBlueMoneyMarketView is BaseMoneyMarketView {

    UD60x18 internal constant DAYS_PER_YEAR = UD60x18.wrap(365e18);
    UD60x18 internal constant SECONDS_PER_DAY = UD60x18.wrap(1 days * WAD);

    error OracleNotFound(IERC20 asset);

    using Math for *;
    using SharesMathLib for *;

    uint256 public constant ORACLE_PRICE_DECIMALS = 36;

    IMorpho public immutable morpho;
    MorphoBlueReverseLookup public immutable reverseLookup;

    constructor(
        MoneyMarketId _moneyMarketId,
        string memory _moneyMarketName,
        IContango _contango,
        IMorpho _morpho,
        MorphoBlueReverseLookup _reverseLookup,
        IWETH9 _nativeToken,
        IAggregatorV2V3 _nativeUsdOracle
    ) BaseMoneyMarketView(_moneyMarketId, _moneyMarketName, _contango, _nativeToken, _nativeUsdOracle) {
        morpho = _morpho;
        reverseLookup = _reverseLookup;
    }

    // ====== IMoneyMarketView =======

    function _balances(PositionId positionId, IERC20, IERC20) internal virtual override returns (Balances memory balances_) {
        MorphoMarketId marketId = reverseLookup.marketId(positionId.getPayload());
        MarketParams memory marketParams = morpho.idToMarketParams(marketId);
        morpho.accrueInterest(marketParams); // Accrue interest before before loading the market state
        Market memory market = morpho.market(marketId);
        Position memory position = morpho.position(marketId, _account(positionId));
        balances_.collateral = position.collateral;
        balances_.debt = position.borrowShares.toAssetsUp(market.totalBorrowAssets, market.totalBorrowShares);
    }

    function _prices(PositionId positionId, IERC20, IERC20) internal view virtual override returns (Prices memory prices_) {
        MarketParams memory params = morpho.idToMarketParams(reverseLookup.marketId(positionId.getPayload()));

        uint256 priceDecimals = ORACLE_PRICE_DECIMALS + params.loanToken.decimals() - params.collateralToken.decimals();

        prices_.collateral = params.oracle.price();
        prices_.debt = prices_.unit = 10 ** priceDecimals;
    }

    // Morpho's Oracles don't follow the pattern of returning the price of the base currency in USD or ETH
    // Instead, they return the price of the collateral in the loan token
    // So these 2 functions can't be implemented
    // The reason why they are not made to revert is because Solidity would thrown an "Unreachable code" error
    function _oraclePrice(IERC20 asset) internal view virtual override returns (uint256) { }
    function _oracleUnit() internal view virtual override returns (uint256) { }

    function priceInNativeToken(IERC20 asset) public view virtual override returns (uint256 price_) {
        uint256 nativeTokenDecimals = nativeToken.decimals();
        uint256 nativeTokenUnit = 10 ** nativeTokenDecimals;
        if (asset == nativeToken) return nativeTokenUnit;

        MorphoMarketId marketId = reverseLookup.assetToMarketId(asset);
        if (MorphoMarketId.unwrap(marketId) != bytes32(0)) {
            MarketParams memory params = morpho.idToMarketParams(marketId);
            uint256 priceDecimals = ORACLE_PRICE_DECIMALS + params.loanToken.decimals() - params.collateralToken.decimals();
            price_ = params.oracle.price();
            if (priceDecimals < 18) price_ *= 10 ** (18 - priceDecimals);
            if (priceDecimals > 18) price_ /= 10 ** (priceDecimals - 18);
            if (params.loanToken == nativeToken) return price_;
            asset = params.loanToken;
        }

        QuoteOracle memory quoteOracle = reverseLookup.assetToQuoteOracle(asset);
        if (quoteOracle.oracle == address(0)) revert OracleNotFound(asset);

        uint256 oraclePrice;
        if (quoteOracle.oracleType == "CHAINLINK") {
            oraclePrice = uint256(IAggregatorV2V3(quoteOracle.oracle).latestAnswer());
            uint256 oracleDecimals = uint256(IAggregatorV2V3(quoteOracle.oracle).decimals());
            if (oracleDecimals < 18) oraclePrice *= 10 ** (18 - oracleDecimals);
        }

        price_ = price_ > 0 ? price_ * oraclePrice / WAD : oraclePrice;

        if (quoteOracle.oracleCcy == QuoteOracleCcy.NATIVE) return price_;

        uint256 nativeAssetPrice = uint256(nativeUsdOracle.latestAnswer()) * 1e10;

        price_ = price_ * nativeTokenUnit / nativeAssetPrice;
    }

    function _thresholds(PositionId positionId, IERC20, IERC20)
        internal
        view
        virtual
        override
        returns (uint256 ltv, uint256 liquidationThreshold)
    {
        ltv = liquidationThreshold = morpho.idToMarketParams(reverseLookup.marketId(positionId.getPayload())).lltv;
    }

    function _liquidity(PositionId positionId, IERC20 collateralAsset, IERC20)
        internal
        view
        virtual
        override
        returns (uint256 borrowing, uint256 lending)
    {
        Market memory market = morpho.market(reverseLookup.marketId(positionId.getPayload()));
        borrowing = market.totalSupplyAssets - market.totalBorrowAssets;
        lending = collateralAsset.totalSupply();
    }

    function _rates(PositionId positionId, IERC20, IERC20) internal view virtual override returns (uint256 borrowing, uint256 lending) {
        MorphoMarketId marketId = reverseLookup.marketId(positionId.getPayload());
        MarketParams memory params = morpho.idToMarketParams(marketId);

        UD60x18 rate = ud(params.irm.borrowRateView(params, morpho.market(marketId))) * SECONDS_PER_DAY;
        borrowing = ((rate + UNIT).pow(DAYS_PER_YEAR) - UNIT).unwrap();
        lending = 0;
    }

}
