// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "./IEscrowTicketer.sol";
import "./IAuctionRunner.sol";
import "./ISeenHausNFT.sol";
import "./MarketHandlerBase.sol";

/**
 * @title AuctionOperatorFacet
 *
 * @notice Handles the operation of Seen.Haus auctions.
 *
 * @author Cliff Hall <cliff@futurescale.com> (https://twitter.com/seaofarrows)
 */
contract AuctionRunnerFacet is IAuctionRunner, MarketHandlerBase {

    // Threshold to auction extension window
    uint256 constant public extensionWindow = 15 minutes;

    /**
     * @dev Modifier to protect initializer function from being invoked twice.
     */
    modifier onlyUnInitialized()
    {

        MarketHandlerLib.MarketHandlerInitializers storage mhi = MarketHandlerLib.marketHandlerInitializers();
        require(!mhi.auctionRunnerFacet, "Initializer: contract is already initialized");
        mhi.auctionRunnerFacet = true;
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
        DiamondLib.addSupportedInterface(type(IAuctionRunner).interfaceId);
    }

    /**
     * @notice Change the audience for a auction.
     *
     * Reverts if:
     *  - Caller does not have ADMIN role
     *  - Auction doesn't exist or has already been settled
     *
     * @param _consignmentId - the id of the consignment being sold
     * @param _audience - the new audience for the auction
     */
    function changeAuctionAudience(uint256 _consignmentId, Audience _audience)
    external
    override
    onlyRole(ADMIN)
    {
        // Get Market Handler Storage struct
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get consignment (reverting if not valid)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the auction exists and hasn't been settled
        Auction storage auction = mhs.auctions[consignment.id];
        require(auction.start != 0, "Auction does not exist");
        require(auction.state != State.Ended, "Auction has already been settled");

        // Set the new audience for the consignment
        setAudience(consignment.id, _audience);

    }

    /**
     * @notice Bid on an active auction.
     *
     * If successful, the bidder's payment will be held and accepted as the standing bid.
     *
     * Reverts if:
     *  - Caller is not in audience
     *  - Caller is a contract
     *  - Auction doesn't exist or hasn't started
     *  - Auction timer has elapsed
     *  - Bid is below the reserve price
     *  - Bid is less than the outbid percentage above the standing bid, if one exists
     *
     * Emits a BidAccepted event on success.
     * May emit a AuctionStarted event, on the first bid.
     * May emit a AuctionExtended event, on bids placed in the last 15 minutes
     *
     * @param _consignmentId - the id of the consignment being sold
     */
    function bid(uint256 _consignmentId)
    external
    override
    payable
    onlyAudienceMember(_consignmentId)
    {
        // Get Market Handler Storage slot
        MarketHandlerLib.MarketHandlerStorage storage mhs = MarketHandlerLib.marketHandlerStorage();

        // Get the consignment (reverting if consignment doesn't exist)
        Consignment memory consignment = getMarketController().getConsignment(_consignmentId);

        // Make sure the auction exists
        Auction memory auction = mhs.auctions[consignment.id];
        require(auction.start != 0, "Auction does not exist");

        // Determine time after which no more bids will be accepted
        uint256 endTime = auction.start + auction.duration;

        // Make sure we can accept the caller's bid
        require(block.timestamp >= auction.start, "Auction hasn't started");
        if ((auction.state != State.Pending) || (auction.clock != Clock.Trigger)) {
            require(block.timestamp <= endTime, "Auction timer has elapsed");
        }
        require(msg.value >= auction.reserve, "Bid below reserve price");

        // Store current required refund values in memory
        uint256 previousBid = auction.bid;
        address payable previousBidder = payable(auction.buyer);

        // Record the new bid
        auction.bid = msg.value;
        auction.buyer = payable(msg.sender);
        getMarketController().setConsignmentPendingPayout(consignment.id, msg.value);

        // If this was the first successful bid...
        if (auction.state == State.Pending) {

            // First bid updates auction state to Running
            auction.state = State.Running;

            // For auctions where clock is triggered by first bid, update start time
            if (auction.clock == Clock.Trigger) {

                // Set start time
                auction.start = block.timestamp;

            }

            // Notify listeners of state change
            emit AuctionStarted(consignment.id);

        } else {

            // Should not apply to first bid
            // For bids placed within the extension window
            // Extend the duration so that auction still lasts for the length of the extension window
            if ((block.timestamp + extensionWindow) >= endTime) {
                auction.duration += (extensionWindow - (endTime - block.timestamp));
                emit AuctionExtended(_consignmentId);
            }

        }

        mhs.auctions[_consignmentId] = auction;

        // If a standing bid exists:
        // - Be sure new bid outbids previous
        // - Give back the previous bidder's money
        if (previousBid > 0) {
            require(msg.value >= (previousBid + getPercentageOf(previousBid, getMarketController().getOutBidPercentage())), "Bid too small");
            sendValueOrCreditAccount(previousBidder, previousBid);
            emit BidReturned(consignment.id, previousBidder, previousBid);
        }

        // Announce the bid
        emit BidAccepted(_consignmentId, auction.buyer, auction.bid);

    }

}