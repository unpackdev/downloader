// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./PositionLibrary.sol";
import "./LimitOrderLibrary.sol";
import "./PrimexPricingLibrary.sol";

interface IConditionalClosingManager {
    /**
     * @notice Checks if a position can be closed.
     * @param _position The position details.
     * @param _params The encoded parameters for closing the position.
     * @param _additionalParams Additional encoded parameters.
     * @return A boolean indicating whether the position can be closed.
     */
    function canBeClosedBeforeSwap(
        PositionLibrary.Position calldata _position,
        bytes calldata _params,
        bytes calldata _additionalParams
    ) external returns (bool);

    /**
     * @notice Checks if a position can be closed.
     * @param _position The position details.
     * @param _params The encoded parameters for closing the position.
     * @param _additionalParams Additional encoded parameters (not used).
     * @param _closeAmount The amount of the position to be closed, measured in the same decimal format as the position's asset.
     * @param _borowedAssetAmount The amount of borrowed asset.
     * @return A boolean indicating whether the position can be closed.
     */
    function canBeClosedAfterSwap(
        PositionLibrary.Position calldata _position,
        bytes calldata _params,
        bytes calldata _additionalParams,
        uint256 _closeAmount,
        uint256 _borowedAssetAmount
    ) external returns (bool);
}
