// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./SeaDropStructs.sol";

import "./SeaDropErrorsAndEvents.sol";

interface IWavemintV1DataAndEvents is SeaDropErrorsAndEvents {
    /**
     * @dev Order info data structure
     * @param baseToken The baseToken type placed in the order
     * @param tokenId The token type placed in the order
     * @param startTime The startTime of the auction
     * @param orderType The type of the order, 1 is sale order, 2 is auction order, 3 is splittable order
     * @param amount The amount of token placed in the order
     * @param quoteToken The address of the token accepted as payment for the order
     * @param price The price asked for the order (minimum bidding price for auction order)
     * @param sellerAddr The address of the seller that created the order
     * @param endTime The end time of the auction (only meaningful for auction order)
     * @param reservePrice The reservePrice for the auction
     * @param buyoutPrice The buyoutPrice for ending the auction
     */
    struct OrderForSaleInfo {
        address baseToken;
        uint256 tokenId;
        uint256 startTime;
        uint8 orderType;
        uint256 amount;
        address quoteToken;        
        uint256 price;
        address payable sellerAddr;
        uint256 endTime;
        uint256 reservePrice;
        uint256 buyoutPrice;
    }

    /**
     * @dev Order info data structure
     * @param baseToken The baseToken type placed in the order
     * @param tokenId The token type placed in the order
     * @param endTime The endTime of the offer
     * @param startTime The startTime of the offer
     * @param quoteToken The address of the token accepted as payment for the order
     * @param price The price that offering the token
     * @param nftOwner The address of the nft owner
     * @param offerer The address of the offerer
     */
    struct OfferToBuyInfo {
        address baseToken;
        uint256 tokenId;
        uint256 endTime;
        uint256 startTime;
        address quoteToken;        
        uint256 price;
        address payable nftOwner;
        address offerer;
    }

    /**
     * @dev bider info data structure
     * @param offerer The address of the buyer
     * @param price The number of orders the buyer participated to buy or bid on
     */
    struct OffererInfo {
        address offerer;
        uint256 price;
    }

    /**
     * @dev Order info data structure
     * @param baseToken The baseToken type placed in the order
     * @param endTime The endTime of the offer
     * @param startTime The startTime of the offer
     * @param quoteToken The address of the token accepted as payment for the order
     * @param price The price that offering the token
     * @param offerer The address of the offerer
     */
    struct CollectionOfferToBuyInfo {
        address baseToken;
        uint256 endTime;
        uint256 startTime;
        address quoteToken;        
        uint256 price;
        address offerer;
    }

    /**
     * @dev bider info data structure
     * @param offerer The address of the buyer
     * @param price The number of orders the buyer participated to buy or bid on
     */
    struct CollectionOffererInfo {
        address offerer;
        uint256 price;
    }

    /**
     * @dev Orders can be validated (either explicitly via `validate`, or as a
     *      consequence of a full or partial fill), specifically cancelled (they can
     *      also be cancelled in bulk via incrementing a per-zone counter), and
     *      partially or fully filled (with the fraction filled represented by a
     *      numerator and denominator).
     */
    struct OrderStatus {
        bool available;
        bool isfilled;
        bool isCancelled;
    }
        /**
     * @dev bider info data structure
     * @param lastBidder The address of the buyer
     * @param lastBid The number of orders the buyer participated to buy or bid on
     */
    struct BiderInfo {
        address lastBidder;
        uint256 lastBid;
    }
    
    /**
     * @dev MUST emit when the contract receives a single ERC1155 token type.
     */
    event ERC1155Received(
        address indexed _operator,
        address indexed _from,
        uint256 indexed _id,
        uint256 _value,
        bytes _data
    );

    /**
     * @dev MUST emit when the contract receives multiple ERC1155 token types.
     */
    event ERC1155BatchReceived(
        address indexed _operator,
        address indexed _from,
        uint256[] _ids,
        uint256[] _values,
        bytes _data
    );

    /**
     * @dev MUST emit when the contract receives multiple ERC1155 token types.
     */
    event ERC721Received(
        address indexed _operator,
        address indexed _from,
        address indexed _tokenAddress,
        uint256 _tokenId,
        bytes _data
    );

    /**
     * @dev MUST emit when a new sale order is created in Wavemint.
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_orderId` argument MUST be the id of the order created.
     * The `_tokenId` argument MUST be the token type placed on sale.
     * The `_amount` argument MUST be the amount of token placed on sale.
     * The `_quoteToken` argument MUST be the address of the token accepted as payment for the order.
     * The `_price` argument MUST be the fixed price asked for the sale order.
     */
    event OrderForSale(
        address _seller,
        bytes32 indexed _orderHash,
        address _baseToken,
        uint256 indexed _tokenId,
        uint256 _amount,
        address indexed _quoteToken,
        uint256 _price,
        uint256 _startTime
    );

