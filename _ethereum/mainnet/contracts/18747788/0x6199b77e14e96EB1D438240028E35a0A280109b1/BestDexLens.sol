// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IERC165.sol";
import "./IERC20Metadata.sol";
import "./WadRayMath.sol";
import "./SafeCast.sol";

import "./LimitOrderLibrary.sol";
import "./PrimexPricingLibrary.sol";
import "./PositionLibrary.sol";
import "./Errors.sol";

import "./IBestDexLens.sol";
import "./IPositionManager.sol";
import "./IPrimexDNS.sol";
import "./ILimitOrderManager.sol";
import "./IDexAdapter.sol";

/**
 * @dev  All functions in this contract are intended to be called off-chain. Do not call functions from other contracts to avoid an out-of-gas error.
 */
contract BestDexLens is IBestDexLens, IERC165 {
    using WadRayMath for uint256;
    using SafeCast for uint256;

    int256 internal constant VERY_NEGATIVE_VALUE = -1e72;
    int256 internal constant VERY_POSITIVE_VALUE = 1e72;

    /**
     * @inheritdoc IBestDexLens
     */
    function getBestDexByOrder(
        BestDexByOrderParams memory _params
    ) external override returns (GetBestDexByOrderReturnParams memory _returnParams) {
        _require(
            IERC165(address(_params.positionManager)).supportsInterface(type(IPositionManager).interfaceId) &&
                IERC165(address(_params.limitOrderManager)).supportsInterface(type(ILimitOrderManager).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );

        LimitOrderLibrary.LimitOrder memory order = _params.limitOrderManager.getOrder(_params.orderId);
        address borrowedAsset = order.leverage == WadRayMath.WAD
            ? order.depositAsset
            : address(order.bucket.borrowedAsset());
        IPrimexDNS primexDns = _params.positionManager.primexDNS();

        bool isBorrowedAsset = borrowedAsset == order.depositAsset;
        bool isThirdAsset = !isBorrowedAsset && order.depositAsset != order.positionAsset;

        if (!isBorrowedAsset) {
            _returnParams.depositToBorrowedReturnParams = getBestMultipleDexes(
                GetBestMultipleDexesParams({
                    positionManager: _params.positionManager,
                    assetToBuy: borrowedAsset,
                    assetToSell: order.depositAsset,
                    amount: order.depositAmount,
                    isAmountToBuy: false,
                    shares: _params.shares.depositToBorrowedShares,
                    gasPriceInCheckedAsset: 0,
                    dexes: _params.dexes
                })
            );
        }

        uint256 depositAmountInBorrowed = PrimexPricingLibrary.getDepositAmountInBorrowed(
            PrimexPricingLibrary.AmountParams({
                tokenA: order.depositAsset,
                tokenB: borrowedAsset,
                amount: order.depositAmount,
                routes: _returnParams.depositToBorrowedReturnParams.routes,
                dexAdapter: primexDns.dexAdapter(),
                primexDNS: address(primexDns)
            }),
            isThirdAsset,
            address(_params.positionManager.priceOracle())
        );

        uint256 amountToTransfer = depositAmountInBorrowed.wmul(order.leverage - WadRayMath.WAD);

        if (isBorrowedAsset) {
            amountToTransfer += depositAmountInBorrowed;
        } else if (isThirdAsset) {
            _returnParams.depositInThirdAssetReturnParams = getBestMultipleDexes(
                GetBestMultipleDexesParams({
                    positionManager: _params.positionManager,
                    assetToBuy: order.positionAsset,
                    assetToSell: order.depositAsset,
                    amount: order.depositAmount,
                    isAmountToBuy: false,
                    shares: _params.shares.depositInThirdAssetShares,
                    gasPriceInCheckedAsset: 0,
                    dexes: _params.dexes
                })
            );
        }

        _returnParams.firstAssetReturnParams = getBestMultipleDexes(
            GetBestMultipleDexesParams({
                positionManager: _params.positionManager,
                assetToBuy: order.positionAsset,
                assetToSell: borrowedAsset,
                amount: amountToTransfer,
                isAmountToBuy: false,
                shares: _params.shares.firstAssetShares,
                gasPriceInCheckedAsset: 0,
                dexes: _params.dexes
            })
        );
    }

    /**
     * @inheritdoc IBestDexLens
     */
    function getArrayCurrentPriceAndProfitByPosition(
        IPositionManager _positionManager,
        uint256[] memory _ids,
        uint256[] memory _shares,
        DexWithAncillaryData[][] memory _dexes
    ) external override returns (uint256[] memory, int256[] memory) {
        _require(
            (_dexes.length == _ids.length) && (_shares.length == _dexes.length),
            Errors.DIFFERENT_DATA_LENGTH.selector
        );
        uint256 count = _ids.length;
        uint256[] memory currentPrices = new uint256[](count);
        int256[] memory currentProfits = new int256[](count);
        for (uint256 i; i < count; i++) {
            (currentPrices[i], currentProfits[i]) = getCurrentPriceAndProfitByPosition(
                _positionManager,
                _ids[i],
                _shares[i],
                _dexes[i]
            );
        }
        return (currentPrices, currentProfits);
    }

    /**
     * @inheritdoc IBestDexLens
     */
    function getPositionProfit(
        address _positionManager,
        uint256 _id,
        PrimexPricingLibrary.Route[] memory _routes
    ) public override returns (int256) {
        _require(
            IERC165(_positionManager).supportsInterface(type(IPositionManager).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );

        PositionLibrary.Position memory position = IPositionManager(_positionManager).getPosition(_id);

        uint256 expectedBorowedAssetAmount = PrimexPricingLibrary.getAmountOut(
            PrimexPricingLibrary.AmountParams({
                tokenA: position.positionAsset,
                tokenB: position.soldAsset,
                amount: position.positionAmount,
                routes: _routes,
                dexAdapter: IPositionManager(_positionManager).primexDNS().dexAdapter(),
                primexDNS: address(IPositionManager(_positionManager).primexDNS())
            })
        );
        uint256 positionDebt = IPositionManager(_positionManager).getPositionDebt(_id);
        uint256 returnedToTrader = expectedBorowedAssetAmount > positionDebt
            ? expectedBorowedAssetAmount - positionDebt
            : 0;

        return returnedToTrader.toInt256() - position.depositAmountInSoldAsset.toInt256();
    }

    /**
     * @inheritdoc IBestDexLens
     */
    function getBestDexByPosition(
        IPositionManager _positionManager,
        uint256 _positionId,
        uint256 _shares,
        DexWithAncillaryData[] memory _dexesWithAncillaryData
    ) public override returns (GetBestMultipleDexesReturnParams memory) {
        _require(
            IERC165(address(_positionManager)).supportsInterface(type(IPositionManager).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        PositionLibrary.Position memory position = _positionManager.getPosition(_positionId);

        return
            getBestMultipleDexes(
                GetBestMultipleDexesParams({
                    positionManager: _positionManager,
                    assetToBuy: position.soldAsset,
                    assetToSell: position.positionAsset,
                    amount: position.positionAmount,
                    isAmountToBuy: false,
                    shares: _shares,
                    gasPriceInCheckedAsset: 0,
                    dexes: _dexesWithAncillaryData
                })
            );
    }

    /**
     * @inheritdoc IBestDexLens
     */
    function getBestDexForOpenablePosition(
        BestDexForOpenablePositionParams memory _params
    )
        public
        override
        returns (
            GetBestMultipleDexesReturnParams memory _firstAssetReturnParams,
            GetBestMultipleDexesReturnParams memory _depositInThirdAssetReturnParams,
            GetBestMultipleDexesReturnParams memory _depositToBorrowedReturnParams
        )
    {
        _require(
            IERC165(address(_params.positionManager)).supportsInterface(type(IPositionManager).interfaceId) &&
                _params.borrowedAsset != address(0) &&
                _params.depositAsset != address(0) &&
                _params.positionAsset != address(0),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        _require(_params.depositAmount != 0, Errors.DEPOSITED_AMOUNT_IS_0.selector);

        _require(
            _params.borrowedAmount != 0 || _params.borrowedAsset == _params.depositAsset,
            Errors.SPOT_DEPOSITED_ASSET_SHOULD_BE_EQUAL_BORROWED_ASSET.selector
        );

        bool isBorrowedAsset = _params.borrowedAsset == _params.depositAsset;
        bool isThirdAsset = !isBorrowedAsset && _params.depositAsset != _params.positionAsset;
        if (!isBorrowedAsset) {
            _depositToBorrowedReturnParams = getBestMultipleDexes(
                GetBestMultipleDexesParams({
                    positionManager: _params.positionManager,
                    assetToBuy: _params.borrowedAsset,
                    assetToSell: _params.depositAsset,
                    amount: _params.depositAmount,
                    isAmountToBuy: false,
                    shares: _params.shares.depositToBorrowedShares,
                    gasPriceInCheckedAsset: 0,
                    dexes: _params.dexes
                })
            );
        }
        if (isThirdAsset) {
            _depositInThirdAssetReturnParams = getBestMultipleDexes(
                GetBestMultipleDexesParams({
                    positionManager: _params.positionManager,
                    assetToBuy: _params.positionAsset,
                    assetToSell: _params.depositAsset,
                    amount: _params.depositAmount,
                    isAmountToBuy: false,
                    shares: _params.shares.depositInThirdAssetShares,
                    gasPriceInCheckedAsset: 0,
                    dexes: _params.dexes
                })
            );
        }
        _firstAssetReturnParams = getBestMultipleDexes(
            GetBestMultipleDexesParams({
                positionManager: _params.positionManager,
                assetToBuy: _params.positionAsset,
                assetToSell: _params.borrowedAsset,
                amount: _params.borrowedAmount + (isBorrowedAsset ? _params.depositAmount : 0),
                isAmountToBuy: false,
                shares: _params.shares.firstAssetShares,
                gasPriceInCheckedAsset: 0,
                dexes: _params.dexes
            })
        );
    }

    /**
     * @inheritdoc IBestDexLens
     */
    function getBestMultipleDexes(
        GetBestMultipleDexesParams memory _params
    ) public override returns (GetBestMultipleDexesReturnParams memory _returnParams) {
        _require(
            _params.assetToBuy != address(0) && _params.assetToSell != address(0),
            Errors.ZERO_ASSET_ADDRESS.selector
        );
        _require(_params.assetToBuy != _params.assetToSell, Errors.ASSETS_SHOULD_BE_DIFFERENT.selector);
        _require(_params.shares > 0, Errors.ZERO_SHARES.selector);
        _require(_params.amount >= _params.shares, Errors.SHARES_AMOUNT_IS_GREATER_THAN_AMOUNT_TO_SELL.selector);

        GetBestMultipleDexesVars memory vars;
        DexWithAncillaryData[] memory activeDexes = new DexWithAncillaryData[](_params.dexes.length);
        vars.shareCount = _params.shares;

        // stores estimated gas to perform swap on each DEX
        vars.gases = new uint256[](_params.dexes.length);

        // matrix [allDexes.length][shareCount] containing the swapped amount
        // on each DEX (rows) for each share (columns) minus estimated gas to perform the swap
        int256[][] memory amountByDexByShare = new int256[][](_params.dexes.length);

        vars.path = new address[](2);
        vars.path[0] = _params.assetToSell;
        vars.path[1] = _params.assetToBuy;

        // filter out inactive DEXes and collect their outputs for all possible share splits
        {
            IDexAdapter.GetAmountsParams memory amountParams;

            for (uint256 i; i < _params.dexes.length; i++) {
                // if DEX is not supported or deactivated - set expected gas to a very large number
                // slither-disable-next-line unused-return
                try _params.positionManager.primexDNS().getDexAddress(_params.dexes[i].dex) returns (
                    // slither-disable-next-line unused-return,variable-scope
                    address currentRouter
                ) {
                    uint256 returnGas = IDexAdapter(_params.positionManager.primexDNS().dexAdapter()).getGas(
                        currentRouter
                    );
                    amountParams.amount = _params.amount / vars.shareCount;
                    amountParams.dexRouter = currentRouter;

                    amountParams.encodedPath = PrimexPricingLibrary.encodePath(
                        vars.path,
                        currentRouter,
                        _params.dexes[i].ancillaryData,
                        _params.positionManager.primexDNS().dexAdapter(),
                        _params.isAmountToBuy
                    );

                    uint256 amount = _getAmountsFromAdapter(
                        amountParams,
                        IDexAdapter(_params.positionManager.primexDNS().dexAdapter()),
                        _params.isAmountToBuy
                    );
                    if (amount == type(uint256).max) continue;
                    // add DEX to active list
                    activeDexes[vars.activeDexesLength] = _params.dexes[i];
                    amountByDexByShare[vars.activeDexesLength] = new int256[](vars.shareCount);
                    // store estimated gas
                    vars.gases[vars.activeDexesLength] = returnGas;
                    vars.gasInCheckedAsset = ((returnGas * _params.gasPriceInCheckedAsset) / 1e18).toInt256();
                    amountByDexByShare[vars.activeDexesLength][0] = _params.isAmountToBuy
                        ? amount.toInt256() + vars.gasInCheckedAsset
                        : amount.toInt256() - vars.gasInCheckedAsset;
                } catch {
                    continue;
                }
                for (uint256 j = 1; j < vars.shareCount; j++) {
                    amountParams.amount = (_params.amount * (j + 1)) / vars.shareCount;
                    uint256 amount = _getAmountsFromAdapter(
                        amountParams,
                        IDexAdapter(_params.positionManager.primexDNS().dexAdapter()),
                        _params.isAmountToBuy
                    );

                    amountByDexByShare[vars.activeDexesLength][j] = _params.isAmountToBuy
                        ? (
                            amount == type(uint256).max
                                ? VERY_POSITIVE_VALUE
                                : amount.toInt256() + vars.gasInCheckedAsset
                        )
                        : (
                            amount == type(uint256).max
                                ? VERY_NEGATIVE_VALUE
                                : amount.toInt256() - vars.gasInCheckedAsset
                        );
                }

                // we should get here if first _getAmountsFromAdapter is successful and DEX is active
                vars.activeDexesLength++;
            }
        }

        _require(vars.activeDexesLength > 0, Errors.NO_ACTIVE_DEXES.selector);

        // array with best splitting route
        uint256[] memory distribution = new uint256[](vars.activeDexesLength);
        uint256 involvedDexesLength;

        {
            // matrix [activeDexesLength][shareCount] containing the maximum amount you receive for swapping
            // j parts of asset for each DEX
            int256[][] memory answer = new int256[][](vars.activeDexesLength);
            // matrix [activeDexesLength][shareCount] containing the amount of parts you should swap on previous DEXes
            // if you swap j parts on current DEX
            uint256[][] memory parentParts = new uint256[][](vars.activeDexesLength);

            for (uint256 i; i < vars.activeDexesLength; i++) {
                answer[i] = new int256[](vars.shareCount);
                parentParts[i] = new uint256[](vars.shareCount);
            }

            // copy first DEX from `amountByDexByShare` to the `answer` first row
            for (uint256 j; j < vars.shareCount; j++) {
                answer[0][j] = amountByDexByShare[0][j];
            }

            for (uint256 i = 1; i < vars.activeDexesLength; i++) {
                for (uint256 j; j < vars.shareCount; j++) {
                    // choose the value from the previous DEX as a max value
                    int256 bestValue = answer[i - 1][j];
                    // save current shares count
                    parentParts[i][j] = j + 1;
                    // current value is a sum of previous max shares so that total shares count is j + 1
                    int256 currentValue = amountByDexByShare[i][j];
                    if (
                        _params.isAmountToBuy ? (currentValue < bestValue || bestValue == 0) : currentValue > bestValue
                    ) {
                        bestValue = currentValue;
                        parentParts[i][j] = 0;
                    }

                    for (uint256 k; k < j; k++) {
                        currentValue = answer[i - 1][j - k - 1] + amountByDexByShare[i][k];

                        // if current value of DEX + previous value of previous DEX is higher than max value
                        // update max value and save previous shares count
                        if (
                            _params.isAmountToBuy
                                ? (currentValue < bestValue || bestValue == 0)
                                : currentValue > bestValue
                        ) {
                            bestValue = currentValue;
                            parentParts[i][j] = j - k;
                        }
                    }
                    answer[i][j] = bestValue;
                }
            }

            // iterate over `parentParts` backwards and collect the parts of the shares to get the resulting maximum amount
            {
                uint256 partsLeft = vars.shareCount;
                for (uint256 i; i < vars.activeDexesLength; i++) {
                    if (partsLeft == 0) break;
                    uint256 curExchange = vars.activeDexesLength - i - 1;
                    distribution[curExchange] = partsLeft - parentParts[curExchange][partsLeft - 1];
                    partsLeft = parentParts[curExchange][partsLeft - 1];
                    if (distribution[curExchange] > 0) {
                        involvedDexesLength++;
                    }
                }
            }
        }

        _returnParams.routes = new PrimexPricingLibrary.Route[](involvedDexesLength);

        for (uint256 i; i < vars.activeDexesLength; i++) {
            if (distribution[i] == 0) continue;

            _returnParams.routes[vars.filledRoutes] = PrimexPricingLibrary.Route({
                paths: new PrimexPricingLibrary.SwapPath[](1),
                shares: distribution[i]
            });
            _returnParams.routes[vars.filledRoutes].paths[0] = PrimexPricingLibrary.SwapPath({
                dexName: activeDexes[i].dex,
                encodedPath: PrimexPricingLibrary.encodePath(
                    vars.path,
                    _params.positionManager.primexDNS().getDexAddress(activeDexes[i].dex),
                    activeDexes[i].ancillaryData,
                    _params.positionManager.primexDNS().dexAdapter(),
                    _params.isAmountToBuy
                )
            });
            vars.filledRoutes++;
            // collect some additional statistics: total return amount, estimate gas spending
            _returnParams.estimateGasAmount = _returnParams.estimateGasAmount.add(vars.gases[i]);
            int256 value = amountByDexByShare[i][distribution[i] - 1];
            _returnParams.returnAmount =
                _returnParams.returnAmount +
                uint256(
                    (
                        value == 0 ? int256(0) : _params.isAmountToBuy
                            ? (value - ((vars.gases[i] * _params.gasPriceInCheckedAsset) / 1e18).toInt256())
                            : (value + ((vars.gases[i] * _params.gasPriceInCheckedAsset) / 1e18).toInt256())
                    )
                );
        }
    }

    /**
     * @inheritdoc IBestDexLens
     */
    function getCurrentPriceAndProfitByPosition(
        IPositionManager _positionManager,
        uint256 _id,
        uint256 _shares,
        DexWithAncillaryData[] memory _dexes
    ) public override returns (uint256, int256) {
        _require(
            IERC165(address(_positionManager)).supportsInterface(type(IPositionManager).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        PositionLibrary.Position memory position = _positionManager.getPosition(_id);

        PrimexPricingLibrary.Route[] memory routes = getBestMultipleDexes(
            GetBestMultipleDexesParams({
                positionManager: _positionManager,
                assetToBuy: position.soldAsset,
                assetToSell: position.positionAsset,
                amount: position.positionAmount,
                isAmountToBuy: false,
                shares: _shares,
                gasPriceInCheckedAsset: 0,
                dexes: _dexes
            })
        ).routes;

        uint256 multiplier1 = 10 ** (18 - IERC20Metadata(position.soldAsset).decimals());

        uint256 currentPriceNumerator = PrimexPricingLibrary.getAmountOut(
            PrimexPricingLibrary.AmountParams({
                tokenA: position.positionAsset,
                tokenB: position.soldAsset,
                amount: position.positionAmount,
                routes: routes,
                dexAdapter: _positionManager.primexDNS().dexAdapter(),
                primexDNS: address(_positionManager.primexDNS())
            })
        ) * multiplier1;
        uint256 currentPriceDenominator = position.positionAmount *
            (10 ** (18 - IERC20Metadata(position.positionAsset).decimals()));

        return (
            currentPriceNumerator.wdiv(currentPriceDenominator) / multiplier1,
            getPositionProfit(address(_positionManager), _id, routes)
        );
    }

    /**
     * @inheritdoc IBestDexLens
     */
    function getAmountOut(PrimexPricingLibrary.AmountParams memory _params) public override returns (uint256) {
        return PrimexPricingLibrary.getAmountOut(_params);
    }

    /**
     * @inheritdoc IBestDexLens
     */
    function getAmountIn(PrimexPricingLibrary.AmountParams memory _params) public override returns (uint256) {
        return PrimexPricingLibrary.getAmountIn(_params);
    }

    /**
     * @notice Interface checker
     * @param interfaceId The interface id to check
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBestDexLens).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice Retrieves the amounts from a DEX adapter contract.
     * @param _params The parameters for getting amounts from the adapter.
     * @param _adapter The DEX adapter contract.
     * @param _isAmountToBuy A flag indicating whether the amount to retrieve is for buying or selling.
     * @return The retrieved amount.
     */
    function _getAmountsFromAdapter(
        IDexAdapter.GetAmountsParams memory _params,
        IDexAdapter _adapter,
        bool _isAmountToBuy
    ) internal returns (uint256) {
        if (_isAmountToBuy) {
            try _adapter.getAmountsIn(_params) returns (uint256[3] memory answersList) {
                return answersList[0];
            } catch {
                return type(uint256).max;
            }
        }
        try _adapter.getAmountsOut(_params) returns (uint256[3] memory answersList) {
            return answersList[1];
        } catch {
            return type(uint256).max;
        }
    }
}
