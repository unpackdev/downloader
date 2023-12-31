// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "./MintGoldDustMarketplace.sol";
import "./IERC1155Receiver.sol";
import "./IERC165.sol";

/// @title A contract responsible by the Marketplace Auction functionalities
/// @notice Contains functions for list, place a bid in an existent auction
/// check if an auction time is ended and end an auction.
/// @author Mint Gold Dust LLC
/// @custom:contact klvh@mintgolddust.io
contract MintGoldDustMarketplaceAuction is MintGoldDustMarketplace {
    using Counters for Counters.Counter;

    /**
     * @notice that is a Data Transfer Object to be transferred betwwen the functions in the auction flow.
     *              It consists of the following fields:
     *                    - tokenId: The tokenId of the marketItem.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     */
    struct BidDTO {
        uint256 tokenId;
        address contractAddress;
        address seller;
    }

    Counters.Counter public auctionIds;
    mapping(address => mapping(address => mapping(uint256 => mapping(address => bool))))
        private checkBidder;

    /**
     * @notice that this event show the info about the creation of a new auction.
     * @dev this event will be triggered when a MintGoldDustNFT is listed for the  marketplace auction.
     * @param tokenId the sequence number for the item.
     * @param contractAddress the MintGoldDustERC721 address or the MintGoldDustERC1155 address.
     * @param seller the seller of this tokenId.
     * @param price the reserve price for this auction.
     *    @dev it can be zero (so the auction does not has a reserve price).
     * @param timeOfCreation the timestamp that the auction was created.
     * @param auctionId the sequence number for the auction.
     */
    event ItemListedToAuction(
        uint256 indexed tokenId,
        address contractAddress,
        address seller,
        uint256 price,
        uint256 timeOfCreation,
        uint256 indexed auctionId
    );

    /**
     * @notice that this event show the info about new bids in an auction.
     * @dev this event will be triggered if a new bid was placed.
     * @param tokenId the sequence number for the item.
     * @param contractAddress the MintGoldDustERC721 address or the MintGoldDustERC1155 address.
     * @param startTime the timestamp that the time was initialized for this auction.
     * @param endTime the startTime plus 24 hours.
     * @param auctionId the sequence number for the auction.
     */
    event AuctionTimeStarted(
        uint256 indexed tokenId,
        address contractAddress,
        uint256 startTime,
        uint256 endTime,
        uint256 indexed auctionId
    );

    /**
     * @notice that this event show the info about new bids in an auction.
     * @dev this event will be triggered if a new bid was placed.
     * @param tokenId the sequence number for the item.
     * @param contractAddress the MintGoldDustERC721 address or the MintGoldDustERC1155 address.
     * @param previousBidder the address that did the latest highest bid.
     * @param currentBidder the address is doing the new highest bid.
     * @param bid the amount that is being payed in the new bid.
     * @param bidTime the timestamp of the bid.
     * @param auctionId the sequence number for the auction.
     */
    event AuctionNewBid(
        uint256 indexed tokenId,
        address contractAddress,
        address previousBidder,
        address currentBidder,
        uint256 bid,
        uint256 bidTime,
        uint256 indexed auctionId
    );

    /**
     * @notice that this event is triggered when an auction has the time extended.
     * @dev if an auction receives a new highest bid, in the last five minutes of the auction time,
     *      then more five minutes are added to the auction endTime. So at this moment this event is triggered.
     * @param tokenId the sequence number for the item.
     * @param contractAddress the MintGoldDustERC721 address or the MintGoldDustERC1155 address.
     * @param newEndTime the auction endTime plus five minutes.
     * @param auctionId the sequence number for the auction.
     */
    event AuctionExtended(
        uint256 tokenId,
        address contractAddress,
        uint256 newEndTime,
        uint256 auctionId
    );

    /// @notice that this event is triggered when an auction is cancelled.
    /// @param tokenId the sequence number for the item.
    /// @param contractAddress the MintGoldDustERC721 address or the MintGoldDustERC1155 address.
    /// @param seller the seller of this tokenId.
    /// @param cancelTime the timestamp that the auction was cancelled.
    /// @param auctionId the sequence number for the auction.
    event AuctionCancelled(
        uint256 tokenId,
        address contractAddress,
        address seller,
        uint256 cancelTime,
        uint256 auctionId
    );

    /// @notice that this event is triggered when the winner call the endAuction function.s
    /// @param tokenId the sequence number for the item.
    /// @param contractAddress the MintGoldDustERC721 address or the MintGoldDustERC1155 address.
    /// @param seller the seller of this tokenId.
    /// @param endTime the timestamp that the highest bidder winner call the end auction to really get the token.
    /// @param auctionId the sequence number for the auction.
    event AuctionWinnerCall(
        uint256 tokenId,
        address contractAddress,
        address seller,
        uint256 endTime,
        uint256 auctionId
    );

    /// @notice that this event is triggered when some bidder place a bid greater than the last one.
    /// @param recipient the address that will receive the refund.
    /// @param amount the amount that will be refunded.
    event LastBidderRefunded(address indexed recipient, uint256 amount);

    error AuctionMustBeEnded(
        uint256 _tokenId,
        address contractAddress,
        uint256 _auctionId
    );
    error AuctionEndedAlready();
    error BidTooLow();
    error AuctionCannotBeEndedYet();
    error AuctionTimeNotStartedYet();
    error AuctionCreatorCannotBid();
    error LastBidderCannotPlaceNextBid();
    error AuctionAlreadyStarted();
    error ErrorToRefundLastBidder();
    error ListPriceMustBeGreaterOrEqualZero();

    /**
     *
     * @notice MGDAuction is a children of MintGoldDustMarketplace and this one is
     * composed by other two contracts.
     * @param _mintGoldDustCompany The contract responsible to MGD management features.
     * @param _mintGoldDustERC721Address The MGD ERC721.
     * @param _mintGoldDustERC1155Address The MGD ERC721.
     */
    function initializeChild(
        address _mintGoldDustCompany,
        address payable _mintGoldDustERC721Address,
        address payable _mintGoldDustERC1155Address
    ) external initializer {
        MintGoldDustMarketplace.initialize(
            _mintGoldDustCompany,
            _mintGoldDustERC721Address,
            _mintGoldDustERC1155Address
        );
    }

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }

    /**
     *
     * @notice a function that allow users make new bid in an existent auction.
     * @dev to this function works some
     *      verifications need be done:
     *         - The bidder cannot be the auction creator;
     *         - The next bidder cannot be the same of the last bid;
     *         - The item must be listed;
     *         - The time of the auction should not be ended yet;
     *         - The bid value must be greater than zero
     *             - in case that the auction does not has a reserve price;
     *             - greater than the reserve price if the auction has one and is the first bid;
     *             - or greater than the last highest bid.
     *         - After all verifications pass we verify if the time of the auction was already started. If not we start it.
     *         - Also is verified if the bid is being done in the last final minutes of the bid (initiale it is set
     *           by 5 minutes). If yes, we add more the same quantity to the final of the end time of the auction.
     *         - If everything goes alright we do the transfers.
     * @param _bidDTO struct that represents the data to be transfered between functions in the auction flow.
     *                It consists of the following fields:
     *                  - tokenId: the id of the token that is listed to this auction.
     *                  - contractAddress: is a MintGoldDustNFT address.
     *                  - seller: is the address of the seller of this tokenId.
     */
    function placeBid(BidDTO memory _bidDTO) external payable nonReentrant {
        /// @dev verifications
        isNotCreator(_bidDTO);
        isNotLastBidder(_bidDTO);
        isTokenIdListed(
            _bidDTO.tokenId,
            _bidDTO.contractAddress,
            _bidDTO.seller
        );
        isAuctionTimeEnded(_bidDTO);
        isBidTooLow(_bidDTO);

        if (
            checkBidder[msg.sender][_bidDTO.contractAddress][_bidDTO.tokenId][
                _bidDTO.seller
            ] == false
        ) {
            checkBidder[msg.sender][_bidDTO.contractAddress][_bidDTO.tokenId][
                _bidDTO.seller
            ] == true;

            /// @dev starts auction flow
            isAuctionTimeStarted(_bidDTO);
            checkIfIsLast5MinutesAndAddMore5(_bidDTO);
            refundLastBidder(_bidDTO);
            manageNewBid(_bidDTO);
            delete checkBidder[msg.sender][_bidDTO.contractAddress][
                _bidDTO.tokenId
            ][_bidDTO.seller];
        }
    }

    /**
     * @notice that this function is responsible to cancel an auction.
     * @dev some verifications are done before cancel the auction.
     *            - The item must be listed.
     *            - The seller must be the msg.sender.
     *            - The auction must not be started yet.
     *            - The time of the auction should be zero.
     * @param _tokenId is the token id of the listed item.
     * @param _contractAddress is a MintGoldDustERC721 or a MintGoldDustERC1155 contract address.
     * @notice if everything goes alright the token is retrieved by the seller and the function EMIT the AuctionCancelled event.
     *                In the final the item is deleted from the idMarketItemsByContractByOwner mapping.
     */
    function cancelAuction(
        uint256 _tokenId,
        address _contractAddress
    ) external nonReentrant {
        isTokenIdListed(_tokenId, _contractAddress, msg.sender);
        require(
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][
                msg.sender
            ].seller == msg.sender,
            "Unauthorized"
        );

        if (
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][
                msg.sender
            ].auctionProps.endTime > 0
        ) {
            revert AuctionAlreadyStarted();
        }

        MintGoldDustNFT _mintGoldDustNFT = getERC1155OrERC721(
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][
                msg.sender
            ].isERC721
        );

        _mintGoldDustNFT.transfer(
            address(this),
            msg.sender,
            _tokenId,
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][
                msg.sender
            ].tokenAmount
        );

        emit AuctionCancelled(
            _tokenId,
            _contractAddress,
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][
                msg.sender
            ].seller,
            block.timestamp,
            idMarketItemsByContractByOwner[_contractAddress][_tokenId][
                msg.sender
            ].auctionProps.auctionId
        );

        delete idMarketItemsByContractByOwner[_contractAddress][_tokenId][
            msg.sender
        ];
    }

    /**
     * @notice that this function is responsible to finalize the flow of the auciton
     * that must be a purchaseNFT sale.
     * @dev this function must be called from the frontend only when the time of the auction is ended.
     *      Who can call this function?
     *        - The highest bidder;
     *        - The seller;
     *        - The MintGoldDustCompany owner.
     * @dev some verifications are done before finalize the auction.
     *            - The item must be listed.
     *            - The highest bidder must be the msg.sender.
     *            - And the time of the auction must already be reached out the final.
     *            - The auction must not be ended yet.
     *            - The time of the auction should not be zero.
     * @param _bidDTO struct that represents the data to be transfered between functions in the auction flow.
     *                It consists of the following fields:
     *                  - tokenId: the id of the token that is listed to this auction.
     *                  - contractAddress: is a MintGoldDustNFT address.
     *                  - seller: is the address of the seller of this tokenId.
     */
    function endAuction(BidDTO memory _bidDTO) external nonReentrant {
        isTokenIdListed(
            _bidDTO.tokenId,
            _bidDTO.contractAddress,
            _bidDTO.seller
        );
        MarketItem storage item = idMarketItemsByContractByOwner[
            _bidDTO.contractAddress
        ][_bidDTO.tokenId][_bidDTO.seller];
        require(
            item.auctionProps.highestBidder == msg.sender ||
                item.seller == msg.sender ||
                mintGoldDustCompany.owner() == msg.sender,
            "Unauthorized"
        );

        if (block.timestamp < item.auctionProps.endTime) {
            revert AuctionCannotBeEndedYet();
        }

        if (item.auctionProps.ended) {
            revert AuctionEndedAlready();
        }

        if (item.auctionProps.endTime == 0) {
            revert AuctionTimeNotStartedYet();
        }

        item.auctionProps.ended = true;
        uint256 auctionId = item.auctionProps.auctionId;

        purchaseAuctionNft(
            SaleDTO(
                _bidDTO.tokenId,
                item.tokenAmount,
                _bidDTO.contractAddress,
                _bidDTO.seller
            ),
            item.auctionProps.highestBid
        );

        emit AuctionWinnerCall(
            _bidDTO.tokenId,
            _bidDTO.contractAddress,
            _bidDTO.seller,
            block.timestamp,
            auctionId
        );
    }

    /**
     * @notice that is function to list a MintGoldDustNFT for the marketplace auction.
     * @dev This is an implementation of a virtual function declared in the father contract.
     *      Here we call the more generic list function passing the correct params for an auction flow
     *      and after that emit the ItemListedToAuction event.
     * @param _tokenId: The tokenId of the marketItem.
     * @param _amount: The quantity of tokens to be listed for an MintGoldDustERC1155.
     *    @dev For MintGoldDustERC721 the amout must be always one.
     * @param _contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     * @param _priceForAllTokens: The price or reserve price for the quantity of tokens listed.
     *    @dev in the auction the seller must set a price for all tokens that are being listed.
     */
    function list(
        uint256 _tokenId,
        uint256 _amount,
        address _contractAddress,
        uint256 _priceForAllTokens
    ) external override whenNotPaused {
        mustBeMintGoldDustERC721Or1155(_contractAddress);
        checkAmount(_amount);
        isNotListed(_tokenId, _contractAddress, msg.sender);

        ListDTO memory _listDTO = ListDTO(
            _tokenId,
            _amount,
            _contractAddress,
            _priceForAllTokens
        );

        auctionIds.increment();

        list(_listDTO, auctionIds.current(), msg.sender);

        emit ItemListedToAuction(
            _listDTO.tokenId,
            _contractAddress,
            msg.sender,
            _listDTO.price,
            block.timestamp,
            auctionIds.current()
        );
    }

    /**
     * Acquire a listed item for the MintGoldDustMarketplaceAuction.
     * @notice function will fail if the token was not listed to the auction market.
     * @notice function will fail if the contract address is not a MintGoldDustERC721 neither a MintGoldDustERC1155.
     * @notice function will fail if the amount paid by the buyer does not cover the purshace amount required.
     * @dev This function is specific for the auction market. Then, in this case, the function will be called
     *      internally from the MGDAuction contract. So is not possible to get the msg.value. Then we're receiving the value by param.
     * @param _saleDTO The SaleDTO struct parameter to use.
     *                 It consists of the following fields:
     *                    - tokenid: The tokenId of the marketItem.
     *                    - amount: The quantity of tokens to be listed for an MintGoldDustERC1155. For
     *                              MintGoldDustERC721 the amout must be always one.
     *                    - contractAddress: The MintGoldDustERC1155 or the MintGoldDustERC721 address.
     *                    - seller: The seller of the marketItem.
     * @param _value The value to be paid for the purchase.
     *    @dev we need to receive the sender this way, because in the auction flow the purchase starts from
     *         the endAuction function in the MintGoldDustMarketplaceAuction contract. So from there the address
     *         that we get is the highst bidder that is stored in the marketItem struct. So we need to manage this way.
     */
    function purchaseAuctionNft(
        SaleDTO memory _saleDTO,
        uint256 _value
    ) internal {
        isTokenIdListed(
            _saleDTO.tokenId,
            _saleDTO.contractAddress,
            _saleDTO.seller
        );

        mustBeMintGoldDustERC721Or1155(_saleDTO.contractAddress);

        hasEnoughAmountListed(
            _saleDTO.tokenId,
            _saleDTO.contractAddress,
            address(this),
            _saleDTO.amount,
            _saleDTO.seller
        );

        MarketItem memory _marketItem = getMarketItem(_saleDTO);

        /// @dev if the flow goes for ERC721 the amount of tokens MUST be ONE.
        uint256 _realAmount = 1;

        if (!_marketItem.isERC721) {
            _realAmount = _saleDTO.amount;
            isBuyingAllListedTokens(_saleDTO);
        }

        //require(_marketItem.price == _value, "Invalid amount for this purchase");

        checkIfIsPrimaryOrSecondarySaleAndCall(
            _marketItem,
            _saleDTO,
            _value,
            _marketItem.auctionProps.highestBidder,
            _realAmount
        );
    }

    /**
     * @dev the main goal of this function is check if the endTime of the auction is different of zero, so
     *      the time auction was already started. And, in this case, if the endTime is greater than the current timestamp.
     * @notice that if not it REVERTS with a AuctionMustBeEnded error.
     * @param _bidDTO BidDTO struct.
     */
    function isAuctionTimeEnded(BidDTO memory _bidDTO) private view {
        MarketItem storage item = idMarketItemsByContractByOwner[
            _bidDTO.contractAddress
        ][_bidDTO.tokenId][_bidDTO.seller];
        if (
            item.auctionProps.endTime != 0 &&
            block.timestamp >= item.auctionProps.endTime
        ) {
            revert AuctionMustBeEnded(
                _bidDTO.tokenId,
                _bidDTO.contractAddress,
                item.auctionProps.auctionId
            );
        }
    }

    /**
     * @dev the goal of this function is check the amount paid by the buyer is valid.
     * @notice that first if the reserve price is zero so the amount paid must be greater than it.
     * @notice that in the second case if we have a reserve price and the highest bid is zero. It means
     *         that the first bid needs to be greater than the reserve price.
     * @notice that in the last case the item alredy has received some bid. So the amount paid
     *         must be greater than the last highest bid.
     * @notice if one of the conditions was not met the function REVERTS with a BidTooLow() error.
     * @param _bidDTO BidDTO struct.
     */
    function isBidTooLow(BidDTO memory _bidDTO) private {
        MarketItem storage item = idMarketItemsByContractByOwner[
            _bidDTO.contractAddress
        ][_bidDTO.tokenId][_bidDTO.seller];

        if (item.price == 0 && msg.value <= 0) {
            revert BidTooLow();
        }

        /// @dev in this case the item did not received any bids yet and the bid is less than the reserve price
        if (item.auctionProps.highestBid == 0 && msg.value < item.price) {
            revert BidTooLow();
        }

        /// @dev in this case the item have already received bids and the bid is less or equal the latest highest bid + 3%
        if (
            item.auctionProps.highestBid != 0 &&
            msg.value < (item.auctionProps.highestBid * 103) / 100
        ) {
            revert BidTooLow();
        }

        ManageSecondarySale memory manageSecondarySale = isSecondarySale[
            _bidDTO.contractAddress
        ][_bidDTO.tokenId];

        if (
            (manageSecondarySale.owner == _bidDTO.seller &&
                !manageSecondarySale.sold) &&
            item.auctionProps.highestBid == 0 &&
            item.price > 0 &&
            msg.value < (item.price * 103) / 100
        ) {
            revert BidTooLow();
        }
    }

    /**
     * @dev the goal of this function start the time for the auction if it was not started yet.
     * @notice that it EMITS the AuctionTimeStarted event when the time is started.
     * @notice that the end time is the start time plus the mintGoldDustCompany.auctionDuration(). This
     *         value is 24 hours and is defined at the moment of the deployment of the contracts.
     * @param _bidDTO BidDTO struct.
     */
    function isAuctionTimeStarted(BidDTO memory _bidDTO) private {
        MarketItem storage item = idMarketItemsByContractByOwner[
            _bidDTO.contractAddress
        ][_bidDTO.tokenId][_bidDTO.seller];

        if (item.auctionProps.endTime == 0) {
            /// @dev The time starts to count for the auction.
            item.auctionProps.startTime = block.timestamp;
            item.auctionProps.endTime =
                item.auctionProps.startTime +
                mintGoldDustCompany.auctionDuration();

            emit AuctionTimeStarted(
                _bidDTO.tokenId,
                _bidDTO.contractAddress,
                item.auctionProps.startTime,
                item.auctionProps.endTime,
                item.auctionProps.auctionId
            );
        }
    }

    /**
     * @dev the goal of this function is check if the endTime is in the final minutes configured initially
     *      by five minutes in the MintGoldDustCompany contract. If yes it adds more five minutes to the
     *      auction end time and EMITS the AuctionExtended event.
     * @param _bidDTO BidDTO struct.
     */
    function checkIfIsLast5MinutesAndAddMore5(BidDTO memory _bidDTO) private {
        MarketItem storage item = idMarketItemsByContractByOwner[
            _bidDTO.contractAddress
        ][_bidDTO.tokenId][_bidDTO.seller];
        /**
         * @dev If a higher bid happens in the last 5 minutes we should add more 5 minutes
         * to the end time auction.
         */
        if (
            item.auctionProps.endTime - block.timestamp <
            mintGoldDustCompany.auctionFinalMinutes()
        ) {
            item.auctionProps.endTime =
                item.auctionProps.endTime +
                mintGoldDustCompany.auctionFinalMinutes();
            emit AuctionExtended(
                _bidDTO.tokenId,
                _bidDTO.contractAddress,
                item.auctionProps.endTime,
                item.auctionProps.auctionId
            );
        }
    }

    /**
     * @dev if the auction receives a new highest bid so the latest amount paid by the last address
     *      must be refunded for it. So this function add the amount to the recipientBalances mapping.
     * @param _bidDTO BidDTO struct.
     * @notice that the mapping is incremented only if is not the first bid in the auction.
     * @notice that the function EMIT the LastBidderRefunded event.
     */
    function refundLastBidder(BidDTO memory _bidDTO) private {
        MarketItem storage item = idMarketItemsByContractByOwner[
            _bidDTO.contractAddress
        ][_bidDTO.tokenId][_bidDTO.seller];

        if (item.auctionProps.highestBidder != address(0)) {
            address lastBidder = item.auctionProps.highestBidder;
            uint256 amount = item.auctionProps.highestBid;
            item.auctionProps.highestBid = 0;

            (bool success, ) = address(lastBidder).call{value: amount}("");

            if (!success) {
                revert ErrorToRefundLastBidder();
            }

            emit LastBidderRefunded(item.auctionProps.highestBidder, amount);
        }
    }

    /**
     * @dev this is the last step in the place a bid flow. Here all the correct values will be
     *      updated to the idMarketItemsByContractByOwner mapping.
     * @notice that the AuctionNewBid event is emmited.
     * @param _bidDTO BidDTO struct.
     */
    function manageNewBid(BidDTO memory _bidDTO) private {
        MarketItem storage item = idMarketItemsByContractByOwner[
            _bidDTO.contractAddress
        ][_bidDTO.tokenId][_bidDTO.seller];

        /// @dev save the previous bidder to show in the event.
        address previousBidder = item.auctionProps.highestBidder;

        uint256 realPrice = msg.value;

        ManageSecondarySale memory manageSecondarySale = isSecondarySale[
            _bidDTO.contractAddress
        ][_bidDTO.tokenId];

        /// @dev If is primary sale so the bidder needs to pay the item price + 3% of the item price
        if (
            (manageSecondarySale.owner == _bidDTO.seller &&
                !manageSecondarySale.sold)
        ) {
            realPrice = (msg.value * 100 * 1e18) / (103) / 1e18;
        }

        /// @dev here we change the states.
        item.price = realPrice;
        item.auctionProps.highestBid = msg.value;
        item.auctionProps.highestBidder = msg.sender;

        emit AuctionNewBid(
            _bidDTO.tokenId,
            _bidDTO.contractAddress,
            previousBidder,
            msg.sender,
            realPrice,
            block.timestamp,
            item.auctionProps.auctionId
        );
    }

    /**
     * @dev this function verify if the address is not the seller.
     * @notice if yes it REVERTS with a AuctionCreatorCannotBid() error.
     * @param _bidDTO BidDTO struct.
     */
    function isNotCreator(BidDTO memory _bidDTO) private view {
        if (
            idMarketItemsByContractByOwner[_bidDTO.contractAddress][
                _bidDTO.tokenId
            ][_bidDTO.seller].seller == msg.sender
        ) {
            revert AuctionCreatorCannotBid();
        }
    }

    /**
     * @dev this function verify if the address is not the auction current highest bidder.
     * @notice if yes it REVERTS with a LastBidderCannotPlaceNextBid() error.
     * @param _bidDTO BidDTO struct.
     */
    function isNotLastBidder(BidDTO memory _bidDTO) private view {
        if (
            idMarketItemsByContractByOwner[_bidDTO.contractAddress][
                _bidDTO.tokenId
            ][_bidDTO.seller].auctionProps.highestBidder == msg.sender
        ) {
            revert LastBidderCannotPlaceNextBid();
        }
    }
}
