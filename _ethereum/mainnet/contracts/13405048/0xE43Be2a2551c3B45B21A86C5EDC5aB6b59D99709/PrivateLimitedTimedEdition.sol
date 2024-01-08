//SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "./BasePrivateEdition.sol";
import "./SafeMath.sol";

contract PrivateLimitedTimedEdition is BasePrivateEdition {
    using SafeMath for uint256;

    event LotCreated(
        uint256 pricePerEdition,
        uint256 startTime,
        uint256 endTime,
        uint256 lotID,
        uint256 tokenID,
        uint256 auctionID,
        address[] validBuyers
    );

    // -----------------------------------------------------------------------
    // CONSTRUCTOR
    // -----------------------------------------------------------------------

    constructor(address _registry, address _timer)
        BasePrivateEdition(_registry, _timer)
    {}

    // -----------------------------------------------------------------------
    // NON-STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    function getLotInfo(uint256 _lotID)
        external
        view
        returns (
            uint256 tokenID,
            address owner,
            uint256 price,
            uint256 startTime,
            uint256 endTime,
            bool maxBuyPerTx,
            uint256 maxBuy,
            uint256 maxSupply,
            bool biddable
        )
    {
        tokenID = lots_[_lotID].tokenID;
        owner = lots_[_lotID].owner;
        price = lotPrices_[_lotID].pricePerEdition;
        startTime = lotPrices_[_lotID].startTime;
        endTime = lotPrices_[_lotID].endTime;
        maxBuy = lotPrices_[_lotID].maxBatchBuy;
        maxBuy == 0 ? maxBuyPerTx = false : maxBuyPerTx = true;
        maxSupply = lotPrices_[_lotID].maxStock;
        biddable = lotPrices_[_lotID].biddable;
    }

    // -----------------------------------------------------------------------
    // PUBLICLY ACCESSIBLE STATE MODIFYING FUNCTIONS
    // -----------------------------------------------------------------------

    /**
     * @param   _lotID ID of the new lot auction being created within this
     *          auction instance.
     * @param   _tokenID ID of the token being sold in the auction type.
     * @dev     Only the Auction Hub is able to call this function.
     */
    function createLot(
        uint256 _lotID,
        uint256 _tokenID,
        uint256 _pricePerEdition,
        uint256 _startTimeStamp,
        uint256 _endTimeStamp,
        bool _maxBuyPerTx,
        uint256 _maxBuy,
        uint256 _maxSupply,
        address[] calldata _validBuyers
    ) external {
        require(_pricePerEdition != 0, "Lot price cannot be 0");
        require(_startTimeStamp < _endTimeStamp, "End time before start");
        require(
            _endTimeStamp > getCurrentTime(),
            "End time cannot be before current"
        );
        // If there is a max buy limit per batch buy transaction
        if (_maxBuyPerTx) {
            lotPrices_[_lotID].maxBatchBuy = _maxBuy;
        }
        // Storing the price for the lot
        lotPrices_[_lotID].pricePerEdition = _pricePerEdition;
        lotPrices_[_lotID].startTime = _startTimeStamp;
        lotPrices_[_lotID].endTime = _endTimeStamp;
        lotPrices_[_lotID].tokenID = _tokenID;
        lotPrices_[_lotID].useMaxStock = true;
        lotPrices_[_lotID].maxStock = _maxSupply;
        // Verifying senders rights to start auction, pulling token from the
        // hub, emitting relevant info
        _createAuctionLot(_lotID, _tokenID);
        _addBuyersForLot(_lotID, _validBuyers);
        // Checks if the start time has passed
        if (getCurrentTime() >= _startTimeStamp) {
            lotPrices_[_lotID].biddable = true;
            auctionHubInstance_.lotAuctionStarted(auctionID_, _lotID);
        }

        emit LotCreated(
            _pricePerEdition,
            _startTimeStamp,
            _endTimeStamp,
            _lotID,
            _tokenID,
            auctionID_,
            _validBuyers
        );
    }

    /**
     * @param   _lotID The ID of the lot
     * @notice  This function will revert if the bid amount is not higher than
     *          the current highest bid and the min bid price for the lot.
     */
    function bid(uint256 _lotID, uint256 _editionAmount)
        external
        payable
        onlyListedBuyer(_lotID)
    {
        _bid(_lotID, _editionAmount);
    }
}
