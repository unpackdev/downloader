// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./IJustice.sol";
import "./IRestore.sol";
import "./IWETH.sol";

/**
 * @title Justice
 *
 * Justice - a contract that creates unique NFTs to be auctioned off, using the Restore ERC721 Contract.
 *
 * Adapted from the wonderful Nounders.
 * https://github.com/nounsDAO/nouns-monorepo/blob/2cbe6c7bdfee258e646e8d9e84302375320abc72/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
 *
 * Once auctioned, this contract does not immediatedly transfer the art, but 'freezes' it, while ensuring that the steward of the system,
 * which is multisig maintained by Pr1s0n Art Inc - a 501(c)3 registered in Florida - can only ever transfer them to the winning bidder.
 * Pr1s0n Art takes the funds raised from the sale, exchanges them into USD, pays the Legal Financial Obligations of the people who
 * made the art and then reattaches the receipts as the `data` in `transferToBuyer`, which uses the `safeTransfer` method in the
 * ERC721 standard.
 *
 * This means you receive not just the art, but the full story - aesthetic, economic, and sociopolitical - of a human being's journey
 * home. This contract enacts restorative justice because, unless we are all involved with justice, we will never realise it fully.
 */
                                                                                                                                                                           
//      ██╗██╗   ██╗███████╗████████╗   ██╗███████╗
//      ██║██║   ██║██╔════╝╚══██╔══╝   ██║██╔════╝
//      ██║██║   ██║███████╗   ██║█████╗██║███████╗
// ██   ██║██║   ██║╚════██║   ██║╚════╝██║╚════██║
// ╚█████╔╝╚██████╔╝███████║   ██║      ██║███████║
//  ╚════╝  ╚═════╝ ╚══════╝   ╚═╝      ╚═╝╚══════╝
                                                
