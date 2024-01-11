//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title IEscrow
 * @author Protofire
 * @dev Ilamini Dagogo for Protofire.
 *
 */
interface IdOTC {
    /**
        @dev Offer Stucture 
    */

    struct Offer {
        bool isNft;
        address maker;
        uint256 offerId;
        uint256[] nftIds; // list nft ids
        bool fullyTaken;
        uint256 amountIn; // offer amount
        uint256 offerFee;
        uint256 unitPrice;
        uint256 amountOut; // the amount to be receive by the maker
        address nftAddress;
        uint256 expiryTime;
        uint256 offerPrice;
        OfferType offerType; // can be PARTIAL or FULL
        uint256[] nftAmounts;
        address escrowAddress;
        address specialAddress; // makes the offer avaiable for one account.
        address tokenInAddress; // Token to exchange for another
        uint256 availableAmount; // available amount
        address tokenOutAddress; // Token to receive by the maker
    }

    struct Order {
        uint256 offerId;
        uint256 amountToSend; // the amount the taker sends to the maker
        address takerAddress;
        uint256 amountToReceive;
        uint256 minExpectedAmount; // the amount the taker is to recieve
    }

    enum OfferType { PARTIAL, FULL }

    function getOfferOwner(uint256 offerId) external view returns (address owner);

    function getOffer(uint256 offerId) external view returns (Offer memory offer);

    function getTaker(uint256 orderId) external view returns (address taker);

    function getTakerOrders(uint256 orderId) external view returns (Order memory order);
}
