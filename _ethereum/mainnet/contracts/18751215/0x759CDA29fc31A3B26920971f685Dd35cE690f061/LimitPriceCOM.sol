// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC20Metadata.sol";
import "./IERC165.sol";
import "./WadRayMath.sol";

import "./PrimexPricingLibrary.sol";
import "./LimitOrderLibrary.sol";
import "./Errors.sol";

import "./IPositionManager.sol";
import "./IPrimexDNS.sol";
import "./IPriceOracle.sol";
import "./ILimitPriceCOM.sol";
import "./IConditionalOpeningManager.sol";
import "./ITakeProfitStopLossCCM.sol";

contract LimitPriceCOM is IConditionalOpeningManager, ILimitPriceCOM, IERC165 {
    using WadRayMath for uint256;

    uint256 private constant CM_TYPE = 1;

    address public immutable primexDNS;
    address public immutable priceOracle;
    address public immutable pm;

    constructor(address _primexDNS, address _priceOracle, address _pm) {
        _require(
            IERC165(address(_primexDNS)).supportsInterface(type(IPrimexDNS).interfaceId) &&
                IERC165(_priceOracle).supportsInterface(type(IPriceOracle).interfaceId) &&
                IERC165(_pm).supportsInterface(type(IPositionManager).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        primexDNS = _primexDNS;
        priceOracle = _priceOracle;
        pm = _pm;
    }

    /**
     * @inheritdoc IConditionalOpeningManager
     */
    function canBeFilledBeforeSwap(
        LimitOrderLibrary.LimitOrder calldata _order,
        bytes calldata _params,
        bytes calldata _additionalParams
    ) external override returns (bool) {
        if (_params.length == 0) return false;

        CanBeFilledVars memory vars;
        vars.params = abi.decode(_params, (CanBeFilledParams));
        vars.additionalParams = abi.decode(_additionalParams, (AdditionalParams));

        vars.borrowedAsset = _order.leverage == WadRayMath.WAD
            ? _order.depositAsset
            : address(_order.bucket.borrowedAsset());

        vars.dexAdapter = address(IPrimexDNS(primexDNS).dexAdapter());
        vars.isThirdAsset = _order.depositAsset != vars.borrowedAsset && _order.depositAsset != _order.positionAsset;
        if (!vars.isThirdAsset) {
            _require(
                vars.additionalParams.depositInThirdAssetRoutes.length == 0,
                Errors.DEPOSIT_IN_THIRD_ASSET_ROUTES_LENGTH_SHOULD_BE_0.selector
            );
        } else {
            vars.depositInPositionAsset = PrimexPricingLibrary.getAmountOut(
                PrimexPricingLibrary.AmountParams({
                    tokenA: _order.depositAsset,
                    tokenB: _order.positionAsset,
                    amount: _order.depositAmount,
                    routes: vars.additionalParams.depositInThirdAssetRoutes,
                    dexAdapter: vars.dexAdapter,
                    primexDNS: primexDNS
                })
            );
        }

        if (_order.depositAsset == vars.borrowedAsset) {
            vars.amountIn = _order.depositAmount.wmul(_order.leverage);
            vars.amountToTransfer = vars.amountIn;
        } else {
            if (_order.depositAsset == _order.positionAsset) vars.depositInPositionAsset = _order.depositAmount;
            uint256 depositAmountInBorrowed = PrimexPricingLibrary.getOracleAmountsOut(
                _order.depositAsset,
                vars.borrowedAsset,
                _order.depositAmount,
                priceOracle
            );
            vars.amountIn = depositAmountInBorrowed.wmul(_order.leverage);
            vars.amountToTransfer = vars.amountIn - depositAmountInBorrowed;
        }
        vars.borrowedAmountInPositionAsset = PrimexPricingLibrary.getAmountOut(
            PrimexPricingLibrary.AmountParams({
                tokenA: vars.borrowedAsset,
                tokenB: _order.positionAsset,
                amount: vars.amountToTransfer,
                routes: vars.additionalParams.firstAssetRoutes,
                dexAdapter: vars.dexAdapter,
                primexDNS: primexDNS
            })
        );

        vars.amountOut = vars.depositInPositionAsset + vars.borrowedAmountInPositionAsset;

        vars.borrowedAssetMultiplier = (10 ** (18 - IERC20Metadata(vars.borrowedAsset).decimals()));

        vars.exchangeRate =
            (vars.amountIn * vars.borrowedAssetMultiplier).wdiv(
                vars.amountOut * (10 ** (18 - IERC20Metadata(_order.positionAsset).decimals()))
            ) /
            vars.borrowedAssetMultiplier;

        if (vars.exchangeRate > vars.params.limitPrice) return false;

        if (_order.leverage > WadRayMath.WAD) {
            uint256 leverage;
            if (_order.depositAsset == vars.borrowedAsset) {
                leverage = _order.leverage;
            } else {
                leverage = (vars.borrowedAmountInPositionAsset + vars.depositInPositionAsset).wdiv(
                    vars.depositInPositionAsset
                );
            }
            if (leverage > _order.bucket.maxAssetLeverage(_order.positionAsset)) return false;

            if (vars.amountOut > IPositionManager(pm).maxPositionSize(vars.borrowedAsset, _order.positionAsset)) {
                return false;
            }
        }

        return
            PrimexPricingLibrary.isCorrespondsMinPositionSize(
                IPositionManager(pm).minPositionSize(),
                IPositionManager(pm).minPositionAsset(),
                vars.borrowedAsset,
                vars.amountIn,
                priceOracle
            );
    }

    /**
     * @inheritdoc IConditionalOpeningManager
     */
    function canBeFilledAfterSwap(
        LimitOrderLibrary.LimitOrder calldata,
        bytes calldata _params,
        bytes calldata,
        uint256 _exchangeRate
    ) external pure override returns (bool) {
        if (_params.length == 0) {
            return false;
        }
        CanBeFilledVars memory vars;
        vars.params = abi.decode(_params, (CanBeFilledParams));
        return _exchangeRate <= vars.params.limitPrice;
    }

    /**
     * @notice Interface checker
     * @param _interfaceId The interface id to check
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return
            _interfaceId == type(IConditionalOpeningManager).interfaceId ||
            _interfaceId == type(ILimitPriceCOM).interfaceId ||
            _interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @inheritdoc ILimitPriceCOM
     */
    function getLimitPrice(bytes calldata _params) public pure override returns (uint256) {
        CanBeFilledParams memory params;
        if (_params.length > 0) {
            params = abi.decode(_params, (CanBeFilledParams));
        }
        return (params.limitPrice);
    }
}
