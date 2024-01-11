//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title IEscrow
 * @author Protofire
 * @dev Ilamini Dagogo for Protofire.
 *
 */
interface INFTdOTC {
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

    struct NftOrder {
        uint256 offerId;
        uint256[] nftIds;
        uint256 amountPaid;
        uint256[] nftAmounts;
        address takerAddress;
    }

    enum OfferType { PARTIAL, FULL }

    function getNftOfferOwner(uint256 _nftOfferId) external view returns (address owner);

    function getNftOffer(uint256 _nftOfferId) external view returns (Offer memory offer);

    function getNftTaker(uint256 _nftOrderId) external view returns (address taker);

    function getNftOrders(uint256 _nftOrderId) external view returns (NftOrder memory order);
}
