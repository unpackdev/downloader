// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PullPaymentUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./SaleBaseV3Upgradeable.sol";
import "./EnumerableMap.sol";

/**
 * @title Base open offers contract
 * @dev This is the base contract which implements the open offers functionality
 */
contract OpenOffersBaseV3Upgradeable is PullPaymentUpgradeable, ReentrancyGuardUpgradeable, SaleBaseV3Upgradeable {
    using AddressUpgradeable for address payable;

    // Add the library methods
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct OpenOffers {
        address seller;
        address creator;
        address gallery;
        uint64 startedAt;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
        EnumerableMap.AddressToUintMap offers;
    }

    // this struct is only used for referencing in memory. The OpenOffers struct can not
    // be used because it is only valid in storage since it contains a nested mapping
    struct OffersReference {
        address seller;
        address creator;
        address gallery;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
    }

    // mapping for tokenId to its sale
    mapping(uint256 => OpenOffers) tokenIdToOpenOfferSale;

    event OpenOffersSaleCreated(uint256 tokenId, uint64 startingTime, address creator, address seller, address gallery, uint16 creatorCut, uint16 platformCut, uint16 galleryCut);
    event OpenOffersSaleSuccessful(uint256 tokenId, uint256 totalPrice, address winner, address creator, address seller, address gallery, uint16 creatorCut, uint16 platformCut, uint16 galleryCut);
    event makeOpenOffer(uint256 tokenId, uint256 totalPrice, address winner, address creator, address seller, address gallery);
    event rejectOpenOffer(uint256 tokenId, uint256 totalPrice, address loser, address creator, address seller, address gallery);
    event OpenOffersSaleFinished(uint256 tokenId, address creator, address seller, address gallery);

    /**
     * @dev Internal function to check if the sale started, by default startedAt will be 0
     *
     */
    function _isOnSale(OpenOffers storage _openSale) internal view returns (bool) {
        return (_openSale.startedAt > 0 && _openSale.startedAt <= block.timestamp);
    }

    /**
     * @dev Remove the sale from the mapping (sets everything to zero/false)
     * @param _tokenId ID of the token to remove sale of
     */
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToOpenOfferSale[_tokenId];
    }

    /**
     * @dev Internal that updates the mapping when a new offer is made for a token on sale
     * @param _tokenId Id of the token to make offer on
     * @param _bidAmount The offer in wei
     */
    function _makeOffer(uint _tokenId, uint _bidAmount) internal {
        // get reference to the open offer struct
        OpenOffers storage openSale = tokenIdToOpenOfferSale[_tokenId];

        // check if the item is on sale
        require(_isOnSale(openSale), "Item is not on sale");

        uint256 returnAmount;
        bool offerExists;

        // get reference to the amount to return
        (offerExists, returnAmount) = openSale.offers.tryGet(msg.sender);

        // if there was a previous offer from this address, return the previous offer amount
        if(offerExists){
            _cancelOffer(_tokenId, msg.sender);
        }

        // update the mapping with the new offer
        openSale.offers.set(msg.sender, _bidAmount);

        // emit event
        emit makeOpenOffer(
            _tokenId,
            _bidAmount,
            msg.sender,
            openSale.creator,
            openSale.seller,
            openSale.gallery
            );
    }

    /**
     * @dev Internal function to accept the offer of an address. Once an offer is accepted, all existing offers
     * for the token are moved into the PullPayment contract and the mapping is deleted. Only gallery can accept
     * offers if the sale involves a gallery
     * @param _tokenId Id of the token to accept offer of
     * @param _buyer The address of the buyer to accept offer from
     */
    function _acceptOffer(uint256 _tokenId, address _buyer) internal nonReentrant {
        OpenOffers storage openSale = tokenIdToOpenOfferSale[_tokenId];

        // only the gallery can accept the offer if it was the one to put it on open offers
        if(openSale.gallery != address(0)) {
            require(openSale.gallery == msg.sender);
        } else {
            require(openSale.seller == msg.sender);
        }

        // check if token was on sale
        require(_isOnSale(openSale), "Item is not on sale");

        // check if the offer from the buyer exists
        require(openSale.offers.contains(_buyer));

        // get reference to the offer
        uint256 _payoutAmount = openSale.offers.get(_buyer);

        // remove the offer from the enumerable mapping
        openSale.offers.remove(_buyer);

        address returnAddress;
        uint256 returnAmount;

        // put the returns in the pull payments contract
        for (uint i = 0; i < openSale.offers.length(); i++) {
            (returnAddress, returnAmount) = openSale.offers.at(i);
            // remove the offer from the enumerable mapping
            openSale.offers.remove(returnAddress);
            // transfer the return amount into the pull payement contract
            _asyncTransfer(returnAddress, returnAmount);

            // emit event
            emit rejectOpenOffer(
                _tokenId,
                returnAmount,
                returnAddress,
                openSale.creator,
                openSale.seller,
                openSale.gallery
                );
        }

        // using struct to avoid stack too deep error
        OffersReference memory openSaleReference = OffersReference(
            openSale.seller,
            openSale.creator,
            openSale.gallery,
            openSale.creatorCut,
            openSale.platformCut,
            openSale.galleryCut
        );

        // delete the sale
        _removeSale(_tokenId);

        // pay the seller and distribute the cuts
        _payout(
            payable(openSaleReference.seller),
            payable(openSaleReference.creator),
            payable(openSaleReference.gallery),
            openSaleReference.creatorCut,
            openSaleReference.platformCut,
            openSaleReference.galleryCut,
            _payoutAmount,
            _tokenId
        );

        // transfer the token to the buyer
        _transfer(_buyer, _tokenId);

        // emit event
        emit OpenOffersSaleSuccessful(
                _tokenId,
                _payoutAmount,
                _buyer,
                openSaleReference.creator,
                openSaleReference.seller,
                openSaleReference.gallery,
                openSaleReference.creatorCut,
                openSaleReference.platformCut,
                openSaleReference.galleryCut
            );
    }

    /**
     * @dev Internal function to cancel an offer. This is used for both rejecting and revoking offers
     * @param _tokenId Id of the token to cancel offer of
     * @param _buyer The address to cancel bid of
     */
    function _cancelOffer(uint256 _tokenId, address _buyer) internal {
        OpenOffers storage openSale = tokenIdToOpenOfferSale[_tokenId];

        // check if token was on sale
        require(_isOnSale(openSale), "Item is not on sale");

        // get reference to the offer, will fail if mapping doesn't exist
        uint256 _payoutAmount = openSale.offers.get(_buyer);

        // remove the offer from the enumerable mapping
        openSale.offers.remove(_buyer);

        // return the ether
        payable(_buyer).sendValue(_payoutAmount);

        // emit event
        emit rejectOpenOffer(
            _tokenId,
            _payoutAmount,
            _buyer,
            openSale.creator,
            openSale.seller,
            openSale.gallery
            );
    }

    /**
     * @dev Function to finish the sale. Can be called manually if there was no suitable offer
     * for the NFT. If a gallery put the artwork on sale, only it can call this function.
     * The super admin can also call the function, this is implemented as a safety mechanism for
     * the seller in case the gallery becomes idle
     * @param _tokenId Id of the token to end sale of
     */
    function _finishOpenOfferSale(uint256 _tokenId) internal nonReentrant {
        OpenOffers storage openSale = tokenIdToOpenOfferSale[_tokenId];

        // only the gallery or admin can finish the sale if it was the one to put it on auction
        if(openSale.gallery != address(0)) {
            require(openSale.gallery == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        } else {
            require(openSale.seller == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        }

        // check if token was on sale
        require(_isOnSale(openSale), "Item is not on sale");

        address seller = openSale.seller;

        address returnAddress;
        uint256 returnAmount;

        // put all pending returns in the pull payments contract
        for (uint i = 0; i < openSale.offers.length(); i++) {
            (returnAddress, returnAmount) = openSale.offers.at(i);
            // remove the offer from the enumerable mapping
            openSale.offers.remove(returnAddress);
            // transfer the return amount into the pull payement contract
            _asyncTransfer(returnAddress, returnAmount);

            // emit event
            emit rejectOpenOffer(
                _tokenId,
                returnAmount,
                returnAddress,
                openSale.creator,
                openSale.seller,
                openSale.gallery
                );
        }
        
        // emit event
        emit OpenOffersSaleFinished(
            _tokenId,
            openSale.creator,
            openSale.seller,
            openSale.gallery
            );

        // delete the sale
        _removeSale(_tokenId);

        // return the token to the seller
        _transfer(seller, _tokenId);
    }

    uint256[1000] private __gap;
}

/**
 * @title Open Offers sale contract that provides external functions
 * @dev Implements the external and public functions of the open offers implementation
 */
contract OpenOffersSaleV3Upgradeable is OpenOffersBaseV3Upgradeable {
    bool public isFarbeOpenOffersSale;

    /**
     * External function to create an Open Offers sale. Can only be called by the Farbe NFT contract
     * @param _tokenId Id of the token to create sale for
     * @param _startingTime Starting time of the sale
     * @param _creator Address of  the original creator of the artwork
     * @param _seller Address of the owner of the artwork
     * @param _gallery Address of the gallery of the artwork, 0 address if gallery is not involved
     * @param _creatorCut Cut of the creator in %age * 10
     * @param _galleryCut Cut of the gallery in %age * 10
     * @param _platformCut Cut of the platform on primary sales in %age * 10
     */
    function createOppenOfferSale(
        uint256 _tokenId,
        uint64 _startingTime,
        address _creator,
        address _seller,
        address _gallery,
        uint16 _creatorCut,
        uint16 _galleryCut,
        uint16 _platformCut
    )
    internal
    {
        OpenOffers storage openOffers = tokenIdToOpenOfferSale[_tokenId];

        openOffers.seller = _seller;
        openOffers.creator = _creator;
        openOffers.gallery = _gallery;
        openOffers.startedAt = _startingTime;
        openOffers.creatorCut = _creatorCut;
        openOffers.platformCut = _platformCut;
        openOffers.galleryCut = _galleryCut;

        // emit event
        emit OpenOffersSaleCreated(
            _tokenId,
            openOffers.startedAt,
            openOffers.creator,
            openOffers.seller,
            openOffers.gallery,
            openOffers.creatorCut,
            openOffers.platformCut,
            openOffers.galleryCut
        );
    }

    /**
     * @dev External function that allows others to make offers for an artwork
     * @param _tokenId Id of the token to make offer for
     */
    function makeOffer(uint256 _tokenId) external payable {
        // do not allow sellers and galleries to make offers on their own artwork
        require(tokenIdToOpenOfferSale[_tokenId].seller != msg.sender && tokenIdToOpenOfferSale[_tokenId].gallery != msg.sender,
            "Sellers and Galleries not allowed");

        _makeOffer(_tokenId, msg.value);
    }

    /**
     * @dev External function to allow a gallery or a seller to accept an offer
     * @param _tokenId Id of the token to accept offer of
     * @param _buyer Address of the buyer to accept offer of
     */
    function acceptOffer(uint256 _tokenId, address _buyer) external {
        _acceptOffer(_tokenId, _buyer);
    }

    /**
     * @dev External function to reject a particular offer and return the ether
     * @param _tokenId Id of the token to reject offer of
     * @param _buyer Address of the buyer to reject offer of
     */
    function rejectOffer(uint256 _tokenId, address _buyer) external {
    // only the gallery can accept the offer if it was the one to put it on open offers
        if(tokenIdToOpenOfferSale[_tokenId].gallery != address(0)) {
            require(tokenIdToOpenOfferSale[_tokenId].gallery == msg.sender);
        } else {
            require(tokenIdToOpenOfferSale[_tokenId].seller == msg.sender);
        }        _cancelOffer(_tokenId, _buyer);
    }

    /**
     * @dev External function to allow buyers to revoke their offers
     * @param _tokenId Id of the token to revoke offer of
     */
    function revokeOffer(uint256 _tokenId) external {
        _cancelOffer(_tokenId, msg.sender);
    }

    /**
     * @dev External function to finish the sale if no one bought it. Can only be called by the owner or gallery
     * @param _tokenId ID of the token to finish sale of
     */
    function finishSale(uint256 _tokenId) external {
        _finishOpenOfferSale(_tokenId);
    }
}
