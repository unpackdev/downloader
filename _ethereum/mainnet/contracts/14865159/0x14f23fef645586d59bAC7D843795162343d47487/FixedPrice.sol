pragma solidity 0.8.12;

import "./ExchangeCore.sol";
import "./IERC721.sol";
import "./IWETH.sol";

abstract contract ERC721FixedPrice is ExchangeCore {
    struct FixedPriceListing {
        address seller;
        uint256 price;
    }

    struct Offer {
        uint256 value;
        uint256 expiresAt;
    }

    mapping(address => mapping(uint256 => FixedPriceListing))
        public fixedPriceListings;

    mapping(address => mapping(uint256 => mapping(address => Offer)))
        public offers;

    event ItemListed(
        address indexed account,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    event ItemUpdated(
        address indexed account,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    event ItemRemoved(
        address indexed account,
        address indexed collection,
        uint256 tokenId
    );

    event ItemPurchased(
        address indexed buyer,
        address seller,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    event OfferMade(
        address account,
        address indexed collection,
        uint256 tokenId,
        uint256 offerValue,
        uint256 validityDuration,
        uint256 expiresAt
    );

    event OfferUpdated(
        address account,
        address indexed collection,
        uint256 tokenId,
        uint256 offerValue,
        uint256 validityDuration,
        uint256 expiresAt
    );

    event OfferCancelled(
        address account,
        address indexed collection,
        uint256 tokenId
    );

    event OfferAccepted(
        address beneficiary,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    function listItem(
        address collection,
        uint256 tokenId,
        uint256 price
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        _listItem(collection, tokenId, price);

        emit ItemListed(msg.sender, collection, tokenId, price);
    }

    function listItem(
        address collection,
        uint256 tokenId,
        uint256 price,
        address royaltyReceiver,
        uint256 royaltyPercentage
    ) external whenNotPaused onlyNonBlacklistedUsers nonReentrant {
        if (collection != JUMY_COLLECTION)
            revert Exchange_Rejected_Genesis_Collection_Only();

        _listItem(collection, tokenId, price);

        royaltyManager.setJumyTokenRoyalty(
            collection,
            tokenId,
            royaltyReceiver,
            royaltyPercentage
        );

        emit ItemListed(msg.sender, collection, tokenId, price);
    }

    function updateItem(
        address collection,
        uint256 tokenId,
        uint256 price
    )
        external
        onlyAllowedToBeListed(collection)
        whenNotPaused
        onlyNonBlacklistedUsers
        nonReentrant
    {
        _listItem(collection, tokenId, price);

        emit ItemUpdated(msg.sender, collection, tokenId, price);
    }

    function removeItem(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        if (fixedPriceListings[collection][tokenId].seller != msg.sender) {
            revert Exchange_Not_Sale_Owner();
        }

        delete fixedPriceListings[collection][tokenId];

        emit ItemRemoved(msg.sender, collection, tokenId);
    }

    function purchaseItem(
        address collection,
        uint256 tokenId,
        address to
    ) external payable nonReentrant {
        if (collection == address(0)) revert RejectedNullishAddress();
        if (to == address(0)) revert RejectedNullishAddress();

        FixedPriceListing memory item = fixedPriceListings[collection][tokenId];

        if (item.seller == address(0) || item.price == 0)
            revert Exchange_Listing_Not_Found();

        if (msg.value != item.price) revert Exchange_Wrong_Price_Value();

        delete fixedPriceListings[collection][tokenId];

        ExchangeCore._executeETHPayment(
            collection,
            tokenId,
            item.seller,
            item.price
        );

        IERC721(collection).transferFrom(item.seller, to, tokenId);

        if (address(rewardsManager) != address(0)) {
            rewardsManager.purchaseEvent(
                item.seller,
                to,
                item.price,
                collection,
                tokenId
            );
        }

        emit ItemPurchased(to, item.seller, collection, tokenId, item.price);
    }

    function makeOffer(
        uint256 offerValue,
        uint256 validityDuration,
        address collection,
        uint256 tokenId
    ) external nonReentrant {
        uint256 expiresAt = _updateOffer(
            offerValue,
            validityDuration,
            collection,
            tokenId
        );

        emit OfferMade(
            msg.sender,
            collection,
            tokenId,
            offerValue,
            validityDuration,
            expiresAt
        );
    }

    function updateOffer(
        uint256 offerValue,
        uint256 validityDuration,
        address collection,
        uint256 tokenId
    ) external nonReentrant {
        uint256 expiresAt = _updateOffer(
            offerValue,
            validityDuration,
            collection,
            tokenId
        );

        emit OfferUpdated(
            msg.sender,
            collection,
            tokenId,
            offerValue,
            validityDuration,
            expiresAt
        );
    }

    function cancelOffer(address collection, uint256 tokenId)
        external
        nonReentrant
    {
        if (collection == address(0)) revert RejectedNullishAddress();

        delete offers[collection][tokenId][msg.sender];

        emit OfferCancelled(msg.sender, collection, tokenId);
    }

    function acceptOffer(
        address beneficiary,
        uint256 offerValue,
        address collection,
        uint256 tokenId
    ) external nonReentrant {
        if (collection == address(0)) revert RejectedNullishAddress();
        if (beneficiary == address(0)) revert RejectedNullishAddress();

        Offer memory offer = offers[collection][tokenId][beneficiary];

        delete offers[collection][tokenId][beneficiary];
        delete fixedPriceListings[collection][tokenId];

        if (offer.value != offerValue)
            revert Exchange_Wrong_Offer_Value(offer.value);
        if (offer.expiresAt < block.timestamp)
            revert Exchange_Expired_Offer(offer.expiresAt);

        ExchangeCore._executeWETHPayment(
            collection,
            tokenId,
            beneficiary,
            msg.sender,
            offerValue
        );
        IERC721(collection).safeTransferFrom(msg.sender, beneficiary, tokenId);

        if (address(rewardsManager) != address(0)) {
            rewardsManager.purchaseEvent(
                msg.sender,
                beneficiary,
                offer.value,
                collection,
                tokenId
            );
        }

        emit OfferAccepted(beneficiary, collection, tokenId, offerValue);
    }

    function _listItem(
        address collection,
        uint256 tokenId,
        uint256 price
    ) private {
        if (price == 0) revert Exchange_Invalid_Nullish_Price();

        if (IERC721(collection).ownerOf(tokenId) != msg.sender)
            revert Exchange_Not_The_Token_Owner();

        if (
            !IERC721(collection).isApprovedForAll(msg.sender, address(this)) &&
            IERC721(collection).getApproved(tokenId) != address(this)
        ) revert Exchange_Insufficient_Operator_Privilege();

        fixedPriceListings[collection][tokenId] = FixedPriceListing(
            msg.sender,
            price
        );
    }

    function _updateOffer(
        uint256 offerValue,
        uint256 validityDuration,
        address collection,
        uint256 tokenId
    ) private returns (uint256 expiresAt) {
        if (collection == address(0)) revert RejectedNullishAddress();

        if (validityDuration == 0) revert Exchange_Rejected_Nullish_Duration();

        if (offerValue == 0) revert Exchange_Rejected_Nullish_Offer_Value();

        uint256 wethAllowance = IWETH(WETH).allowance(
            msg.sender,
            address(this)
        );
        if (wethAllowance < offerValue)
            revert Exchange_Insufficient_WETH_Allowance(wethAllowance);

        uint256 _expiresAt = block.timestamp + validityDuration;

        offers[collection][tokenId][msg.sender].value = offerValue;
        offers[collection][tokenId][msg.sender].expiresAt = _expiresAt;

        return _expiresAt;
    }
}
