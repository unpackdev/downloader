// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./PrimexPricingLibrary.sol";

import "./IPositionManager.sol";
import "./ILimitOrderManager.sol";

interface IBestDexLens {
    /**
     * @dev Structure for the getBestDexForOpenablePosition function
     * @param positionManager Instance of the PositionManager
     * @param borrowedAsset The address of the borrowed asset of this `bucket`
     * @param borrowedAmount The amount of borrowed token in this position
     * @param depositAsset The address of the deposited asset
     * @param depositAmount The amount of deposited trader funds of open position
     * @param positionAsset The address of the bought asset of open position
     * @param shares The number of parts into which the swap will be divided
     * @param dexes An array with dexes by which the algorithm will iterate
     */
    struct BestDexForOpenablePositionParams {
        IPositionManager positionManager;
        address borrowedAsset;
        uint256 borrowedAmount;
        address depositAsset;
        uint256 depositAmount;
        address positionAsset;
        Shares shares;
        DexWithAncillaryData[] dexes;
    }

    /**
     * @dev Structure for different shares for swap
     * @param firstAssetShares Shares for swap first asset to position asset
     * @param depositInThirdAssetShares Shares for swap deposit asset to third asset
     * @param depositToBorrowedShares Shares for swap deposit asset to borrowed asset
     */
    struct Shares {
        uint256 firstAssetShares;
        uint256 depositInThirdAssetShares;
        uint256 depositToBorrowedShares;
    }

    /**
     * @param dex The name of dex
     * @param ancillaryData Additional data required for certain dex type.
     */
    struct DexWithAncillaryData {
        string dex;
        bytes32 ancillaryData;
    }

    /**
     * @dev Structure for the getBestDexByOrderParams function
     * @param positionManager instance of the PositionManager
     * @param limitOrderManager instance of the LimitOrderManager
     * @param orderId order id
     * @param dexes dexes with ancillary data
     */
    struct BestDexByOrderParams {
        IPositionManager positionManager;
        ILimitOrderManager limitOrderManager;
        uint256 orderId;
        Shares shares;
        DexWithAncillaryData[] dexes;
    }

    /**
     * @dev Structure for the input params for getBestMultipleDexes
     * @param positionManager instance of the PositionManager
     * @param assetToBuy address
     * @param assetToSell address
     * @param amount amount to sell or amount to buy depending on the isAmountToBuy
     * @param isAmountToBuy if true, then the best value, found via getAmountsIn
     * @param shares The number of parts into which the swap will be divided
     * @param gasPriceInCheckedAsset gas Price in asset to sell or asset to buy depending on the isAmountToBuy
     * @param dexes An array with dexes by which the algorithm will iterate
     */
    struct GetBestMultipleDexesParams {
        IPositionManager positionManager;
        address assetToBuy;
        address assetToSell;
        uint256 amount;
        bool isAmountToBuy;
        uint256 shares;
        uint256 gasPriceInCheckedAsset;
        DexWithAncillaryData[] dexes;
    }

    /**
     * @dev Structure for the getBestMultipleDexes function
     * @param shareCount Number of shares
     * @param filledRoutes Number of filled routes
     * @param path Path of assets
     * @param activeDexesLength Count of active dexes
     * @param gasInCheckedAsset The paid price for gas in the purchase token
     * @param gases Estimated gas to perform swap on each dex
     */
    struct GetBestMultipleDexesVars {
        uint256 shareCount;
        uint256 filledRoutes;
        address[] path;
        uint256 activeDexesLength;
        int256 gasInCheckedAsset;
        uint256[] gases;
    }

    /**
     * @dev Structure for the return params for getBestMultipleDexes
     * @param returnAmount expected return amount
     * @param estimateGasAmount expected fee amount
     * @param routes swap routes on dexes
     */
    struct GetBestMultipleDexesReturnParams {
        uint256 returnAmount;
        uint256 estimateGasAmount;
        PrimexPricingLibrary.Route[] routes;
    }

    /**
     * @dev Structure for the function getBestDex through the buy parameters
     * @param assetToBuy Asset to buy on the dex(=_positionAsset in function openPosition)
     * @param assetToSell Asset for sell on the dex(= an asset borrowed from a bucket)
     * @param amountToSell Amount `assetToSell`(=borrowedAmount in function openPosition)
     */
    struct BuyData {
        address assetToBuy;
        address assetToSell;
        uint256 amountToSell;
    }

    /**
     * @dev Structure for the getBestDexByOrder function
     * @param firstAssetReturnParams GetBestMultipleDexesReturnParams for the first asset to position asset
     * @param depositInThirdAssetReturnParams GetBestMultipleDexesReturnParams for deposit asset to third asset
     * @param depositToBorrowedReturnParams GetBestMultipleDexesReturnParams for deposit asset to borrowed asset
     */
    struct GetBestDexByOrderReturnParams {
        GetBestMultipleDexesReturnParams firstAssetReturnParams;
        GetBestMultipleDexesReturnParams depositInThirdAssetReturnParams;
        GetBestMultipleDexesReturnParams depositToBorrowedReturnParams;
    }

