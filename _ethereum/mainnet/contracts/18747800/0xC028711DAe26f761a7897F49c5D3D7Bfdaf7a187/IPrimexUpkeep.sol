// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./PrimexPricingLibrary.sol";
import "./PositionLibrary.sol";

import "./IPositionManager.sol";
import "./ILimitOrderManager.sol";
import "./IPrimexLens.sol";
import "./IBestDexLens.sol";

interface IPrimexUpkeep {
    enum LiquidationSource {
        NONE,
        POSITION,
        ORDER
    }

    struct OpenByOrderInfo {
        uint256 id;
        uint256 conditionIndex;
        bytes comAdditionalParams;
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
    }

    struct LiquidatePositionInfo {
        uint256 id;
        uint256 conditionIndex;
        bytes ccmAdditionalParams;
        PrimexPricingLibrary.Route[] positionAssetRoutes;
        PositionLibrary.CloseReason closeReason;
    }

    struct Routes {
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
    }

    struct Closable {
        bool isRiskyOrDelisted;
        bool canBeClosed;
        PositionLibrary.CloseReason closeReason;
    }

    struct CheckUpkeepParams {
        IBestDexLens.DexWithAncillaryData[] dexes;
        uint256 cursor;
        uint256 count;
        uint256 outputSize;
    }

    event ErrorHandled(uint256 indexed positionId, address indexed keeper, string reason);

    event PanicErrorHandled(uint256 indexed panicErrorId);

    event LowLevelErrorHandled(bytes revertReason);

    function pm() external returns (IPositionManager);

    function lom() external returns (ILimitOrderManager);

    function primexLens() external returns (IPrimexLens);

    function registry() external returns (address);

    function bestDexLens() external returns (IBestDexLens);

    /**
     * @dev This function is intended to be called off-chain. Do not call this from other contracts to avoid an out-of-gas error
     * @notice Checks the upkeep status and performs the necessary actions.
     * Should be called using callStatic to avoid gas fees
     * @param checkData The data needed to perform the upkeep check.
     * @param _dexesWithAncillaryData An array of DexWithAncillaryData structs.
     * @param _cursor The cursor for pagination.
     * @param _count The number of elements to retrieve.
     * @param _outputSize The desired output size.
     * @return newCursor The new cursor value. Cursor = 0 if no more elements are available.
     * @return upkeepNeeded A boolean indicating whether upkeep is needed.
     * @return performData Additional data needed to perform the upkeep.
     */
    function checkUpkeep(
        bytes calldata checkData,
        IBestDexLens.DexWithAncillaryData[] memory _dexesWithAncillaryData,
        uint256 _cursor,
        uint256 _count,
        uint256 _outputSize
    ) external returns (uint256 newCursor, bool upkeepNeeded, bytes memory performData);

    /**
     * @notice Liquidates positions or closes them by condition.
     * @param toLiquidate Array of LiquidatePositionInfo containing information about positions to be liquidated.
     * @param keeper The address of the keeper performing the upkeep.
     */
    function performUpkeepPositions(LiquidatePositionInfo[] calldata toLiquidate, address keeper) external;

    /**
     * @notice Equivalent to performUpkeepPositions() but lacking the try/catch block internally.
     * @param toLiquidate Array of LiquidatePositionInfo containing information about positions to be liquidated.
     * @param keeper The address of the keeper performing the upkeep.
     */
    function performUpkeepPositionsUnsafe(LiquidatePositionInfo[] calldata toLiquidate, address keeper) external;

    /**
     * @notice Executes limit orders based on the provided OpenByOrderInfo array.
     * @param toOpenByOrder The array of OpenByOrderInfo structs containing the necessary information to open positions.
     * @param keeper The address of the keeper performing the upkeep.
     */
    function performUpkeepOrders(OpenByOrderInfo[] calldata toOpenByOrder, address keeper) external;

    /**
     * @notice Equivalent to performUpkeepOrders() but lacking the try/catch block internally.
     * @param toOpenByOrder The array of OpenByOrderInfo structs containing the necessary information to open positions.
     * @param keeper The address of the keeper performing the upkeep.
     */
    function performUpkeepOrdersUnsafe(OpenByOrderInfo[] calldata toOpenByOrder, address keeper) external;

    /**
     * @notice Performs upkeep based on the given performData and keeper address.
     * @param performData The encoded performData containing information about the upkeep.
     * @param keeper The address of the keeper performing the upkeep.
     */
    function performUpkeep(bytes calldata performData, address keeper) external;

    /**
     * @notice Retrieves the closing parameters based on a condition.
     * @param ccm The address of the CloseConditionalManager contract.
     * @param secondAssetRoutes The array of second asset routes.
     * @return params The encoded closing parameters.
     */
    function getClosingParamsByCondition(
        address ccm,
        PrimexPricingLibrary.Route[] memory secondAssetRoutes
    ) external returns (bytes memory params);
}