    /**
     * @dev MUST emit when a new sale order is created in Wavemint.
     * The `_nftOwner` argument MUST be the address of the seller who created the order.
     * The `_offerrHash` argument MUST be the id of the order created.
     * The `_baseToken` argument MUST be the token type placed on sale.
     * The `_tokenId` argument MUST be the amount of token placed on sale.
     * The `_quoteToken` argument MUST be the address of the token accepted as payment for the order.
     * The `_price` argument MUST be the fixed price asked for the sale order.
     * The `_endTime` argument MUST be the fixed price asked for the sale order.
     * The `_offerer` argument MUST be the fixed price asked for the sale order.
     */
    event OfferToBuy(
        address _nftOwner,
        bytes32 indexed _offerrHash,
        address _baseToken,
        uint256 indexed _tokenId,
        address indexed _quoteToken,
        uint256 _price,
        uint256 _endTime,
        address _offerer,
        uint256 _startTime
    );

    /**
     * @dev MUST emit when a new sale order is created in Wavemint.
     * The `_offerrHash` argument MUST be the id of the order created.
     * The `_baseToken` argument MUST be the token type placed on sale.
     * The `_quoteToken` argument MUST be the address of the token accepted as payment for the order.
     * The `_price` argument MUST be the fixed price asked for the sale order.
     * The `_endTime` argument MUST be the fixed price asked for the sale order.
     * The `_offerer` argument MUST be the fixed price asked for the sale order.
     */
    event CollectionOfferToBuy(
        bytes32 indexed _offerrHash,
        address _baseToken,
        address indexed _quoteToken,
        uint256 _price,
        uint256 _endTime,
        address _offerer,
        uint256 _startTime
    );

    /**
     * @dev MUST emit when a new auction order is created in Wavemint.
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_orderId` argument MUST be the id of the order created.
     * The `_tokenId` argument MUST be the token type placed on auction.
     * The `_amount` argument MUST be the amount of token placed on auction.
     * The `_quoteToken` argument MUST be the address of the token accepted as payment for the auction.
     * The `_minPrice` argument MUST be the minimum starting price for the auction bids.
     * The `endTime` argument MUST be the time for ending the auction.
     */
    event OrderForAuction(
        address _seller,
        bytes32 indexed _orderHash,
        address indexed _baseToken,
        uint256 _tokenId,
        uint256 _amount,
        address indexed _quoteToken,
        uint256 _minPrice,
        uint256 _reservePrice,
        uint256 _buyoutPrice,
        uint256 _startTime,
        uint256 _endTime
    );

    /**
     * @dev MUST emit when a bid is placed on an auction order.
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_buyer` argument MUST be the address of the buyer who made the bid.
     * The `_orderHash` argument MUST be the id of the order been bid on.
     * The `_price` argument MUST be the price of the bid.
     */
    event OrderBid(
        address indexed _seller,
        address indexed _buyer,
        bytes32 indexed _orderHash,
        uint256 _price
    );

    /**
     * @dev MUST emit when an order is filled.
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_buyer` argument MUST be the address of the buyer in the fulfilled order.
     * The `_orderId` argument MUST be the id of the order fulfilled.
     * The `_royaltyOwner` argument MUST be the address of the royalty owner of the token sold in the order.
     * The `_quoteToken` argument MUST be the address of the token used as payment for the fulfilled order.
     * The `_price` argument MUST be the price of the fulfilled order.
     * The `_royaltyFee` argument MUST be the royalty paid for the fulfilled order.
     * The `_platformFee` argument MUST be the royalty paid for the fulfilled order.
     */
    event OrderFilled(
        address _seller,
        address indexed _buyer,
        bytes32 indexed _orderHash,
        address _baseToken,
        address indexed _quoteToken,
        uint256 _price,
        address _royaltyOwner,
        uint256 _royaltyFee,
        uint256 _platformFee
    );

    event OfferFilled(
        address _nftOwner,
        address indexed _offerer,
        bytes32 indexed _offerHash,
        address _baseToken,
        address indexed _quoteToken,
        uint256 _price,
        address _royaltyOwner,
        uint256 _royaltyFee,
        uint256 _platformFee
    );

    event CollectionOfferFilled(
        address _nftOwner,
        address indexed _offerer,
        bytes32 indexed _offerHash,
        address _baseToken,
        address indexed _quoteToken,
        uint256 _price,
        address _royaltyOwner,
        uint256 _royaltyFee,
        uint256 _platformFee
    );

    /**
     * @dev MUST emit when an order is canceled.
     * @dev Only an open sale order or an auction order with no bid yet can be canceled
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_orderHash` argument MUST be the id of the order canceled.
     */
    event OrderCanceled(address indexed _seller, bytes32 indexed _orderHash);

    /**
     * @dev MUST emit when an order is canceled.
     * @dev Only an open sale order or an auction order with no bid yet can be canceled
     * The `_offerer` argument MUST be the address of the seller who created the order.
     * The `_isOwner` argument MUST be true if the order is owned by the NFT owner.
     * The `_orderHash` argument MUST be the id of the order canceled.
     */
    event OfferCanceled(address indexed _offerer, bool indexed _isNFTOwner, bytes32 indexed _offerrHash);

