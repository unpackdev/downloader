//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./EditionData.sol";
import "./BaseAuction.sol";
import "./INft.sol";
import "./Testable.sol";
import "./SafeMath.sol";

contract BaseEdition is BaseAuction, EditionData, Testable {
    using SafeMath for uint256;

    event PurchaseOnLot(
        uint256 indexed lotId,
        uint256 noPurchased,
        address indexed bidder,
        uint256 amountPaid
    );

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(address _registry, address _timer)
        BaseAuction(_registry)
        EditionData()
        Testable(_timer)
    {}

    /**
     * @param   _lotID The lot ID
     * @notice  Returns the original token to the owner. Can only be called if
     *          the lot has expired.
     */
    function returnOriginal(uint256 _lotID) external {
        require(
            lotPrices_[_lotID].endTime <= getCurrentTime(),
            "Lot has not expired"
        );
        _returnOriginalToken(_lotID);
    }

    // -----------------------------------------------------------------------
    // INTERNAL STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function _returnOriginalToken(uint256 _lotID) internal {
        nftInstance_.transfer(lots_[_lotID].owner, lots_[_lotID].tokenID);
        // Setting on the auction hub that the first sale is completed
        auctionHubInstance_.firstSaleCompleted(lots_[_lotID].tokenID);
        auctionHubInstance_.lotAuctionCompletedAndClaimed(auctionID_, _lotID);
    }

    /**
     * @param   _lotID The ID of the lot
     * @param   _editionAmount How many tokens to buy
     * @notice  This function will revert if the bid amount is not higher than
     *          the current highest bid and the min bid price for the lot.
     */
    function _bid(uint256 _lotID, uint256 _editionAmount) internal {
        // Will revert if lot is not in biddable state
        _isLotInBiddableState(_lotID);
        // Checks that lot has started (timestamp checks)
        require(_isLotBiddable(_lotID), "Lot has not started or ended");
        // Ensures that if there is limited stock, cannot buy more than stock.
        if (lotPrices_[_lotID].useMaxStock) {
            require(
                lotPrices_[_lotID].maxStock >=
                    lotPrices_[_lotID].tokensMinted.add(_editionAmount),
                "Cannot buy more than max stock"
            );
        }
        // Ensures that if there is a max buy per tx, cannot buy more than max.
        if (lotPrices_[_lotID].maxBatchBuy != 0) {
            require(
                lotPrices_[_lotID].maxBatchBuy >= _editionAmount,
                "Cannot buy more than max batch"
            );
        }
        // Getting the cost to buy the desired edition amount
        uint256 cost = lotPrices_[_lotID].pricePerEdition.mul(_editionAmount);
        // Ensuring sent value is sufficient
        require(cost <= msg.value, "Insufficient msg.value");

        lotPrices_[_lotID].tokensMinted = lotPrices_[_lotID].tokensMinted.add(
            _editionAmount
        );

        _handlePayment(_lotID, cost);

        // All event data will come from the NFT contract
        nftInstance_.batchDuplicateMint(
            msg.sender,
            _editionAmount,
            lotPrices_[_lotID].tokenID,
            lotPrices_[_lotID].useMaxStock
        );

        emit PurchaseOnLot(_lotID, _editionAmount, msg.sender, cost);
    }

    /**
     * @param   _lotID The ID of the lot
     * @notice  This function will not revert. This function will return false
     *          if the lot has not reached the start time, or is passed the end
     *          time. This function will return true if the lot is between
     *          it's start and end time.
     */
    function _isLotBiddable(uint256 _lotID) internal returns (bool) {
        // If the end time has not passed
        if (lotPrices_[_lotID].endTime > getCurrentTime()) {
            // If the start time has passed
            if (getCurrentTime() >= lotPrices_[_lotID].startTime) {
                // If biddable has not been set to true
                if (lotPrices_[_lotID].biddable == false) {
                    // Setting the auction to active on the hub
                    auctionHubInstance_.lotAuctionStarted(auctionID_, _lotID);
                    lotPrices_[_lotID].biddable = true;
                }
                // Start time has passed
                return true;
            }
            // Start time has not passed
            return false;
        } else {
            // If end time has passed lot is set to not biddable
            lotPrices_[_lotID].biddable = false;
            // Lot status updated on hub to complete 
            auctionHubInstance_.lotAuctionCompleted(auctionID_, _lotID);
            return false;
        }
    }

    function _handlePayment(uint256 _lotID, uint256 _totalCollateralAmount)
        internal
    {
        require(
            auctionHubInstance_.isFirstSale(lots_[_lotID].tokenID),
            "Not first sale"
        );
        // Temporary storage for splits and shares
        uint256 creatorSplit;
        uint256 systemSplit;
        uint256 creatorShare;
        uint256 systemShare;
        // Getting the split for the
        (creatorSplit, systemSplit) = auctionHubInstance_.getFirstSaleSplit();
        // Working out the creators share according to the split
        creatorShare = _totalCollateralAmount.mul(creatorSplit).div(
            SPLIT_SCALING_FACTOR
        );
        // Working out the systems share according to the split
        systemShare = _totalCollateralAmount.mul(systemSplit).div(
            SPLIT_SCALING_FACTOR
        );
        require(
            creatorShare.add(systemShare) <= _totalCollateralAmount,
            "BAU: Fatal: value mismatch"
        );
        // Depositing creator share
        royaltiesInstance_.deposit{value: creatorShare}(
            nftInstance_.creatorOf(lots_[_lotID].tokenID),
            creatorShare
        );
        // Depositing the system share
        royaltiesInstance_.deposit{value: systemShare}(address(0), systemShare);
    }
}
