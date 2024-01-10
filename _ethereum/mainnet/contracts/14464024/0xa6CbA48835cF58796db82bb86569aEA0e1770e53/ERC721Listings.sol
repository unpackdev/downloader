//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./IERC721.sol";
import "./Ownable.sol";

/// @title Basic listing management for ERC721 NFTs
/// @author Sam King (samking.eth)
/// @notice Allows the contract owner or token owner to list ERC721 tokens
contract ERC721Listings is Ownable {
    /**************************************************************************
     * STORAGE
     *************************************************************************/

    /// @notice The address of the contract with tokens e.g. Manifold
    address public tokenAddress;

    /// @notice The original minter of the tokens
    /// @dev Used in `safeTransferFrom` when a user purchases a token
    address public tokenOwnerAddress;

    /// @notice The address where purchase proceeds will be sent
    /// @dev Defaults to `tokenOwnerAddress` but can be updated later
    address payable public payoutAddress;

    /// @notice Status for listings
    /// @dev Payments revert for listings that are inactive or executed
    /// @dev Active being 0 saves gas on creation because most listings will be set to active
    enum ListingStatus {
        ACTIVE,
        INACTIVE,
        EXECUTED
    }

    /// @notice Stores price and status for a listing
    struct Listing {
        uint256 price;
        ListingStatus status;
    }

    /// @notice Listing storgage by token id
    mapping(uint256 => Listing) private listings;

    /**************************************************************************
     * EVENTS
     *************************************************************************/

    /// @notice When a listing is created
    /// @param tokenId The token ID that was listed
    /// @param price The price of the listing
    event ListingCreated(
        uint256 indexed tokenId,
        uint256 price,
        ListingStatus indexed status
    );

    /// @notice When a listings price or status is updated
    /// @param tokenId The token ID of the listing that was updated
    /// @param price The new listing price
    /// @param status The new listing status
    event ListingUpdated(
        uint256 indexed tokenId,
        uint256 price,
        ListingStatus indexed status
    );

    /// @notice When a listing is purchased by a buyer
    /// @param tokenId The token ID that was purchased
    /// @param price The price the buyer paid
    /// @param buyer The buyer of the token ID
    event ListingPurchased(
        uint256 indexed tokenId,
        uint256 price,
        address indexed buyer
    );

    /**************************************************************************
     * ERRORS
     *************************************************************************/

    error IncorrectPaymentAmount(uint256 expected, uint256 provided);
    error IncorrectConfiguration();
    error ListingExecuted();
    error ListingInactive();
    error NotAuthorized();
    error PaymentFailed();

    /**************************************************************************
     * MODIFIERS
     *************************************************************************/

    modifier onlyOwnerOrMinter() {
        if (msg.sender != tokenOwnerAddress && msg.sender != owner()) {
            revert NotAuthorized();
        }
        _;
    }

    /**************************************************************************
     * INIT
     *************************************************************************/

    /// @param _tokenAddress The address of the contract with tokens
    /// @param _tokenOwnerAddress The original minter of the tokens
    constructor(address _tokenAddress, address _tokenOwnerAddress) {
        tokenAddress = _tokenAddress;
        tokenOwnerAddress = _tokenOwnerAddress;
        payoutAddress = payable(_tokenOwnerAddress);
    }

    /**************************************************************************
     * LISTING ADMIN
     *************************************************************************/

    /// @notice Internal function to set listing values in storage
    /// @dev Reverts on listings that have already been executed
    /// @param tokenId The tokenId to set listing information for
    /// @param price The price to list the token at
    /// @param setActive If the listing should be set to active or not
    function _setListing(
        uint256 tokenId,
        uint256 price,
        bool setActive
    ) internal {
        Listing storage listing = listings[tokenId];
        if (listing.status == ListingStatus.EXECUTED) revert ListingExecuted();
        listing.price = price;
        listing.status = setActive
            ? ListingStatus.ACTIVE
            : ListingStatus.INACTIVE;
        emit ListingCreated(tokenId, price, listing.status);
    }

    /// @notice Sets information about a listing
    /// @param tokenId The token id to set listing information for
    /// @param price The price to list the token id at
    /// @param setActive If the listing should be set to active or not
    function createListing(
        uint256 tokenId,
        uint256 price,
        bool setActive
    ) external onlyOwnerOrMinter {
        _setListing(tokenId, price, setActive);
    }

    /// @notice Sets information about multiple listings
    /// @dev tokenIds and prices should be the same length
    /// @param tokenIds An array of token ids to set listing information for
    /// @param prices An array of prices to list each token id at
    /// @param setActive If the listings should be set to active or not
    function createListingBatch(
        uint256[] memory tokenIds,
        uint256[] memory prices,
        bool setActive
    ) external onlyOwnerOrMinter {
        if (tokenIds.length != prices.length) {
            revert IncorrectConfiguration();
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _setListing(tokenIds[i], prices[i], setActive);
        }
    }

    /// @notice Updates the price of a specific listing
    /// @param tokenId The token id to update the price for
    /// @param newPrice The new price to set
    function updateListingPrice(uint256 tokenId, uint256 newPrice)
        external
        onlyOwnerOrMinter
    {
        Listing storage listing = listings[tokenId];
        if (listing.status == ListingStatus.EXECUTED) revert ListingExecuted();
        listing.price = newPrice;
        emit ListingUpdated(tokenId, listing.price, listing.status);
    }

    /// @notice Flips the listing state between ACTIVE and INACTIVE
    /// @dev Only flips between ACTIVE and INACTIVE. Reverts if EXECUTED
    /// @param tokenId The token id to update the listing status for
    function toggleListingStatus(uint256 tokenId) external onlyOwnerOrMinter {
        Listing storage listing = listings[tokenId];
        if (listing.status == ListingStatus.EXECUTED) revert ListingExecuted();
        listing.status = listing.status == ListingStatus.ACTIVE
            ? ListingStatus.INACTIVE
            : ListingStatus.ACTIVE;
        emit ListingUpdated(tokenId, listing.price, listing.status);
    }

    /**************************************************************************
     * PURCHASING
     *************************************************************************/

    /// @notice Allows someone to purchase a token
    /// @dev Accepts payment, checks if listing can be purchased,
    ///      transfers token to new owner and sends payment to payout address
    /// @param tokenId The token id to purchase
    function purchase(uint256 tokenId) external payable {
        Listing storage listing = listings[tokenId];

        // Check if the token can be purchased
        if (listing.status == ListingStatus.EXECUTED) revert ListingExecuted();
        if (listing.status == ListingStatus.INACTIVE) revert ListingInactive();
        if (msg.value != listing.price) {
            revert IncorrectPaymentAmount({
                expected: listing.price,
                provided: msg.value
            });
        }

        // Transfer the token from the owner to the buyer
        IERC721(tokenAddress).safeTransferFrom(
            tokenOwnerAddress,
            msg.sender,
            tokenId
        );

        // Set the listing to executed
        listing.status = ListingStatus.EXECUTED;

        emit ListingPurchased(tokenId, msg.value, msg.sender);
    }

    /**************************************************************************
     * ADMIN
     *************************************************************************/

    /// @notice Updates the address that minted the original tokens
    /// @dev The address is used in the purchase flow to transfer tokens
    /// @param _tokenOwnerAddress The original minter of the tokens
    function setTokenOwnerAddress(address _tokenOwnerAddress)
        external
        onlyOwnerOrMinter
    {
        tokenOwnerAddress = _tokenOwnerAddress;
    }

    /// @notice Updates the address that receives sale proceeds
    /// @param _payoutAddress The address where sale proceeds should be paid to
    function setPayoutAddress(address _payoutAddress)
        external
        onlyOwnerOrMinter
    {
        payoutAddress = payable(_payoutAddress);
    }

    /// @notice Withdraw the contract balance to the payout address
    function withdraw() external {
        (bool sent, ) = payoutAddress.call{value: address(this).balance}("");
        if (!sent) revert PaymentFailed();
    }

    /**************************************************************************
     * GETTERS
     *************************************************************************/

    /// @notice Gets listing information for a token id
    /// @param tokenId The token id to get listing information for
    /// @return listing Listing information
    function getListing(uint256 tokenId)
        external
        view
        returns (Listing memory listing)
    {
        listing = listings[tokenId];
    }

    /// @notice Gets the listing price for a token id
    /// @param tokenId The token id to get the listing price for
    /// @return price Listing price
    function getListingPrice(uint256 tokenId)
        external
        view
        returns (uint256 price)
    {
        price = listings[tokenId].price;
    }

    /// @notice Gets the listing status for a token id
    /// @param tokenId The token id to get the listing status for
    /// @return status Listing status
    function getListingStatus(uint256 tokenId)
        external
        view
        returns (ListingStatus status)
    {
        status = listings[tokenId].status;
    }
}