    /**
     * @dev MUST emit when an order is canceled.
     * @dev Only an open sale order or an auction order with no bid yet can be canceled
     * The `_offerer` argument MUST be the address of the seller who created the order.
     * The `_orderHash` argument MUST be the id of the order canceled.
     */
    event CollectionOfferCanceled(address indexed _offerer, bytes32 indexed _offerrHash);

    /**
     * @dev MUST emit when an order has its price changed.
     * @dev Only an open sale order or an auction order with no bid yet can have its price changed.
     * @dev For sale orders, the fixed price asked for the order is changed.
     * @dev for auction orders, the minimum starting price for the bids is changed.
     * The `_seller` argument MUST be the address of the seller who created the order.
     * The `_orderId` argument MUST be the id of the order with the price change.
     * The `_oldPrice` argument MUST be the original price of the order before the price change.
     * The `_newPrice` argument MUST be the new price of the order after the price change.
     */
    event OrderPriceChanged(
        address indexed _seller,
        bytes32 indexed _oldOrderHash,
        bytes32 indexed _newOrderHash,
        uint256 _newPrice,
        address _newQuoteToken,
        uint256 _newReservePrice,
        uint256 _newBuyoutPrice
    );

    /**
     * @dev MUST emit when an order has its price changed.
     * @dev Only an open sale order or an auction order with no bid yet can have its price changed.
     * @dev For sale orders, the fixed price asked for the order is changed.
     * @dev for auction orders, the minimum starting price for the bids is changed.
     * The `_offerer` argument MUST be the address of the seller who created the order.
     * The `_orderId` argument MUST be the id of the order with the price change.
     * The `_oldPrice` argument MUST be the original price of the order before the price change.
     * The `_newPrice` argument MUST be the new price of the order after the price change.
     * The _newDuration argument MUST be the duration of the order.
     */
    event OfferChanged(
        address indexed _offerer,
        bytes32 indexed _oldOfferHash,
        bytes32 indexed _newOfferHash,
        uint256 _newPrice,
        address _newQuoteToken,
        uint256 _newTimeEnd
    );

    /**
     * @dev MUST emit when an order has its price changed.
     * @dev Only an open sale order or an auction order with no bid yet can have its price changed.
     * @dev For sale orders, the fixed price asked for the order is changed.
     * @dev for auction orders, the minimum starting price for the bids is changed.
     * The `_offerer` argument MUST be the address of the seller who created the order.
     * The `_orderId` argument MUST be the id of the order with the price change.
     * The `_oldPrice` argument MUST be the original price of the order before the price change.
     * The `_newPrice` argument MUST be the new price of the order after the price change.
     * The _newDuration argument MUST be the duration of the order.
     */
    event CollectionOfferChanged(
        address indexed _offerer,
        bytes32 indexed _oldCollectionOfferHash,
        bytes32 indexed _newCollectionOfferHash,
        uint256 _newPrice,
        address _newQuoteToken,
        uint256 _newTimeEnd
    );

    /**
     * @dev MUST emit with the platform fee information when an order is fulfilled
     */
    event OrderPlatformFee(
        address _platformAddress,
        address _quoteToken,
        uint256 _platformFee,
        address indexed _seller,
        address indexed _buyer,
        uint256 indexed _orderId
    );

    /**
     * @dev MUST emit with the platform fee information when an order is fulfilled
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Emit when the library logic contract is updated
     */
    event LibraryLogicContract(address indexed _codeAddress);

     /**
     * @dev Emit when the library logic contract is updated
     */
    event LibraryDropLogicContract(address indexed _codeAddressDrop);

    /**
     * @dev MUST emit with the platform fee information when an order is fulfilled
     */
    event TokenInfoUpdated(address indexed _token, address indexed _owner, string _uri, address _royaltyOwners, uint96 _royaltyRates);

    /**
     * @dev MUST emit when a splittable order is (partially) filled.
     * The `_token` argument MUST be the address of the seller who created the order.
     * The `_owner` argument MUST be the buyer in the (partially) fulfilled order.
     * The `_name` argument MUST be the id of the order (partially) fulfilled.
     * The `_uri` argument MUST be the address of the royalty owner of the token sold in the order.
     * The `_royaltyOwners` argument MUST be the address of the token used as payment for the (partially) fulfilled order.
     * The `_royaltyRates` argument MUST be the price paid for the (partially) fulfilled order.
     * The `createTime` argument MUST be the amount of tokens purchased in the (partially) fulfilled order
     * The `updateTime` argument MUST be the price for the tokens left in the splittable order after this (partial) purchase
     * The `_tokenType` argument MUST 721 or 1155
     * The `_chainType` argument MUST onchain or ofchain
     */ 
    struct TokenInfoRegister {
        address _owner;
        string _uri;
        address _royaltyOwners;
        uint96 _royaltyRates;
    }
}