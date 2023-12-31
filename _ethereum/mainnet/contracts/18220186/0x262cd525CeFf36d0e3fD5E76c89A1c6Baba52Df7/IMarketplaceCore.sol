// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: VERTICAL.art

import "./MarketplaceLib.sol";

/**
 * Core Marketplace interface
 */
interface IMarketplaceCore {
    event MarketplaceEnabled(address requestor, bool value);
    event MarketplaceFees(address requestor, uint16 feeBPS);
    event CurationFee(uint40 listingId, uint16 feeBPS);
    event MarketplaceSellerRegistry(address requestor, address registry);
    event MarketplaceWithdraw(
        address requestor,
        address erc20,
        uint256 amount,
        address receiver
    );
    event MarketplaceWithdrawEscrow(
        address requestor,
        address erc20,
        uint256 amount
    );
    event MarketplaceRoyaltyEngineUpdate(address royaltyEngineV1);

    /**
     * @dev Listing structure
     *
     * @param id              - id of listing
     * @param seller          - the selling party
     * @param finalized       - Whether or not this listing has completed accepting bids/purchases
     * @param totalSold       - total number of items sold.
     * @param marketplaceBPS  - Marketplace fee BPS
     * @param curationBPS     - Curation fee BPS
     * @param details         - ListingDetails.  Contains listing configuration
     * @param token           - TokenDetails.  Contains the details of token being sold
     * @param receivers       - Array of ListingReceiver structs.  If provided, will distribute sales proceeds to receivers accordingly.
     * @param fees            - DeliveryFees.  Contains the delivery fee configuration for the listing
     */
    struct Listing {
        uint256 id;
        address payable seller;
        bool finalized;
        uint24 totalSold;
        uint16 marketplaceBPS;
        uint16 curationBPS;
        MarketplaceLib.ListingDetails details;
        MarketplaceLib.TokenDetails token;
        MarketplaceLib.ListingReceiver[] receivers;
        MarketplaceLib.DeliveryFees fees;
        bool offersAccepted;
    }

    /**
     * @dev Offer structure
     *
     * @param offerer     - The address that made the offer
     * @param amount      - The offer amount
     * @param timestamp   - The time the offer was made
     * @param accepted    - Whether or not the offer was accepted
     */
    struct Offer {
        address offerer;
        uint256 amount;
        uint48 timestamp;
        bool accepted;
    }

    /**
     * @dev Set marketplace fee
     */
    function setFees(uint16 marketplaceFeeBPS) external;

    /**
     * @dev Set curation fee
     */
    function setCurationFee(uint40 listingId, uint16 curationFeeBPS) external;

    /**
     * @dev Set marketplace enabled
     */
    function setEnabled(bool enabled) external;

    /**
     * @dev See RoyaltyEngineV1 location. Can only be set once
     */
    function setRoyaltyEngineV1(address royaltyEngineV1) external;

    /**
     * @dev Withdraw from treasury
     */
    function withdraw(uint256 amount, address payable receiver) external;

    /**
     * @dev Withdraw from treasury
     */
    function withdraw(
        address erc20,
        uint256 amount,
        address payable receiver
    ) external;

    /**
     * @dev Withdraw from escrow
     */
    function withdrawEscrow(uint256 amount) external;

    /**
     * @dev Withdraw from escrow
     */
    function withdrawEscrow(address erc20, uint256 amount) external;

    /**
     * @dev Create listing
     */
    function createListing(
        MarketplaceLib.ListingDetails calldata listingDetails,
        MarketplaceLib.TokenDetails calldata tokenDetails,
        MarketplaceLib.DeliveryFees calldata deliveryFees,
        MarketplaceLib.ListingReceiver[] calldata listingReceivers,
        bool acceptOffers
    ) external returns (uint40);

    /**
     * @dev Modify listing
     */
    function modifyListing(
        uint40 listingId,
        uint256 initialAmount,
        uint48 startTime,
        uint48 endTime,
        uint16 extensionInterval
    ) external;

    /**
     * @dev Purchase a listed item
     */
    function purchase(
        uint40 listingId,
        bytes32[] calldata merkleProof
    ) external payable;

    /**
     * @dev Purchase a listed item
     */
    function purchase(
        uint40 listingId,
        uint24 count,
        bytes32[] calldata merkleProof
    ) external payable;

    /**
     * @dev Bid on a listed item
     */
    function bid(
        uint40 listingId,
        uint24 count,
        bool increase,
        bytes32[] calldata merkleProof
    ) external payable;

    /**
     * @dev Bid on a listed item
     */
    function bid(
        uint40 listingId,
        uint24 count,
        uint256 bidAmount,
        bool increase,
        bytes32[] calldata merkleProof
    ) external;

    /**
     * @dev Make offer on a listed item
     */
    function offer(
        uint40 listingId,
        bool increase,
        bytes32[] calldata merkleProof
    ) external payable;

    /**
     * @dev Make offer on a listed item
     */
    function offer(
        uint40 listingId,
        uint256 offerAmount,
        bool increase,
        bytes32[] calldata merkleProof
    ) external;

    /**
     * @dev Rescind an offer on a listed item
     */
    function rescind(uint40 listingId) external;

    function rescind(uint40[] calldata listingIds) external;

    function rescind(
        uint40 listingId,
        address[] calldata offerAddresses
    ) external;

    /**
     * @dev Accept offer(s) on a listed item
     */
    function accept(
        uint40 listingId,
        address[] calldata addresses,
        uint256[] calldata amounts,
        uint256 maxAmount
    ) external;

    /**
     * @dev Finalize a listed item (post-purchase)
     */
    function finalize(uint40 listingId) external payable;

    /**
     * @dev Cancel listing
     */
    function cancel(uint40 listingId, uint16 holdbackBPS) external;

    /**
     * @dev Get listing details
     */
    function getListing(
        uint40 listingId
    ) external view returns (Listing memory);

    /**
     * @dev Get the listing's current price
     */
    function getListingCurrentPrice(
        uint40 listingId
    ) external view returns (uint256);

    /**
     * @dev Get the listing's deliver fee
     */
    function getListingDeliverFee(
        uint40 listingId,
        uint256 price
    ) external view returns (uint256);

    /**
     * @dev Get the total listing price for multiple items
     */
    function getListingTotalPrice(
        uint40 listingId,
        uint24 count
    ) external view returns (uint256);

    /**
     * @dev Returns bids of a listing. No ordering guarantees
     */
    function getBids(
        uint40 listingId
    ) external view returns (MarketplaceLib.Bid[] memory);

    /**
     * @dev Returns offers of a listing. No ordering guarantees
     */
    function getOffers(uint40 listingId) external view returns (Offer[] memory);
}