    /**
     * @notice Returns swap paths on best dexes, expected amount and estimateGasAmount.
     * @dev This function calculates the best DEX to use for a given position based on various parameters.
     * @param _positionManager The instance of the PositionManager contract.
     * @param _positionId The ID of the position.
     * @param _shares The number of shares for dexes.
     * @param _dexesWithAncillaryData An array of DEXes along with their ancillary data.
     * @return A GetBestMultipleDexesReturnParams struct.
     */
    function getBestDexByPosition(
        IPositionManager _positionManager,
        uint256 _positionId,
        uint256 _shares,
        DexWithAncillaryData[] memory _dexesWithAncillaryData
    ) external returns (GetBestMultipleDexesReturnParams memory);

    /**
     * @notice Selects the best dex to open position by order.
     * @param _params The BestDexByOrderParams struct specifying the order parameters.
     * @return _returnParams The GetBestDexByOrderReturnParams struct
     */
    function getBestDexByOrder(
        BestDexByOrderParams memory _params
    ) external returns (GetBestDexByOrderReturnParams memory _returnParams);

    /**
     * @notice Selects the best multiple dexes to open a position
     * @param _params GetBestMultipleDexesParams params
     * @return _returnParams - the array of best dexes at the moment to open a position with the specified parameters
     */
    function getBestMultipleDexes(
        GetBestMultipleDexesParams memory _params
    ) external returns (GetBestMultipleDexesReturnParams memory _returnParams);

    /**
     * @notice Returns the best DEXes for opening a position.
     * @param _params The parameters for the function.
     * @return _firstAssetReturnParams The return parameters for the first asset.
     * @return _depositInThirdAssetReturnParams The return parameters includes routes for converting a third asset
     * (i.e. an asset which is not either underlying asset or position asset) to a position asset.
     * @return _depositToBorrowedReturnParams The return parameters for converting deposit asset (which is a position
     * asset or third asset) to borrowed asset (i.e. underlying asset).
     */
    function getBestDexForOpenablePosition(
        BestDexForOpenablePositionParams memory _params
    )
        external
        returns (
            GetBestMultipleDexesReturnParams memory _firstAssetReturnParams,
            GetBestMultipleDexesReturnParams memory _depositInThirdAssetReturnParams,
            GetBestMultipleDexesReturnParams memory _depositToBorrowedReturnParams
        );

    /**
     * @notice the function shows the profit/loss of a position with `_id`
     * (in case of loss position, a negative number is issued) on dex `_dexName`
     * @param _positionManager The address of the PositionManager where the position is stored
     * @param _id Position id to calculate profit.
     * @param _routes swap routes on dexes
     */
    function getPositionProfit(
        address _positionManager,
        uint256 _id,
        PrimexPricingLibrary.Route[] calldata _routes
    ) external returns (int256);

    /**
     * @notice The function returns the current price and profit for open position with `_id` on the best dex
     * @param _positionManager The instance of the PositionManager where the position is stored
     * @param _id Position id to show the parameters position
     * @param _shares shares for expected close
     * @param _dexes dexes with ancillary data
     */
    function getCurrentPriceAndProfitByPosition(
        IPositionManager _positionManager,
        uint256 _id,
        uint256 _shares,
        DexWithAncillaryData[] memory _dexes
    ) external returns (uint256, int256);

    /**
     * @notice The function returns an array of the current price and the profit for open position with `_id` on the best dex
     * @param _positionManager The instance of the PositionManager where the position is stored
     * @param _ids Array of position ids to show the parameters position
     * @param _shares shares for expected close
     * @param _dexes Array of dexes with ancillary data
     */
    function getArrayCurrentPriceAndProfitByPosition(
        IPositionManager _positionManager,
        uint256[] memory _ids,
        uint256[] memory _shares,
        DexWithAncillaryData[][] memory _dexes
    ) external returns (uint256[] memory, int256[] memory);

    /**
     * @notice Calculates the amount of output token that can be obtained for a given input token amount
     * and pricing parameters.
     * @param _params The input parameters for the calculation.
     * @return The calculated output amount.
     */
    function getAmountOut(PrimexPricingLibrary.AmountParams memory _params) external returns (uint256);

    /**
     * @notice Calculates the amount of tokens to be received in exchange for a given amount of input tokens,
     * based on the provided pricing parameters.
     * @param _params The pricing parameters for calculating the token amount.
     * @return The amount of tokens to be received.
     */
    function getAmountIn(PrimexPricingLibrary.AmountParams memory _params) external returns (uint256);
}
