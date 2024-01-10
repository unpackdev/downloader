// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./SeenTypes.sol";
import "./IMarketHandler.sol";

/**
 * @title ISaleRunner
 *
 * @notice Handles the operation of Seen.Haus sales.
 *
 * The ERC-165 identifier for this interface is: 0xe1bf15c5
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
interface ISaleRunner is IMarketHandler {

    // Events
    event SaleStarted(uint256 indexed consignmentId);
    event Purchase(uint256 indexed consignmentId, address indexed buyer, uint256 amount, uint256 value);
    event TokenHistoryTracker(address indexed tokenAddress, uint256 indexed tokenId, address indexed buyer, uint256 value, uint256 amount, uint256 consignmentId);

    /**
     * @notice Change the audience for a sale.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role
     *  - Auction doesn't exist or has already been settled
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _audience - the new audience for the sale
     */
    function changeSaleAudience(uint256 _consignmentId, SeenTypes.Audience _audience) external;

    /**
     * @notice Buy some amount of the remaining supply of the lot for sale.
     *
     * Ownership of the purchased inventory is transferred to the buyer.
     * The buyer's payment will be held for disbursement when sale is settled.
     *
     * Reverts if:
     *  - Caller is not in audience
     *  - Sale doesn't exist or hasn't started
     *  - Caller is a contract
     *  - The per-transaction buy limit is exceeded
     *  - Payment doesn't cover the order price
     *
     * Emits a Purchase event.
     * May emit a SaleStarted event, on the first purchase.
     *
     * @param _consignmentId - id of the consignment being sold
     * @param _amount - the amount of the remaining supply to buy
     */
    function buy(uint256 _consignmentId, uint256 _amount) external payable;

    /**
     * @notice Claim a pending payout on an ongoing sale without closing/cancelling
     *
     * Funds are disbursed as normal. See: {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     * - Sale doesn't exist or hasn't started
     * - There is no pending payout
     * - Called by any address other than seller
     * - The sale is sold out (in which case closeSale should be called)
     *
     * Does not emit its own event, but disburseFunds emits an event
     *
     * @param _consignmentId - id of the consignment being sold
     */
    function claimPendingPayout(uint256 _consignmentId) external;

}