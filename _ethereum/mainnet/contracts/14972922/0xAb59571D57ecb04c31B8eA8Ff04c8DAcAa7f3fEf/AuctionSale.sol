// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";

import "./Core.sol";

import "./Payment.sol";

error Auction_Sale_Contract_Address_Is_Not_Approved(address nftAddress);

error Auction_Sale_Amount_Cannot_Be_Zero();

error Auction_Sale_Price_Too_Low();

error Auction_Sale_Duration_Grater_Then_Max();

error Auction_Sale_Duration_Lower_Then_Min();

error Cannot_Update_Ongoing_Auction();

error Auction_Sale_Only_Seller_Can_Update();

error Cannot_Cancel_Ongoing_Auction();

error Auction_Sale_Only_Seller_Can_Cancel();

error Auction_Sale_Not_A_Valid_List();

error Auction_Sale_Already_Ended();

error Auction_Sale_Msg_Value_Lower_Then_Reserve_Price();

error Auction_Sale_Bid_Must_Be_Greater_Then(uint256 minimumBid);

error Auction_Sale_Seller_Cannot_Bid();

error Auction_Sale_Cannot_Settle_Onging_Auction();

abstract contract AuctionSale is
    Constants,
    Core,
    Payment,
    ReentrancyGuardUpgradeable
{
    struct AuctionSaleList {
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address bidder;
        uint256 bid;
        uint256 reservePrice;
        uint256 amount;
        address seller;
    }

    uint256 internal _auctionSaleId;

    mapping(address => mapping(uint256 => mapping(uint256 => AuctionSaleList)))
        private _assetAndSaleIdToAuctionSale;

    uint256[1000] private ______gap;

    event ListAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount,
        uint256 duration,
        uint256 reservePrice,
        uint256 extensionDuration,
        address seller,
        address[] royaltiesPayees,
        uint256[] royaltiesShares
    );

    event CancelAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount,
        address seller
    );
    event UpdateAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 duration,
        uint256 reservePrice,
        address[] royaltiesPayees,
        uint256[] royaltiesShares
    );
    event Bid(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        address lastBidder,
        uint256 lastBid,
        address newBidder,
        uint256 newBid,
        uint256 endtime
    );

    event Settle(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        address winner,
        uint256 winnerBid,
        uint256 dissrupCut,
        address seller,
        uint256 sellerCut,
        address[] royaltiesPayees,
        uint256[] royaltiesCuts,
        address settler
    );

    function listAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 duration,
        uint256 reservePrice,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    )
        external
        nonReentrant
        durationInLimits(duration)
        priceAboveMin(reservePrice)
    {
        if (_saleContractAllowlist[nftAddress] == false) {
            revert Auction_Sale_Contract_Address_Is_Not_Approved(nftAddress);
        }
        if (royaltiesPayees.length > 0) {
            _checkRoyalties(royaltiesPayees, royaltiesShares);
        }
        if (amount == 0) {
            revert Auction_Sale_Amount_Cannot_Be_Zero();
        }

        _trasferNFT(msg.sender, address(this), nftAddress, tokenId, amount);

        AuctionSaleList storage auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][++_auctionSaleId];

        _setRoyalties(
            SaleType.AuctionSale,
            _auctionSaleId,
            royaltiesPayees,
            royaltiesShares
        );

        auctionSale.amount = amount;
        auctionSale.bidder = address(0);
        auctionSale.bid = 0;
        auctionSale.endTime = 0;
        auctionSale.extensionDuration = EXTENSION_DURATION;
        auctionSale.duration = duration;
        auctionSale.reservePrice = reservePrice;
        auctionSale.seller = msg.sender;

        emit ListAuctionSale(
            nftAddress,
            tokenId,
            _auctionSaleId,
            auctionSale.amount,
            auctionSale.duration,
            auctionSale.reservePrice,
            auctionSale.extensionDuration,
            auctionSale.seller,
            royaltiesPayees,
            royaltiesShares
        );
    }

    function updateAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 duration,
        uint256 reservePrice,
        address[] calldata royaltiesPayees,
        uint256[] calldata royaltiesShares
    )
        external
        nonReentrant
        durationInLimits(duration)
        priceAboveMin(reservePrice)
    {
        AuctionSaleList storage auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];
        if (auctionSale.seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        if (auctionSale.seller != msg.sender) {
            revert Auction_Sale_Only_Seller_Can_Update();
        }

        if (auctionSale.endTime != 0) {
            revert Cannot_Update_Ongoing_Auction();
        }
        if (royaltiesPayees.length > 0) {
            _checkRoyalties(royaltiesPayees, royaltiesShares);

            _setRoyalties(
                SaleType.AuctionSale,
                saleId,
                royaltiesPayees,
                royaltiesShares
            );
        }

        auctionSale.reservePrice = reservePrice;

        auctionSale.duration = duration;

        emit UpdateAuctionSale(
            nftAddress,
            tokenId,
            saleId,
            auctionSale.duration,
            reservePrice,
            royaltiesPayees,
            royaltiesShares
        );
    }

    function cancelAuctionSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) external nonReentrant {
        AuctionSaleList memory auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];
        if (auctionSale.seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        if (auctionSale.seller != msg.sender) {
            revert Auction_Sale_Only_Seller_Can_Cancel();
        }
        if (auctionSale.endTime != 0) {
            revert Cannot_Cancel_Ongoing_Auction();
        }
        _trasferNFT(
            address(this),
            auctionSale.seller,
            nftAddress,
            tokenId,
            auctionSale.amount
        );

        _unlistAuction(nftAddress, tokenId, saleId);

        emit CancelAuctionSale(
            nftAddress,
            tokenId,
            saleId,
            auctionSale.amount,
            auctionSale.seller
        );
    }

    function bid(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) external payable nonReentrant {
        AuctionSaleList storage auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];
        address lastBidder = auctionSale.bidder;
        uint256 lastBid = auctionSale.bid;

        if (auctionSale.seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        if (msg.sender == auctionSale.seller) {
            revert Auction_Sale_Seller_Cannot_Bid();
        }
        if (auctionSale.bidder == address(0)) {
            //first bid!
            if (msg.value < auctionSale.reservePrice) {
                revert Auction_Sale_Msg_Value_Lower_Then_Reserve_Price();
            }

            auctionSale.bidder = msg.sender;
            auctionSale.bid = msg.value;

            auctionSale.endTime =
                uint256(block.timestamp) +
                auctionSale.duration;
        } else {
            if (auctionSale.endTime < block.timestamp) {
                revert Auction_Sale_Already_Ended();
            }

            // not the fisrt bid
            uint256 minimumRasieForBid = _getMinBidForReserveAuction(
                auctionSale.bid
            );

            if (minimumRasieForBid > msg.value) {
                revert Auction_Sale_Bid_Must_Be_Greater_Then(
                    minimumRasieForBid
                );
            }
            if (
                auctionSale.endTime - block.timestamp <
                auctionSale.extensionDuration
            ) {
                // if endtime < 15 min -> set ;
                auctionSale.endTime =
                    block.timestamp +
                    auctionSale.extensionDuration;
            }

            // return ether to last bidder
            payable(lastBidder).transfer(lastBid);

            //
            auctionSale.bidder = msg.sender;
            auctionSale.bid = msg.value;
        }

        emit Bid(
            nftAddress,
            tokenId,
            saleId,
            lastBidder,
            lastBid,
            auctionSale.bidder,
            auctionSale.bid,
            auctionSale.endTime
        );
    }

    function settle(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) external nonReentrant {
        AuctionSaleList memory auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];
        address seller = auctionSale.seller;
        if (seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        if (auctionSale.endTime > block.timestamp) {
            revert Auction_Sale_Cannot_Settle_Onging_Auction();
        }
        address winner = auctionSale.bidder;
        uint256 winnerBid = auctionSale.bid;

        _trasferNFT(
            address(this),
            winner,
            nftAddress,
            tokenId,
            auctionSale.amount
        );

        (
            uint256 dissrupCut,
            uint256 sellerCut,
            address[] memory royaltiesPayees,
            uint256[] memory royaltiesCuts
        ) = _splitPayment(seller, winnerBid, SaleType.AuctionSale, saleId);

        _unlistAuction(nftAddress, tokenId, saleId);

        emit Settle(
            nftAddress,
            tokenId,
            saleId,
            winner,
            winnerBid,
            dissrupCut,
            seller,
            sellerCut,
            royaltiesPayees,
            royaltiesCuts,
            msg.sender
        );
    }

    function isAuctionEnded(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) public view returns (bool) {
        AuctionSaleList memory auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];

        if (auctionSale.seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        return
            (auctionSale.endTime > 0) &&
            (auctionSale.endTime < block.timestamp);
    }

    function _unlistAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) private {
        delete _saleToRoyalties[SaleType.AuctionSale][saleId];
        delete _assetAndSaleIdToAuctionSale[nftAddress][tokenId][saleId];
    }

    function getEndTimeForReserveAuction(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) public view returns (uint256) {
        AuctionSaleList memory auctionSale = _assetAndSaleIdToAuctionSale[
            nftAddress
        ][tokenId][saleId];
        if (auctionSale.seller == address(0)) {
            revert Auction_Sale_Not_A_Valid_List();
        }
        return auctionSale.endTime;
    }

    function _getMinBidForReserveAuction(uint256 currentBid)
        private
        pure
        returns (uint256)
    {
        uint256 minimumIncrement = currentBid / 10;

        if (minimumIncrement < (0.1 ether)) {
            // The next bid must be at least 0.1 ether greater than the current.
            return currentBid + (0.1 ether);
        }
        return (currentBid + minimumIncrement);
    }

    modifier durationInLimits(uint256 duration) {
        if (duration > MAX_AUCTION_DURATION) {
            revert Auction_Sale_Duration_Grater_Then_Max();
        }
        if (duration < MIN_AUCTION_DURATION) {
            revert Auction_Sale_Duration_Lower_Then_Min();
        }
        _;
    }

    modifier priceAboveMin(uint256 price) {
        if (price < MIN_PRICE) {
            revert Auction_Sale_Price_Too_Low();
        }
        _;
    }
}
