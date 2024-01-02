// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "./IAccessControl.sol";
import "./IERC165.sol";
import "./IERC20.sol";

import "./LimitOrderLibrary.sol";
import "./PrimexPricingLibrary.sol";
import "./PositionLibrary.sol";
import "./Errors.sol";

import "./Constants.sol";
import "./IPositionManager.sol";
import "./ILimitOrderManager.sol";
import "./IPrimexUpkeep.sol";
import "./IBestDexLens.sol";
import "./IPrimexLens.sol";
import "./ILimitPriceCOM.sol";
import "./ITakeProfitStopLossCCM.sol";

contract PrimexUpkeep is IPrimexUpkeep {
    uint256 public constant MAX_UINT256 = type(uint256).max;

    IPositionManager public immutable override pm;
    ILimitOrderManager public immutable override lom;
    IPrimexLens public immutable override primexLens;
    address public immutable override registry;
    IBestDexLens public immutable override bestDexLens;

    /**
     * @dev Modifier that checks if the caller has a specific role.
     * @param _role The role identifier to check.
     */
    modifier onlyRole(bytes32 _role) {
        _require(IAccessControl(registry).hasRole(_role, msg.sender), Errors.FORBIDDEN.selector);
        _;
    }

    constructor(
        IPositionManager _positionManager,
        ILimitOrderManager _limitOrderManager,
        address _registry,
        IBestDexLens _bestDexLens,
        IPrimexLens _primexLens
    ) {
        _require(
            IERC165(address(_bestDexLens)).supportsInterface(type(IBestDexLens).interfaceId) &&
                IERC165(_registry).supportsInterface(type(IAccessControl).interfaceId) &&
                IERC165(address(_positionManager)).supportsInterface(type(IPositionManager).interfaceId) &&
                IERC165(address(_primexLens)).supportsInterface(type(IPrimexLens).interfaceId) &&
                IERC165(address(_limitOrderManager)).supportsInterface(type(ILimitOrderManager).interfaceId),
            Errors.ADDRESS_NOT_SUPPORTED.selector
        );
        pm = _positionManager;
        lom = _limitOrderManager;
        registry = _registry;
        bestDexLens = _bestDexLens;
        primexLens = _primexLens;
    }

    /**
     * @inheritdoc IPrimexUpkeep
     */
    function checkUpkeep(
        bytes calldata checkData,
        IBestDexLens.DexWithAncillaryData[] memory _dexesWithAncillaryData,
        uint256 _cursor,
        uint256 _count,
        uint256 _outputSize
    ) external override returns (uint256 newCursor, bool upkeepNeeded, bytes memory performData) {
        _require(_outputSize > 0, Errors.NUMBER_IS_0.selector);
        LiquidationSource liquidationSource = abi.decode(checkData, (LiquidationSource));

        if (liquidationSource == LiquidationSource.POSITION) {
            return
                _checkPositionUpkeep(
                    CheckUpkeepParams({
                        dexes: _dexesWithAncillaryData,
                        cursor: _cursor,
                        count: _count,
                        outputSize: _outputSize
                    })
                );
        } else if (liquidationSource == LiquidationSource.ORDER) {
            return
                _checkOrderUpkeep(
                    CheckUpkeepParams({
                        dexes: _dexesWithAncillaryData,
                        cursor: _cursor,
                        count: _count,
                        outputSize: _outputSize
                    })
                );
        }
    }

    /**
     * @inheritdoc IPrimexUpkeep
     */
    function performUpkeepOrders(OpenByOrderInfo[] calldata toOpenByOrder, address keeper) external override {
        for (uint256 i; i < toOpenByOrder.length; i++) {
            try
                lom.openPositionByOrder(
                    LimitOrderLibrary.OpenPositionParams({
                        orderId: toOpenByOrder[i].id,
                        conditionIndex: toOpenByOrder[i].conditionIndex,
                        comAdditionalParams: toOpenByOrder[i].comAdditionalParams,
                        firstAssetRoutes: toOpenByOrder[i].firstAssetRoutes,
                        depositInThirdAssetRoutes: toOpenByOrder[i].depositInThirdAssetRoutes,
                        keeper: keeper
                    })
                )
            {} catch Error(string memory revertReason) {
                emit ErrorHandled(toOpenByOrder[i].id, keeper, revertReason);
            } catch Panic(uint revertReason) {
                emit PanicErrorHandled(revertReason);
            } catch (bytes memory revertReason) {
                emit LowLevelErrorHandled(revertReason);
            }
        }
    }

    /**
     * @inheritdoc IPrimexUpkeep
     */
    function performUpkeepOrdersUnsafe(OpenByOrderInfo[] calldata toOpenByOrder, address keeper) external override {
        for (uint256 i; i < toOpenByOrder.length; i++) {
            lom.openPositionByOrder(
                LimitOrderLibrary.OpenPositionParams({
                    orderId: toOpenByOrder[i].id,
                    conditionIndex: toOpenByOrder[i].conditionIndex,
                    comAdditionalParams: toOpenByOrder[i].comAdditionalParams,
                    firstAssetRoutes: toOpenByOrder[i].firstAssetRoutes,
                    depositInThirdAssetRoutes: toOpenByOrder[i].depositInThirdAssetRoutes,
                    keeper: keeper
                })
            );
        }
    }

    /**
     * @inheritdoc IPrimexUpkeep
     */
    function performUpkeepPositions(LiquidatePositionInfo[] calldata toLiquidate, address keeper) external override {
        for (uint256 i; i < toLiquidate.length; i++) {
            try
                pm.closePositionByCondition(
                    toLiquidate[i].id,
                    keeper,
                    toLiquidate[i].positionAssetRoutes,
                    toLiquidate[i].conditionIndex,
                    toLiquidate[i].ccmAdditionalParams,
                    toLiquidate[i].closeReason
                )
            {} catch Error(string memory revertReason) {
                emit ErrorHandled(toLiquidate[i].id, keeper, revertReason);
            } catch Panic(uint revertReason) {
                emit PanicErrorHandled(revertReason);
            } catch (bytes memory revertReason) {
                emit LowLevelErrorHandled(revertReason);
            }
        }
    }

    /**
     * @inheritdoc IPrimexUpkeep
     */
    function performUpkeepPositionsUnsafe(
        LiquidatePositionInfo[] calldata toLiquidate,
        address keeper
    ) external override {
        for (uint256 i; i < toLiquidate.length; i++) {
            pm.closePositionByCondition(
                toLiquidate[i].id,
                keeper,
                toLiquidate[i].positionAssetRoutes,
                toLiquidate[i].conditionIndex,
                toLiquidate[i].ccmAdditionalParams,
                toLiquidate[i].closeReason
            );
        }
    }

    /**
     * @inheritdoc IPrimexUpkeep
     */
    function performUpkeep(bytes calldata performData, address keeper) external override {
        (LiquidationSource liquidationSource, uint256 count) = abi.decode(
            performData[:64],
            (LiquidationSource, uint256)
        );

        if (liquidationSource == LiquidationSource.POSITION) {
            (, , LiquidatePositionInfo[] memory toLiquidate) = abi.decode(
                performData,
                (LiquidationSource, uint256, LiquidatePositionInfo[])
            );

            for (uint256 i; i < count; i++) {
                try
                    pm.closePositionByCondition(
                        toLiquidate[i].id,
                        keeper,
                        toLiquidate[i].positionAssetRoutes,
                        toLiquidate[i].conditionIndex,
                        toLiquidate[i].ccmAdditionalParams,
                        toLiquidate[i].closeReason
                    )
                {} catch {}
            }
        } else if (liquidationSource == LiquidationSource.ORDER) {
            (, , OpenByOrderInfo[] memory toOpenByOrder) = abi.decode(
                performData,
                (LiquidationSource, uint256, OpenByOrderInfo[])
            );

            for (uint256 i; i < count; i++) {
                try
                    lom.openPositionByOrder(
                        LimitOrderLibrary.OpenPositionParams({
                            orderId: toOpenByOrder[i].id,
                            conditionIndex: toOpenByOrder[i].conditionIndex,
                            comAdditionalParams: toOpenByOrder[i].comAdditionalParams,
                            firstAssetRoutes: toOpenByOrder[i].firstAssetRoutes,
                            depositInThirdAssetRoutes: toOpenByOrder[i].depositInThirdAssetRoutes,
                            keeper: keeper
                        })
                    )
                {} catch {}
            }
        }
    }

    /**
     * @inheritdoc IPrimexUpkeep
     */
    function getClosingParamsByCondition(
        address ccm,
        PrimexPricingLibrary.Route[] memory secondAssetRoutes
    ) public view override returns (bytes memory params) {
        if (IERC165(ccm).supportsInterface(type(ITakeProfitStopLossCCM).interfaceId)) {
            return abi.encode(ITakeProfitStopLossCCM.AdditionalParams({routes: secondAssetRoutes}));
        }
    }

    /**
     * @notice Internal function to check position upkeep and perform liquidation if necessary.
     * @param _params CheckUpkeepParams struct containing the necessary parameters.
     * @return newCursor The new cursor value. Cursor is non-zero if there are more positions available.
     * @return upkeepNeeded Boolean indicating whether upkeep is needed.
     * @return performData Encoded data indicating the liquidation source, count, and liquidation information.
     */
    function _checkPositionUpkeep(
        CheckUpkeepParams memory _params
    ) internal returns (uint256 newCursor, bool upkeepNeeded, bytes memory performData) {
        LiquidatePositionInfo[] memory toLiquidate = new LiquidatePositionInfo[](_params.outputSize);
        uint256 count;
        (IPrimexLens.OpenPositionWithConditions[] memory openPositionsWithConditions, uint256 _newCursor) = primexLens
            .getOpenPositionsWithConditions(address(pm), _params.cursor, _params.count);
        for (uint256 i; i < openPositionsWithConditions.length; i++) {
            PrimexPricingLibrary.Route[] memory secondAssetRoutes;
            try
                bestDexLens.getBestDexByPosition(pm, openPositionsWithConditions[i].positionData.id, 10, _params.dexes)
            returns (IBestDexLens.GetBestMultipleDexesReturnParams memory _dexParams) {
                secondAssetRoutes = _dexParams.routes;
            } catch {
                continue;
            }
            Closable memory closable;

            if (pm.isPositionRisky(openPositionsWithConditions[i].positionData.id)) {
                closable.canBeClosed = true;
                closable.isRiskyOrDelisted = true;
                closable.closeReason = PositionLibrary.CloseReason.RISKY_POSITION;
            } else if (pm.isDelistedPosition(openPositionsWithConditions[i].positionData.id)) {
                closable.canBeClosed = true;
                closable.isRiskyOrDelisted = true;
                closable.closeReason = PositionLibrary.CloseReason.BUCKET_DELISTED;
            }
            for (uint256 j; j < openPositionsWithConditions[i].conditionsData.length; j++) {
                bytes memory additionalParams = getClosingParamsByCondition(
                    pm.primexDNS().cmTypeToAddress(openPositionsWithConditions[i].conditionsData[j].managerType),
                    secondAssetRoutes
                );
                if (
                    !closable.canBeClosed &&
                    pm.canBeClosed(openPositionsWithConditions[i].positionData.id, j, additionalParams)
                ) {
                    closable.canBeClosed = true;
                    closable.closeReason = PositionLibrary.CloseReason.LIMIT_CONDITION;
                }
                if (closable.canBeClosed) {
                    try
                        pm.closePositionByCondition(
                            openPositionsWithConditions[i].positionData.id,
                            msg.sender,
                            secondAssetRoutes,
                            closable.isRiskyOrDelisted ? MAX_UINT256 : j,
                            closable.isRiskyOrDelisted ? bytes("") : additionalParams,
                            closable.closeReason
                        )
                    {} catch {
                        continue;
                    }
                    toLiquidate[count] = LiquidatePositionInfo({
                        id: openPositionsWithConditions[i].positionData.id,
                        conditionIndex: closable.isRiskyOrDelisted ? MAX_UINT256 : j,
                        ccmAdditionalParams: closable.isRiskyOrDelisted ? bytes("") : additionalParams,
                        positionAssetRoutes: secondAssetRoutes,
                        closeReason: closable.closeReason
                    });
                    count++;
                    if (count == _params.outputSize) {
                        return (
                            _params.cursor + _params.outputSize,
                            true,
                            abi.encode(LiquidationSource.POSITION, count, toLiquidate)
                        );
                    }
                    break;
                }
            }
        }
        if (count > 0) {
            upkeepNeeded = true;
        }
        return (_newCursor, upkeepNeeded, abi.encode(LiquidationSource.POSITION, count, toLiquidate));
    }

    /**
     * @notice Internal function to check the upkeep of an order.
     * @param _params The CheckUpkeepParams struct containing the necessary parameters.
     * @return newCursor The new cursor value. Cursor is non-zero if there are more orders available.
     * @return upkeepNeeded Boolean indicating whether upkeep is needed.
     * @return performData Encoded data indicating the upkeep source, count, and order filling information.
     */
    function _checkOrderUpkeep(
        CheckUpkeepParams memory _params
    ) internal returns (uint256 newCursor, bool upkeepNeeded, bytes memory performData) {
        OpenByOrderInfo[] memory toOpenByOrder = new OpenByOrderInfo[](_params.outputSize);
        uint256 count;
        (IPrimexLens.LimitOrderWithConditions[] memory limitOrdersWithConditions, uint256 _newCursor) = primexLens
            .getLimitOrdersWithConditions(address(lom), _params.cursor, _params.count);
        for (uint256 i; i < limitOrdersWithConditions.length; i++) {
            IBestDexLens.GetBestDexByOrderReturnParams memory bestDexLensReturnParams;
            try
                bestDexLens.getBestDexByOrder(
                    IBestDexLens.BestDexByOrderParams({
                        positionManager: pm,
                        limitOrderManager: lom,
                        orderId: limitOrdersWithConditions[i].limitOrderData.id,
                        shares: IBestDexLens.Shares({
                            firstAssetShares: 10,
                            depositInThirdAssetShares: 10,
                            depositToBorrowedShares: 10
                        }),
                        dexes: _params.dexes
                    })
                )
            returns (IBestDexLens.GetBestDexByOrderReturnParams memory _dexParams) {
                bestDexLensReturnParams = _dexParams;
            } catch {
                continue;
            }
            Routes memory routes;
            routes.firstAssetRoutes = bestDexLensReturnParams.firstAssetReturnParams.routes;
            routes.depositInThirdAssetRoutes = bestDexLensReturnParams.depositInThirdAssetReturnParams.routes;
            {
                for (uint256 j; j < limitOrdersWithConditions[i].openConditionsData.length; j++) {
                    bytes memory additionalParams = _getOpeningParamsByCondition(
                        pm.primexDNS().cmTypeToAddress(limitOrdersWithConditions[i].openConditionsData[j].managerType),
                        routes
                    );
                    if (lom.canBeFilled(limitOrdersWithConditions[i].limitOrderData.id, j, additionalParams)) {
                        try
                            lom.openPositionByOrder(
                                LimitOrderLibrary.OpenPositionParams({
                                    orderId: limitOrdersWithConditions[i].limitOrderData.id,
                                    conditionIndex: j,
                                    comAdditionalParams: additionalParams,
                                    firstAssetRoutes: routes.firstAssetRoutes,
                                    depositInThirdAssetRoutes: routes.depositInThirdAssetRoutes,
                                    keeper: msg.sender
                                })
                            )
                        {} catch {
                            continue;
                        }
                        toOpenByOrder[count] = OpenByOrderInfo({
                            id: limitOrdersWithConditions[i].limitOrderData.id,
                            conditionIndex: j,
                            comAdditionalParams: additionalParams,
                            firstAssetRoutes: routes.firstAssetRoutes,
                            depositInThirdAssetRoutes: routes.depositInThirdAssetRoutes
                        });

                        count++;
                        if (count == _params.outputSize) {
                            return (
                                _params.cursor + _params.outputSize,
                                true,
                                abi.encode(LiquidationSource.ORDER, count, toOpenByOrder)
                            );
                        }
                        break;
                    }
                }
            }
        }
        if (count > 0) {
            upkeepNeeded = true;
        }
        return (_newCursor, upkeepNeeded, abi.encode(LiquidationSource.ORDER, count, toOpenByOrder));
    }

    /**
     * @notice Retrieves the opening parameters based on a condition.
     * @param com The address of the COM contract.
     * @param routes The Routes struct containing the asset routes.
     * @return params The encoded opening parameters.
     */
    function _getOpeningParamsByCondition(
        address com,
        Routes memory routes
    ) internal view returns (bytes memory params) {
        if (IERC165(com).supportsInterface(type(ILimitPriceCOM).interfaceId)) {
            return
                abi.encode(
                    ILimitPriceCOM.AdditionalParams({
                        firstAssetRoutes: routes.firstAssetRoutes,
                        depositInThirdAssetRoutes: routes.depositInThirdAssetRoutes
                    })
                );
        }
    }
}
