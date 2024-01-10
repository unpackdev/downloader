// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title ISaleEnder
 *
 * @notice Handles the finalization of Seen.Haus sales.
 *
 * The ERC-165 identifier for this interface is: 0x19b68d56
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface ISaleEnder is IMarketHandler {

    // Events
    event SaleEnded(uint256 indexed consignmentId, SeenTypes.Outcome indexed outcome);

    /**
     * @notice Close out a successfully completed sale.
     *
     * Funds are disbursed as normal. See: {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     * - Sale doesn't exist or hasn't started
     * - There is remaining inventory
     *
     * Emits a SaleEnded event.
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function closeSale(uint256 _consignmentId) external;

    /**
     * @notice Cancel a sale that has remaining inventory.
     *
     * Remaining tokens are returned to seller. If there have been any purchases,
     * the funds are distributed normally.
     *
     * Reverts if:
     * - Caller doesn't have ADMIN role
     * - Sale doesn't exist or has already been settled
     *
     * Emits a SaleEnded event
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function cancelSale(uint256 _consignmentId) external;

}