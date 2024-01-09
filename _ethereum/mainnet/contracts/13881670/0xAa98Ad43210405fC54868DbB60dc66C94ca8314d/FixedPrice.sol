// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SaleBase.sol";

/**
 * @title Base fixed price contract
 * @dev This is the base fixed price contract which implements the internal functionality
 */
contract FixedPriceBase is SaleBase {
    using Address for address payable;

    // fixed price sale struct to keep track of the sales
    struct FixedPrice {
        address seller;
        address creator;
        address gallery;
        uint128 fixedPrice;
        uint64 startedAt;
        uint16 creatorCut;
        uint16 platformCut;
        uint16 galleryCut;
    }

    // mapping for tokenId to its sale
    mapping(uint256 => FixedPrice) tokenIdToSale;

    event FixedSaleCreated(uint256 tokenId, uint256 fixedPrice);
    event FixedSaleSuccessful(uint256 tokenId, uint256 totalPrice, address winner);

    /**
     * @dev Add the sale to the mapping and emit the FixedSaleCreated event
     * @param _tokenId ID of the token to sell
     * @param _fixedSale Reference to the sale struct to add to the mapping
     */
    function _addSale(uint256 _tokenId, FixedPrice memory _fixedSale) internal {
        // update mapping
        tokenIdToSale[_tokenId] = _fixedSale;

        // emit event
        emit FixedSaleCreated(
            uint256(_tokenId),
            uint256(_fixedSale.fixedPrice)
        );
    }

    /**
     * @dev Remove the sale from the mapping (sets everything to zero/false)
     * @param _tokenId ID of the token to remove sale of
     */
    function _removeSale(uint256 _tokenId) internal {
        delete tokenIdToSale[_tokenId];
    }

    /**
     * @dev Internal function to check if a sale started. By default startedAt is at 0
     * @param _fixedSale Reference to the sale struct to check
     * @return bool Weather the sale has started
     */
    function _isOnSale(FixedPrice storage _fixedSale) internal view returns (bool) {
        return (_fixedSale.startedAt > 0 && _fixedSale.startedAt <= block.timestamp);
    }

    /**
     * @dev Internal function to buy a token on sale
     * @param _tokenId Id of the token to buy
     * @param _amount The amount in wei
     */
    function _buy(uint256 _tokenId, uint256 _amount) internal {
        // get reference to the fixed price sale struct
        FixedPrice storage fixedSale = tokenIdToSale[_tokenId];

        // check if the item is on sale
        require(_isOnSale(fixedSale), "Item is not on sale");

        // check if sent amount is equal or greater than the set price
        require(_amount >= fixedSale.fixedPrice, "Amount sent is not enough to buy the token");

        // using struct to avoid stack too deep error
        FixedPrice memory referenceFixedSale = fixedSale;

        // delete the sale
        _removeSale(_tokenId);

        // pay the seller, and distribute cuts
        _payout(
            payable(referenceFixedSale.seller),
            payable(referenceFixedSale.creator),
            payable(referenceFixedSale.gallery),
            referenceFixedSale.creatorCut,
            referenceFixedSale.platformCut,
            referenceFixedSale.galleryCut,
            _amount,
            _tokenId
        );

        // transfer the token to the buyer
        _transfer(msg.sender, _tokenId);

        emit FixedSaleSuccessful(_tokenId, referenceFixedSale.fixedPrice, msg.sender);
    }

    /**
     * @dev Function to finish the sale. Can be called manually if no one bought the NFT. If
     * a gallery put the artwork on sale, only it can call this function. The super admin can
     * also call the function, this is implemented as a safety mechanism for the seller in case
     * the gallery becomes idle
     * @param _tokenId Id of the token to end sale of
     */
    function _finishSale(uint256 _tokenId) internal {
        FixedPrice storage fixedSale = tokenIdToSale[_tokenId];

        // only the gallery can finish the sale if it was the one to put it on auction
        if(fixedSale.gallery != address(0)) {
            require(fixedSale.gallery == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        } else {
            require(fixedSale.seller == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        }

        // check if token was on sale
        require(_isOnSale(fixedSale));

        address seller = fixedSale.seller;

        // delete the sale
        _removeSale(_tokenId);

        // return the token to the seller
        _transfer(seller, _tokenId);
    }
}

/**
 * @title Fixed Price sale contract that provides external functions
 * @dev Implements the external and public functions of the Fixed price implementation
 */
contract FixedPriceSale is FixedPriceBase {
    // sanity check for the nft contract
    bool public isFarbeFixedSale = true;

    // ERC721 interface id
    bytes4 constant InterfaceSignature_ERC721 = bytes4(0x80ac58cd);

    constructor(address _nftAddress, address _platformAddress) {
        // check NFT contract supports ERC721 interface
        FarbeArtSale candidateContract = FarbeArtSale(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_ERC721));

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        platformWalletAddress = _platformAddress;

        NFTContract = candidateContract;
    }

    /**
     * @dev External function to create fixed sale. Called by the Farbe NFT contract
     * @param _tokenId ID of the token to create sale for
     * @param _fixedPrice Starting price of the sale in wei
     * @param _creator Address of the original creator of the NFT
     * @param _seller Address of the seller of the NFT
     * @param _gallery Address of the gallery of this sale, will be 0 if no gallery is involved
     * @param _creatorCut The cut that goes to the creator, as %age * 10
     * @param _galleryCut The cut that goes to the gallery, as %age * 10
     * @param _platformCut The cut that goes to the platform if it is a primary sale
     */
    function createSale(
        uint256 _tokenId,
        uint128 _fixedPrice,
        uint64 _startingTime,
        address _creator,
        address _seller,
        address _gallery,
        uint16 _creatorCut,
        uint16 _galleryCut,
        uint16 _platformCut
    )
    external
    onlyFarbeContract
    {
        // create and add the sale
        FixedPrice memory fixedSale = FixedPrice(
            _seller,
            _creator,
            _gallery,
            _fixedPrice,
            _startingTime,
            _creatorCut,
            _platformCut,
            _galleryCut
        );
        _addSale(_tokenId, fixedSale);
    }

    /**
     * @dev External payable function to buy the artwork
     * @param _tokenId Id of the token to buy
     */
    function buy(uint256 _tokenId) external payable {
        // do not allow sellers and galleries to buy their own artwork
        require(tokenIdToSale[_tokenId].seller != msg.sender && tokenIdToSale[_tokenId].gallery != msg.sender,
            "Sellers and Galleries not allowed");

        _buy(_tokenId, msg.value);
    }

    /**
     * @dev External function to finish the sale if no one bought it. Can only be called by the owner or gallery
     * @param _tokenId ID of the token to finish sale of
     */
    function finishSale(uint256 _tokenId) external {
        _finishSale(_tokenId);
    }

    /**
     * @dev External view function to get the details of a sale
     * @param _tokenId ID of the token to get the sale information of
     * @return seller Address of the seller
     * @return fixedPrice Fixed Price of the sale in wei
     * @return startedAt Unix timestamp for when the sale started
     */
    function getFixedSale(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 fixedPrice,
        uint256 startedAt
    ) {
        FixedPrice storage fixedSale = tokenIdToSale[_tokenId];
        require(_isOnSale(fixedSale), "Item is not on sale");
        return (
        fixedSale.seller,
        fixedSale.fixedPrice,
        fixedSale.startedAt
        );
    }

    /**
     * @dev Helper function for testing with timers TODO Remove this before deploying live
     * @param _tokenId ID of the token to get timers of
     */
    function getTimers(uint256 _tokenId)
    external
    view returns (
        uint256 saleStart,
        uint256 blockTimestamp
    ) {
        FixedPrice memory fixedSale = tokenIdToSale[_tokenId];
        return (fixedSale.startedAt, block.timestamp);
    }
}
