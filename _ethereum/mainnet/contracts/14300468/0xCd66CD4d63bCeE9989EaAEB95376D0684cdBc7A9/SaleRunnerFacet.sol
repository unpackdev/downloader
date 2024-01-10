// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "./IEscrowTicketer.sol";
import "./ISeenHausNFT.sol";
import "./ISaleRunner.sol";
import "./MarketHandlerBase.sol";

/**
 * @title SaleRunnerFacet
 *
 * @notice Handles the operation of Seen.Haus sales.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract SaleRunnerFacet is ISaleRunner, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {
        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.saleRunnerFacet, "already initialized");
        mhi.saleRunnerFacet = true;
        _;
    }

    /**
     * @notice Facet Initializer
     *
     * Register supported interfaces
     */
    function initialize()
    public
    onlyUnInitialized
    {
        DiamondLib.addSupportedInterface(type(ISaleRunner).interfaceId);
    }

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
    function changeSaleAudience(uint256 _consignmentId, Audience _audience)
    external
    override
    onlyRole(ADMIN)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get consignment (reverting if not valid)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the sale exists and hasn't been settled
        Sale storage sale = mhs.sales[consignment.id];
        require((sale.state != State.Ended) && (sale.start != 0), "already settled or non-existent");

        // Set the new audience for the consignment
        setAudience(_consignmentId, _audience);

    }

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
    function buy(uint256 _consignmentId, uint256 _amount)
    external
    override
    payable
    onlyAudienceMember(_consignmentId)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure we can accept the buy order & that the sale exists
        Sale storage sale = mhs.sales[_consignmentId];
        require((block.timestamp >= sale.start) && (sale.start != 0), "Sale hasn't started or non-existent");
        require(_amount <= sale.perTxCap, "Per tx limit exceeded");
        require(msg.value == sale.price * _amount, "Value doesn't cover price");

        // If this was the first successful purchase...
        if (sale.state == State.Pending) {

            // First buy updates sale state to Running
            sale.state = State.Running;

            // Notify listeners of state change
            emit SaleStarted(_consignmentId);

        }

        uint256 pendingPayoutValue = consignment.pendingPayout + msg.value;
        getMarketController().setConsignmentPendingPayout(consignment.id, pendingPayoutValue);

        // Determine if consignment is physical
        address nft = getMarketController().getNft();
        if (nft == consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(consignment.tokenId)) {

            // Issue an escrow ticket to the buyer
            address escrowTicketer = getMarketController().getEscrowTicketer(_consignmentId);
            IEscrowTicketer(escrowTicketer).issueTicket(_consignmentId, _amount, payable(msg.sender));

        } else {

            // Release the purchased amount of the consigned token supply to buyer
            getMarketController().releaseConsignment(_consignmentId, _amount, msg.sender);

        }

        // Announce the purchase
        emit Purchase(consignment.id, msg.sender, _amount, msg.value);

        // Track the sale info against the token itself
        emit TokenHistoryTracker(consignment.tokenAddress, consignment.tokenId, msg.sender, msg.value, _amount, consignment.id);
    }

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
    function claimPendingPayout(uint256 _consignmentId)
    external
    override
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get consignment
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Ensure that there is a pending payout & that caller is the seller
        require((consignment.pendingPayout > 0) && (consignment.seller == msg.sender));

        // Ensure that the sale has not yet sold out
        require((consignment.supply - consignment.releasedSupply) > 0, "sold out - use closeSale");

        // Make sure the sale exists and is running
        Sale storage sale = mhs.sales[_consignmentId];
        require((sale.state == State.Running) && (sale.start != 0), "Sale hasn't started or non-existent");

        // Distribute the funds (handles royalties, staking, multisig, and seller)
        getMarketController().setConsignmentPendingPayout(consignment.id, 0);
        disburseFunds(_consignmentId, consignment.pendingPayout);

    }

}