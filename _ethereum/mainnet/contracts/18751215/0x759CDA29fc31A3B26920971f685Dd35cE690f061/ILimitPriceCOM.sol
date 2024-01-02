// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./PrimexPricingLibrary.sol";

interface ILimitPriceCOM {
    struct CanBeFilledParams {
        uint256 limitPrice;
    }

    struct AdditionalParams {
        PrimexPricingLibrary.Route[] firstAssetRoutes;
        PrimexPricingLibrary.Route[] depositInThirdAssetRoutes;
    }

    struct CanBeFilledVars {
        CanBeFilledParams params;
        AdditionalParams additionalParams;
        address borrowedAsset;
        uint256 amountIn;
        uint256 amountOut;
        uint256 amountToTransfer;
        address dexAdapter;
        bool isThirdAsset;
        uint256 borrowedAssetMultiplier;
        uint256 exchangeRate;
        uint256 depositInPositionAsset;
        uint256 borrowedAmountInPositionAsset;
    }

    /**
     * @notice Retrieves the limit price from the provided `_params` input.
     * @dev To use this function correctly, you need to encode a CanBeFilledParams struct into the _params parameter.
     * The CanBeFilledParams struct has field limitPrice.
     * @param _params The encoded parameters containing the limit price information.
     * @return The limit price extracted from the `_params`.
     */
    //TODO Consider removing this function from the protocol as it is currently unused.
    function getLimitPrice(bytes calldata _params) external view returns (uint256);
}
