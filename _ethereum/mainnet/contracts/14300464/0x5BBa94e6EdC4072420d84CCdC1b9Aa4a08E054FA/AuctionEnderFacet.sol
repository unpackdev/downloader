// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "./IEscrowTicketer.sol";
import "./IAuctionEnder.sol";
import "./ISeenHausNFT.sol";
import "./MarketHandlerBase.sol";

/**
 * @title AuctionEnderFacet
 *
 * @notice Handles the operation of Seen.Haus auctions.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract AuctionEnderFacet is IAuctionEnder, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {

        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.auctionEnderFacet, "Initializer: contract is already initialized");
        mhi.auctionEnderFacet = true;
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
        DiamondLib.addSupportedInterface(type(IAuctionEnder).interfaceId);
    }

    /**
     * @notice Close out a successfully completed auction.
     *
     * Funds are disbursed as normal. See {MarketHandlerBase.disburseFunds}
     *
     * Reverts if:
     *  - Auction doesn't exist
     *  - Auction timer has not yet elapsed
     *  - Auction has not yet started
     *  - Auction has already been settled
     *  - Bids have been placed
     *
     * Emits a AuctionEnded event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function closeAuction(uint256 _consignmentId)
    external
    override
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the auction exists
        Auction storage auction = mhs.auctions[_consignmentId];
        require(auction.start != 0, "Auction does not exist");

        // Make sure timer has elapsed
        uint256 endTime = auction.start + auction.duration;
        require(block.timestamp > endTime, "Auction end time not yet reached");

        // Make sure auction hasn't been settled
        require(auction.outcome == Outcome.Pending, "Auction has already been settled");

        // Make sure it there was at least one bid
        require(auction.buyer != address(0), "No bids have been placed");

        // Mark auction as settled
        auction.state = State.Ended;
        auction.outcome = Outcome.Closed;

        // Distribute the funds (pay royalties, staking, multisig, and seller)
        getMarketController().setConsignmentPendingPayout(consignment.id, 0);
        disburseFunds(_consignmentId, consignment.pendingPayout);

        // Determine if consignment is physical
        address nft = getMarketController().getNft();
        if (nft == consignment.tokenAddress && ISeenHausNFT(nft).isPhysical(consignment.tokenId)) {

            // For physicals, issue an escrow ticket to the buyer
            address escrowTicketer = getMarketController().getEscrowTicketer(_consignmentId);
            IEscrowTicketer(escrowTicketer).issueTicket(_consignmentId, 1, auction.buyer);

        } else {

            // Release the purchased amount of the consigned token supply to buyer
            getMarketController().releaseConsignment(_consignmentId, 1, auction.buyer);

        }

        // Notify listeners about state change
        emit AuctionEnded(consignment.id, auction.outcome);

        // Track the winning bid info against the token itself
        emit TokenHistoryTracker(consignment.tokenAddress, consignment.tokenId, auction.buyer, auction.bid, consignment.supply, consignment.id);

    }    

    /**
     * @notice Cancel an auction
     *
     * If there is a standing bid, it is returned to the bidder.
     * Consigned inventory will be transferred back to the seller.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role or is not consignor
     *  - Auction doesn't exist
     *  - Auction has already been settled
     *
     * Emits a AuctionEnded event on success.
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function cancelAuction(uint256 _consignmentId)
    external
    override
    onlyRoleOrConsignor(ADMIN, _consignmentId)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure auction exists
        Auction storage auction = mhs.auctions[_consignmentId];
        require(auction.start != 0, "Auction does not exist");

        // Make sure auction hasn't been settled
        require(auction.state != State.Ended, "Auction has already been settled");

        // Mark auction as settled
        auction.state = State.Ended;
        auction.outcome = Outcome.Canceled;

        getMarketController().setConsignmentPendingPayout(consignment.id, 0);

        // Give back the previous bidder's money
        if (auction.bid > 0) {
            sendValueOrCreditAccount(auction.buyer, auction.bid);
            emit CanceledAuctionBidReturned(_consignmentId, auction.buyer, auction.bid);
        }

        // Release the consigned token supply to seller
        getMarketController().releaseConsignment(_consignmentId, 1, consignment.seller);

        // Notify listeners about state change
        emit AuctionEnded(_consignmentId, auction.outcome);

    }

}