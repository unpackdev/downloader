// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./AggregatorV3Interface.sol";
import "./IERC20Metadata.sol";
import "./IERC165.sol";
import "./WadRayMath.sol";

import "./PrimexPricingLibrary.sol";
import "./PositionLibrary.sol";
import "./LimitOrderLibrary.sol";
import "./Errors.sol";

import "./IPositionManager.sol";
import "./IPrimexDNS.sol";
import "./IPriceOracle.sol";
import "./IConditionalClosingManager.sol";
import "./ITakeProfitStopLossCCM.sol";

contract TakeProfitStopLossCCM is IConditionalClosingManager, ITakeProfitStopLossCCM, IERC165 {
    using WadRayMath for uint256;

    uint256 private constant CM_TYPE = 2;

    address public immutable primexDNS;
    address public immutable priceOracle;

    constructor(address _primexDNS, address _priceOracle) {
        _require(
            IERC165(address(_primexDNS)).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        primexDNS = _primexDNS;
        priceOracle = _priceOracle;
    }

    /**
     * @inheritdoc IConditionalClosingManager
     */
    function canBeClosedBeforeSwap(
        PositionLibrary.Position calldata _position,
        bytes calldata _params,
        bytes calldata _additionalParams
    ) external override returns (bool) {
        if (_params.length == 0) return false;
        CanBeClosedParams memory params = abi.decode(_params, (CanBeClosedParams));
        if (_additionalParams.length > 0) {
            AdditionalParams memory additionalParams = abi.decode(_additionalParams, (AdditionalParams));
            return isTakeProfitReached(_position, params.takeProfitPrice, additionalParams.routes);
        }
        return isStopLossReached(_position, params.stopLossPrice);
    }

    /**
     * @inheritdoc IConditionalClosingManager
     */
    function canBeClosedAfterSwap(
        PositionLibrary.Position calldata _position,
        bytes calldata _params,
        bytes calldata,
        uint256 _closeAmount,
        uint256 _borowedAssetAmount
    ) external view override returns (bool) {
        if (_params.length == 0) return false;
        uint256 multiplierAssetOut = 10 ** (18 - IERC20Metadata(_position.soldAsset).decimals());
        uint256 multiplierAssetIn = 10 ** (18 - IERC20Metadata(_position.positionAsset).decimals());
        uint256 exchangeRate = (_borowedAssetAmount * multiplierAssetOut).wdiv(_closeAmount * multiplierAssetIn) /
            multiplierAssetOut;
        CanBeClosedParams memory params = abi.decode(_params, (CanBeClosedParams));
        return ((params.takeProfitPrice > 0 && exchangeRate >= params.takeProfitPrice) ||
            isStopLossReached(_position, params.stopLossPrice));
    }

    /**
     * @inheritdoc ITakeProfitStopLossCCM
     */
    function isTakeProfitReached(
        PositionLibrary.Position calldata _position,
        uint256 takeProfitPrice,
        PrimexPricingLibrary.Route[] memory routes
    ) public override returns (bool) {
        (, uint256 takeProfitAmount) = _calcTakeProfitStopLossAmounts(
            _position.positionAsset,
            _position.soldAsset,
            _position.positionAmount,
            0,
            takeProfitPrice
        );

        if (takeProfitAmount > 0) {
            return
                takeProfitAmount <=
                PrimexPricingLibrary.getAmountOut(
                    PrimexPricingLibrary.AmountParams({
                        tokenA: _position.positionAsset,
                        tokenB: _position.soldAsset,
                        amount: _position.positionAmount,
                        routes: routes,
                        dexAdapter: IPrimexDNS(primexDNS).dexAdapter(),
                        primexDNS: primexDNS
                    })
                );
        }
        return false;
    }

    /**
     * @inheritdoc ITakeProfitStopLossCCM
     */
    function isStopLossReached(
        PositionLibrary.Position calldata _position,
        uint256 stopLossPrice
    ) public view override returns (bool) {
        if (stopLossPrice == 0) return false;
        (uint256 exchangeRate, bool isForward) = IPriceOracle(priceOracle).getExchangeRate(
            _position.positionAsset,
            _position.soldAsset
        );
        return isForward ? stopLossPrice >= exchangeRate : stopLossPrice >= WadRayMath.WAD.wdiv(exchangeRate);
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IERC165).interfaceId ||
            _interfaceId == type(IConditionalClosingManager).interfaceId ||
            _interfaceId == type(ITakeProfitStopLossCCM).interfaceId;
    }

    /**
     * @inheritdoc ITakeProfitStopLossCCM
     */
    function isTakeProfitReached(bytes calldata _params, uint256 exchangeRate) public pure override returns (bool) {
        CanBeClosedParams memory params = abi.decode(_params, (CanBeClosedParams));
        return params.takeProfitPrice > 0 && params.takeProfitPrice <= exchangeRate;
    }

    /**
     * @inheritdoc ITakeProfitStopLossCCM
     */
    function isStopLossReached(bytes calldata _params, uint256 oracleExchangeRate) public pure override returns (bool) {
        CanBeClosedParams memory params = abi.decode(_params, (CanBeClosedParams));
        return params.stopLossPrice >= oracleExchangeRate;
    }

    /**
     * @inheritdoc ITakeProfitStopLossCCM
     */
    function getTakeProfitStopLossPrices(bytes calldata _params) public pure override returns (uint256, uint256) {
        CanBeClosedParams memory params;
        if (_params.length > 0) {
            params = abi.decode(_params, (CanBeClosedParams));
        }
        return (params.takeProfitPrice, params.stopLossPrice);
    }

    /**
     * @notice Calculates the stop loss and take profit amounts based on the provided parameters.
     * @param positionAsset The address of the position asset.
     * @param borrowedAsset The address of the borrowed asset.
     * @param positionAmount The amount of the position.
     * @param stopLossPrice The stop loss price.
     * @param takeProfitPrice The take profit price.
     * @return stopLossAmount The calculated stop loss amount, measured in the same decimal format as the borrowed asset.
     * @return takeProfitAmount The calculated take profit amount, measured in the same decimal format as the borrowed asset.
     */
    function _calcTakeProfitStopLossAmounts(
        address positionAsset,
        address borrowedAsset,
        uint256 positionAmount,
        uint256 stopLossPrice,
        uint256 takeProfitPrice
    ) internal view returns (uint256 stopLossAmount, uint256 takeProfitAmount) {
        uint256 multiplier1 = 10 ** (18 - IERC20Metadata(positionAsset).decimals());
        uint256 multiplier2 = 10 ** (18 - IERC20Metadata(borrowedAsset).decimals());
        if (stopLossPrice != 0) {
            /**@notice  converts the positionAmount to the WAD format
                and then converts to the decimal format of the borrowed asset if necessary*/
            stopLossAmount = (positionAmount * multiplier1).wmul(stopLossPrice) / multiplier2;
        }
        if (takeProfitPrice != 0) {
            takeProfitAmount = (positionAmount * multiplier1).wmul(takeProfitPrice) / multiplier2;
        }
    }
}