contract Justice is IJustice, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    // The Restore ERC721 token contract
    IRestore public restore;

    // The address of the WETH contract
    address public weth;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The minimum percentage difference between the last bid amount and the current bid
    uint8 public minBidIncrementPercentage;

    // The duration of a single auction
    uint256 public duration;

    // The active auction
    IJustice.Auction public auction;

    // The contract that handles sale splits
    address payment;

    // The address of the pr1s0nart onchain fund for operations
    address fund;

    /**
     * @notice Set up the Justice Auction House and prepopulate initial values
     */
    constructor(
        IRestore _restore,
        address _weth,
        address _payment,
        address _fund,
        uint256 _timeBuffer,
        uint256 _reservePrice,
        uint8 _minBidIncrementPercentage,
        uint256 _duration
    ) {
        restore = _restore;
        weth = _weth;
        payment = _payment;
        fund = _fund;
        timeBuffer = _timeBuffer;
        reservePrice = _reservePrice;
        minBidIncrementPercentage = _minBidIncrementPercentage;
        duration = _duration;
    }

    /**
     * @notice Settle the current auction.
     * @dev This function can only be called when the contract is paused.
     */
    function settleAuction() 
        external 
        override 
        nonReentrant 
    {
        _settleAuction();
    }

    /**
     * @notice Create a bid for a pr1s0n.art piece, with a given amount.
     * @dev This contract only accepts payment in ETH.
     */
    function createBid(uint256 tokenId) 
        external 
        payable 
        override 
        nonReentrant 
    {
        IJustice.Auction memory _auction = auction;

        require(_auction.tokenId == tokenId, 'Justice: Art not up for auction');
        require(block.timestamp < _auction.endTime, 'Justice: Auction expired');
        require(msg.value >= reservePrice, 'Justice: Must send at least reservePrice');
        require(
            msg.value >= _auction.amount + ((_auction.amount * minBidIncrementPercentage) / 100),
            'Justice: Must send more than last bid by minBidIncrementPercentage amount'
        );

        address payable lastBidder = _auction.bidder;

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
        }

        emit AuctionBid(_auction.tokenId, msg.sender, msg.value, extended);

        if (extended) {
            emit AuctionExtended(_auction.tokenId, _auction.endTime);
        }

        // Refund the last bidder, if applicable
        if (lastBidder != address(0)) {
            _safeTransferETHWithFallback(lastBidder, _auction.amount);
        }
    }

    /**
     * @notice Set the pr1s0nart payment address (handles exchange to USD + LFO payments).
     * @dev Only callable by the owner.
     */
    function setPaymentAddress(address _newPayment) 
        external 
        override 
        onlyOwner 
    {
        payment = _newPayment;

        emit PaymentAddressUpdated(_newPayment);
    }

    /**
     * @notice Set the pr1s0nartFund address (handles onchain fund for operations)
     * @dev Only callable by the owner.
     */
    function setFundAddress(address _newFund) 
        external 
        override 
        onlyOwner 
    {
        fund = _newFund;

        emit FundAddressUpdated(_newFund);
    }

    /**
     * @notice Set the auction time buffer.
     * @dev Only callable by the owner.
     */
    function setTimeBuffer(uint256 _timeBuffer) 
        external 
        override 
        onlyOwner 
    {
        timeBuffer = _timeBuffer;

        emit AuctionTimeBufferUpdated(_timeBuffer);
    }

    /**
     * @notice Set the duration for auctions.
     * @dev Only callable by the owner.
     */
    function setDuration(uint256 _duration) 
        external 
        override 
        onlyOwner 
    {
        duration = _duration;

        emit AuctionDurationUpdated(_duration);
    }

    /**
     * @notice Set the auction reserve price.
     * @dev Only callable by the owner.
     */
    function setReservePrice(uint256 _reservePrice) 
        external 
        override 
        onlyOwner 
    {
        reservePrice = _reservePrice;

        emit AuctionReservePriceUpdated(_reservePrice);
    }

    /**
     * @notice Set the auction minimum bid increment percentage.
     * @dev Only callable by the owner.
     */
    function setMinBidIncrementPercentage(uint8 _minBidIncrementPercentage) 
        external 
        override 
        onlyOwner 
    {
        minBidIncrementPercentage = _minBidIncrementPercentage;

        emit AuctionMinBidIncrementPercentageUpdated(_minBidIncrementPercentage);
    }

    /**
     * @notice Create an auction.
     * @param creator the address of the creator so we can pass it to the payment splitter once the auction is settled.
     * @param tokenId the index of the art piece to be auctioned off
     * @param split a fixed-sized array of max 3 members which determines how sale proceeds are split between pr1s0nartPayment
     *              (the address that exchanges into USD and pays LFOs), pr1s0nartFund (our onchain fund to cover operations),
     *              and the creator address if they have one and can receive crypto in addition to the LFO payments we cover.
     *              This is likely only the case if they are no longer incarcerated and have an ETH address.
     */
    function createAuction(address creator, uint256 tokenId, uint8[3] memory split) 
        external 
        onlyOwner 
    {
            require(restore.auctionable(tokenId) && address(restore) == restore.ownerOf(tokenId), 'Justice: token id is not auctionable');
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                saleSplit: split,
                creator: creator,
                tokenId: tokenId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(tokenId, split, creator, startTime, endTime);
    }

    /**
     * @notice Settle an auction, freezing the tokenId to the buyer's address and sending the funds to pr1s0n.art for processing.
     * @dev If there are no bids, the art is transferred back to pr1s0n.art
     */
    function _settleAuction() 
        internal 
    {
        IJustice.Auction memory _auction = auction;

        require(_auction.startTime != 0, "Justice: Auction hasn't begun");
        require(!_auction.settled, 'Justice: Auction has already been settled');
        require(block.timestamp >= _auction.endTime, "Justice: Auction hasn't completed");

        auction.settled = true;
        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);

        if (_auction.bidder == address(0)) {
            emit NoBuyer(_auction.tokenId);
        } else {
            restore.freeze(_auction.bidder, _auction.tokenId);
        }

        if (_auction.amount > 0) {
            uint256 LFOShare = (_auction.saleSplit[0] * _auction.amount / 100 );
            _safeTransferETHWithFallback(payment, LFOShare);
            uint256 PAShare = (_auction.saleSplit[1] * _auction.amount / 100 );
            _safeTransferETHWithFallback(fund, PAShare);
            // We do this to ensure effectively 100% of the sale proceeds get distributed and to guard against weird % edge cases
            uint256 creatorShare = _auction.amount - LFOShare - PAShare;
            _safeTransferETHWithFallback(_auction.creator, creatorShare);
        }
    }

    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     * @param recipient the address of the receiver
     * @param amount the total amount
     */
    function _safeTransferETHWithFallback(address recipient, uint256 amount) 
        internal 
    {
        if (!_safeTransferETH(recipient, amount)) {
            IWETH(weth).deposit{ value: amount }();
            IERC20(weth).safeTransfer(recipient, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     */
    function _safeTransferETH(address recipient, uint256 amount) 
        internal 
        returns (bool) 
    {
        (bool success, ) = recipient.call{value: amount, gas: 30_000 }(new bytes(0));
        return success;
    }

}
