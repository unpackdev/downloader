// (c) 2023 Primex.finance
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "./LimitOrderLibrary.sol";
import "./PrimexPricingLibrary.sol";

interface IConditionalOpeningManager {
    /**
     * @notice Checks if a limit order can be filled.
     * Is used as a view function outside transactions and allows to check whether a specific order can be executed imitating the swap.
     * @param _order The limit order details.
     * @param _params Open condition parameters for the order.
     * @param _additionalParams Additional parameters for the order.
     * @return A boolean value indicating if the limit order can be filled.
     */
    function canBeFilledBeforeSwap(
        LimitOrderLibrary.LimitOrder calldata _order,
        bytes calldata _params,
        bytes calldata _additionalParams
    ) external returns (bool);

    /**
     * @notice Checks if a limit order can be filled based on the exchange rate.
     * @dev This function compares the exchange rate with the limit price.
     * @param _order The limit order details.
     * @param _params Open condition parameters for the order.
     * @param _additionalParams Additional parameters for the order.
     * @param _exchangeRate The exchange rate in WAD format to compare with the limit price.
     * @return A boolean value indicating if the limit order can be filled based on the exchange rate.
     */
    function canBeFilledAfterSwap(
        LimitOrderLibrary.LimitOrder calldata _order,
        bytes calldata _params,
        bytes calldata _additionalParams,
        uint256 _exchangeRate
    ) external pure returns (bool);
}
